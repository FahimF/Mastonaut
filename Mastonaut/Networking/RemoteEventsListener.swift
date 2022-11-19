//
//  RemoteEventsListener.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.03.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import CoreTootin
import Foundation
import Starscream

protocol RemoteEventsListenerDelegate: AnyObject {
	func remoteEventsListenerDidConnect(_ remoteEventsListener: RemoteEventsListener)
	func remoteEventsListenerDidDisconnect(_ remoteEventsListener: RemoteEventsListener, code: UInt16)
	func remoteEventsListener(_ remoteEventsListener: RemoteEventsListener, didHandleEvent: ClientEvent)
	func remoteEventsListener(_ remoteEventsListener: RemoteEventsListener, parserProducedError: Error)
}

enum ClientEvent {
	case update(Status)
	case notification(MKNotification)
	case delete(statusID: String)
	case keywordFiltersChanged
}

class RemoteEventsListener: NSObject, WebSocketDelegate {
	private let socketUrl: URL
	private let accessToken: String
	private var lastResolvedURL: URL?

	private var socket: WebSocket!
	private var isConnected = false

	private var isReconnecting: Bool = false
	private var reconnectDelay: TimeInterval = 0.5
	private var reconnectTimer: Timer?

	weak var delegate: RemoteEventsListenerDelegate?

	var isSocketConnected: Bool {
		return isConnected == true
	}

	init(baseUrl: URL, accessToken: String, delegate: RemoteEventsListenerDelegate? = nil) {
		socketUrl = baseUrl.appendingPathComponent("/api/v1/streaming")
		self.accessToken = accessToken
		self.delegate = delegate
		super.init()
	}

