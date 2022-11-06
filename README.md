# Build

The following instructions assume Xcode 14.1 on macOS 12.6.

## Setup

- Open the file `userspecific.xcconfig`.

- Set `MASTONAUT_BUNDLE_ID_BASE` to a bundle ID for the app that works with your Apple ID.

- Enter your Team ID instead of the `xxxxxxxxxx` next to `DEVELOPMENT_TEAM` (It looks something like `74J34U3R6X`).

- **Do not check in your changes to `userspecific.xcconfig`!**

That should be it.

## Pitfalls

- Make sure `MastodonKit` is fetched _as a git submodule_. (For example, Xcode's git clone functionality seems to not do this!) This appears to be a
custom fork called 3.0 that's significantly different from the public MastodonKit. So don't try to change the project to pull the regular MastodonKit using
CocoaPods.

- The `.xcconfig` will auto-append `.mac` and other suffixes to the `MASTONAUT_BUNDLE_ID_BASE`, so you should pick something like
`com.example.mastonaut` (replacing `com.example` with whatever reverse domain name you have set up for your account).

- If you don't know your Team ID, go into _Signing & Capabilities_ in your project and select your team, then your UI will show it under 'App Groups'.
Then revert the project file so it will use the setting from the `xcconfig` and you don't have a lurking change in your checkout.

- If you're using a personal developer ID and get an error like `Personal development teams, including "Your Name Here", do not support the Push
Notifications capability.`, you may have to go _Signing and Capabilities_ and delete the "Push Notifications" capability by clicking the little
trash can next to it. **Do not check in this change.**
