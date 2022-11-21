# Build

The following instructions assume Xcode 14.1 on macOS 12.6.

## Setup

- Open the file `userspecific.xcconfig`.

- Set `MASTONAUT_BUNDLE_ID_BASE` to a bundle ID for the app that works with your Apple ID.

- Enter your Team ID instead of the `xxxxxxxxxx` next to `DEVELOPMENT_TEAM` (It looks something like `74J34U3R6X`).

- **Do not check in your changes to `userspecific.xcconfig`!**

That should be it.

## Bundle IDs

The bundle ID _base_ is used because Mastonaut consists of multiple projects, which use an app group to share information. Given a `MASTONAUT_BUNDLE_ID_BASE` of `com.example.mastonaut` and a `DEVELOPMENT_TEAM` of `ABCDEFGH`:

- the main app will be `com.example.mastonaut.mac`
- the macOS Sharing extension will be `com.example.mastonaut.mac.QuickToot`
- the Core Data database shared by the two above will be stored in `~/Library/Group Containers/ABCDEFGH.com.example.mastonaut/Mastonaut/Mastonaut.sqlite`
- Keychain credentials will be prefixed `ABCDEFGH.com.example.mastonaut.keychain`

## Pitfalls

- The `.xcconfig` will auto-append `.mac` and other suffixes to the `MASTONAUT_BUNDLE_ID_BASE`, so you should pick something like
`com.example.mastonaut` (replacing `com.example` with whatever reverse domain name you have set up for your account).

- If you don't know your Team ID, go into _Signing & Capabilities_ in your project and select your team, then your UI will show it under 'App Groups'.
Then revert the project file so it will use the setting from the `xcconfig` and you don't have a lurking change in your checkout.

- If you're using a personal developer ID and get an error like `Personal development teams, including "Your Name Here", do not support the Push
Notifications capability.`, you may have to go _Signing and Capabilities_ and delete the "Push Notifications" capability by clicking the little
trash can next to it. **Do not check in this change.**