	deinit {
		socket?.disconnect()
		RemoteEventsListener.cancelPreviousPerformRequests(withTarget: self, selector: #selector(watchdogBarked), object: nil)

		RemoteEventsListener.cancelPreviousPerformRequests(withTarget: self, selector: #selector(releaseWatchdog), object: nil)
	}

	func set(stream: RemoteEventStream) {
		var components = URLComponents(url: socketUrl, resolvingAgainstBaseURL: false)!
		components.queryItems = stream.makeQueryItems(accessToken: accessToken)
		set(resolvedSocketURL: components.url!)
	}

	private func set(resolvedSocketURL: URL) {
		let req = URLRequest(url: resolvedSocketURL)
		let socket = WebSocket(request: req)
		socket.delegate = self
		if isConnected {
			self.socket.disconnect(closeCode: CloseCode.noStatusReceived.rawValue)
		}
		self.socket = socket
		lastResolvedURL = resolvedSocketURL
		socket.connect()
	}

	func disconnect() {
		socket?.disconnect()
		resetReconnectState()
	}

	/// This method is idempotent.
	func reconnect() {
		DispatchQueue.main.async {
			self.performReconnect()
			self.debugLog("Reconnect")
		}
	}

	private func performReconnect() {
		guard let url = lastResolvedURL, !isReconnecting else {
			return
		}
		isReconnecting = true
		DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) {
			self.set(resolvedSocketURL: url)
			self.debugLog("Reconnecting")
		}
	}

	private func resetReconnectState() {
		isReconnecting = false
		reconnectDelay = 0.5
	}

	private func resetWatchdog() {
		RemoteEventsListener.cancelPreviousPerformRequests(withTarget: self, selector: #selector(watchdogBarked), object: nil)
		RemoteEventsListener.cancelPreviousPerformRequests(withTarget: self, selector: #selector(releaseWatchdog), object: nil)
		perform(#selector(releaseWatchdog), with: nil, afterDelay: 60)
		debugLog("Watchdog was reset")
	}

	@objc
	private func releaseWatchdog() {
		RemoteEventsListener.cancelPreviousPerformRequests(withTarget: self, selector: #selector(watchdogBarked), object: nil)
		perform(#selector(watchdogBarked), with: nil, afterDelay: 5)
		socket?.write(ping: Data("ping".utf8))
		debugLog("Watchdog was released!")
	}

	@objc
	private func watchdogBarked() {
		socket.disconnect(closeCode: CloseCode.noStatusReceived.rawValue)
		debugLog("Watchdog barked!!!")
	}

	private func debugLog(_ message: String) {
		#if DEBUG
			NSLog("[SOCKET \(addressAsString(self))] \(message)")
		#endif
	}
	
	private func parseMastodonEvent(with data: Data) {
		guard data.isEmpty == false else {
			// This is a heartbeat message. Ignoring it…
			return
		}
		do {
			let payload = try JSONDecoder().decode(StreamPayload.self, from: data)
			delegate?.remoteEventsListener(self, didHandleEvent: try payload.parsedEvent())
		} catch {
			delegate?.remoteEventsListener(self, parserProducedError: error)
		}
	}

	// MARK: - WebSocket Delegate
	func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
		switch event {
		case .connected(let headers):
			isConnected = true
			debugLog("WebSocket connected: \(headers)")
			delegate?.remoteEventsListenerDidConnect(self)
			resetReconnectState()
			resetWatchdog()

		case .disconnected(let reason, let code):
			isConnected = false
			debugLog("websocket is disconnected: \(reason) with code: \(code)")
			isReconnecting = false
			reconnectDelay = min(reconnectDelay * 2, 15)
			delegate?.remoteEventsListenerDidDisconnect(self, code: code)

		case .text(let text):
			debugLog("Received text: \(text)")
			parseMastodonEvent(with: Data(text.utf8))
			resetReconnectState()
			resetWatchdog()

		case .binary(let data):
			debugLog("Received data: \(data.count)")
			parseMastodonEvent(with: data)
			resetReconnectState()
			resetWatchdog()

		case .ping(_):
			break
			
		case .pong(_):
			resetWatchdog()
			
		case .viabilityChanged(_):
			break
			
		case .reconnectSuggested(_):
			break
			
		case .cancelled:
			isConnected = false
			
		case .error(let error):
			isConnected = false
			handleError(error)
		}
	}
	
	func handleError(_ error: Error?) {
		if let e = error as? WSError {
			print("websocket encountered an error: \(e.message)")
		} else if let e = error {
			print("websocket encountered an error: \(e.localizedDescription)")
		} else {
			print("websocket encountered an error")
		}
	}
}

enum RemoteEventStream: Hashable {
	case user
	case `public`
	case publicLocal
	case hashtag(String)
	case hashtagLocal(String)
	case list(String)
	case direct

	var name: String {
		switch self {
		case .user: return "user"
		case .public: return "public"
		case .publicLocal: return "public:local"
		case .hashtag: return "hashtag"
		case .hashtagLocal: return "hashtag:local"
		case .list: return "list"
		case .direct: return "direct"
		}
	}

	func makeQueryItems(accessToken: String) -> [URLQueryItem] {
		var items: [URLQueryItem] = [
			URLQueryItem(name: "access_token", value: accessToken),
			URLQueryItem(name: "stream", value: name),
		]

		switch self {
		case let .hashtag(tag), let .hashtagLocal(tag):
			items.append(URLQueryItem(name: "tag", value: tag))

		case let .list(list):
			items.append(URLQueryItem(name: "list", value: list))

		case .user, .public, .publicLocal, .direct:
			break
		}

		return items
	}
}

struct StreamPayload: Decodable {
	let event: String
	let payload: String?

	func parsedEvent() throws -> ClientEvent {
		guard let type = EventType(rawValue: event) else {
			throw ParseErrors.unknownEventType(event)
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(DateFormatter.mastodonFormatter)

		switch (type, payload) {
		case let (.update, .some(payload)):
			return .update(try decoder.decode(Status.self, from: Data(payload.utf8)))

		case let (.notification, .some(payload)):
			return .notification(try decoder.decode(MKNotification.self, from: Data(payload.utf8)))

		case let (.delete, .some(payload)):
			return .delete(statusID: payload)

		case (.filtersChanged, _):
			return .keywordFiltersChanged

		default:
			throw ParseErrors.missingPayload
		}
	}

	enum EventType: String {
		case update
		case notification
		case delete
		case filtersChanged = "filters_changed"
	}

	enum ParseErrors: Error {
		case unknownEventType(String)
		case missingPayload
	}
}
