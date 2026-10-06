# iOS Share Extension setup

Resource Memory handles incoming shared URLs, text, screenshots, and audio/voice-memo files in Flutter. The native Share Extension source files are already committed, so the remaining iPhone work is Xcode target, App Group, and signing configuration.

## Required Xcode steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Change the Runner bundle identifier from the original fork identifier to `com.naylahknee.resourcememory` (or another permanent identifier you control).
3. File → New → Target → Share Extension. Name it `Share Extension`.
4. Give the extension its own bundle identifier, for example `com.naylahknee.resourcememory.ShareExtension`.
5. Replace the target-generated `Info.plist` and `ShareViewController.swift` with the files already committed in `ios/Share Extension/`.
6. Make the Runner and Share Extension deployment targets iOS 14.0 or newer.
7. Enable Swift Package Manager for Flutter if needed: `flutter config --enable-swift-package-manager`.
8. In the Share Extension target → General → Frameworks and Libraries, add the `FlutterGeneratedPluginSwiftPackage` product that exposes `receive_sharing_intent`.
9. In Signing & Capabilities, add App Groups to both Runner and Share Extension. Use the same group for both targets, for example `group.com.naylahknee.resourcememory`.
10. Add the user-defined build setting `CUSTOM_GROUP_ID` to both targets and set it to that App Group identifier.
11. In Runner Build Phases, ensure `Embed Foundation Extension` is above `Thin Binary`.
12. Select your Apple Developer team for both targets and let Xcode create/update provisioning profiles.
13. Build on a physical iPhone and test Share → Resource Memory from Safari/Threads/YouTube, Photos, Files, and Voice Memos.

## Expected behavior

The extension auto-redirects into Resource Memory. Flutter receives the shared item through `receive_sharing_intent` and passes it to `IncomingShareService`.

Shared screenshots are analyzed when cloud intelligence is connected, then the original image is stored in R2. Shared voice memos are transcribed and analyzed when connected, then the original audio is stored in R2. If the network or AI service is unavailable, Resource Memory still saves a local fallback resource.

## TestFlight readiness

The repository can produce an unsigned iOS build in GitHub Actions, which proves the Flutter/iOS code compiles. TestFlight is the next signing step: it requires an Apple Developer membership, a permanent bundle identifier, signing certificates/provisioning, the App Group capability, and the Share Extension target configured in Xcode.
