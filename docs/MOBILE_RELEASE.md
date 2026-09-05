# Resource Memory mobile release

## 1. Installable web app (PWA)

The GitHub Pages build is configured as an installable PWA. It includes standalone display mode, mobile viewport/safe-area metadata, Apple home-screen metadata, maskable icons, and app shortcuts.

Published URL:

`https://naylahknee.github.io/-resource-memory-app-/`

On iPhone/iPad: open the site in Safari → Share → Add to Home Screen.

On Android: open the site in Chrome → browser menu → Install app / Add to Home screen.

Inside Resource Memory, Sync Devices → Install Resource Memory on this device opens the install instructions.

## 2. Cross-device verification

Use the same Resource Memory account on desktop and mobile.

Recommended test set:

1. Save one normal URL on desktop.
2. Save one screenshot on desktop.
3. Save one voice memory on desktop.
4. Tap Sync now on desktop.
5. Open Resource Memory on the phone, sign into the same account, and tap Sync now.
6. Confirm all three resources appear in Library.
7. Open the screenshot and confirm its synced asset loads.
8. Open the voice memory and confirm its transcript appears.
9. Save/share a screenshot from the phone and confirm it appears on desktop after sync.
10. Save/share a voice memo from the phone and confirm it appears on desktop after sync.

## 3. Mobile capture behavior

Android accepts shared text/URLs, images, and `audio/*` through the system share sheet.

The iOS Flutter side accepts the same content. The committed Share Extension source must still be added/configured as an Xcode target before Resource Memory appears as a native iOS share destination.

When signed in and OpenAI intelligence is configured:

- shared screenshots are understood before saving;
- shared voice memos are transcribed and understood;
- original image/audio bytes are uploaded to R2;
- metadata/transcript sync through Neon.

When offline or AI is unavailable, the resource still saves locally with fallback metadata.

## 4. Android package

The Android application id is:

`com.naylahknee.resourcememory`

The `Mobile Builds` GitHub Actions workflow creates an installable release APK and uploads it as the `resource-memory-android-apk` artifact.

Current release builds intentionally use the debug signing key for private/internal testing. Do not publish this APK to Google Play. Before Play Store release, configure a private release keystore and build an Android App Bundle (`.aab`) with production signing.

## 5. iOS package / TestFlight

The `Mobile Builds` workflow also performs an unsigned iOS release build. This is a compile check, not an installable TestFlight package.

Before TestFlight:

1. Open `ios/Runner.xcworkspace` on a Mac.
2. Set a permanent Runner bundle id such as `com.naylahknee.resourcememory`.
3. Configure the Share Extension target per `docs/IOS_SHARE_EXTENSION_SETUP.md`.
4. Configure the shared App Group.
5. Select the Apple Developer team for Runner and Share Extension.
6. Archive the app in Xcode.
7. Validate and upload the archive to App Store Connect / TestFlight.

The current iOS deployment target is 14.0. Microphone and Photo Library usage descriptions are already present in Runner Info.plist.
