import Flutter
import UIKit
import UserNotifications
import AVFoundation
#if canImport(AppIntents)
import AppIntents
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let voiceChannelName = "com.naylahknee.nanynany/phone"
  private let synthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(
      name: voiceChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }

      switch call.method {
      case "requestNotificationPermission":
        self.requestNotificationPermission(result: result)
      case "speak":
        let args = call.arguments as? [String: Any]
        let text = args?["text"] as? String ?? ""
        self.speak(text)
        result(nil)
      case "scheduleReminder":
        guard
          let args = call.arguments as? [String: Any],
          let id = args["id"] as? String,
          let title = args["title"] as? String,
          let body = args["body"] as? String,
          let epochMs = args["epochMs"] as? NSNumber
        else {
          result(FlutterError(code: "bad_args", message: "Missing reminder fields.", details: nil))
          return
        }
        self.scheduleReminder(
          id: id,
          title: title,
          body: body,
          date: Date(timeIntervalSince1970: epochMs.doubleValue / 1000.0),
          result: result
        )
      case "cancelReminder":
        let args = call.arguments as? [String: Any]
        let id = args?["id"] as? String ?? ""
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        result(nil)
      case "getPendingShortcut":
        let defaults = UserDefaults.standard
        let value = defaults.string(forKey: "resource_memory_pending_shortcut")
        if value != nil {
          defaults.removeObject(forKey: "resource_memory_pending_shortcut")
        }
        result(value)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(code: "notifications", message: error.localizedDescription, details: nil))
        } else {
          result(granted)
        }
      }
    }
  }

  private func speak(_ text: String) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.48
    utterance.volume = 1.0
    synthesizer.speak(utterance)
  }

  private func scheduleReminder(
    id: String,
    title: String,
    body: String,
    date: Date,
    result: @escaping FlutterResult
  ) {
    guard date > Date() else {
      result(false)
      return
    }

    createSpokenNotificationSound(text: body, id: id) { [weak self] soundName in
      guard self != nil else { return }

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = soundName.map { UNNotificationSound(named: UNNotificationSoundName(rawValue: $0)) } ?? .default
      if #available(iOS 15.0, *) {
        content.interruptionLevel = .timeSensitive
      }
      content.userInfo = [
        "resourceMemoryReminderId": id,
        "spokenText": body
      ]

      let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: date
      )
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

      UNUserNotificationCenter.current().add(request) { error in
        DispatchQueue.main.async {
          if let error {
            result(FlutterError(code: "schedule", message: error.localizedDescription, details: nil))
          } else {
            result(true)
          }
        }
      }
    }
  }

  private func createSpokenNotificationSound(
    text: String,
    id: String,
    completion: @escaping (String?) -> Void
  ) {
    let fm = FileManager.default
    guard let library = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else {
      completion(nil)
      return
    }

    let sounds = library.appendingPathComponent("Sounds", isDirectory: true)
    do {
      try fm.createDirectory(at: sounds, withIntermediateDirectories: true)
    } catch {
      completion(nil)
      return
    }

    let safeId = id.replacingOccurrences(of: "/", with: "-")
    let fileName = "rm-\(safeId).caf"
    let url = sounds.appendingPathComponent(fileName)
    try? fm.removeItem(at: url)

    let writer = AVSpeechSynthesizer()
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = 0.48
    utterance.volume = 1.0

    var audioFile: AVAudioFile?
    var failed = false

    writer.write(utterance) { buffer in
      guard let pcm = buffer as? AVAudioPCMBuffer else { return }

      if pcm.frameLength == 0 {
        DispatchQueue.main.async {
          completion(failed ? nil : fileName)
        }
        return
      }

      do {
        if audioFile == nil {
          audioFile = try AVAudioFile(
            forWriting: url,
            settings: pcm.format.settings,
            commonFormat: pcm.format.commonFormat,
            interleaved: pcm.format.isInterleaved
          )
        }
        try audioFile?.write(from: pcm)
      } catch {
        failed = true
      }
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let spoken = notification.request.content.userInfo["spokenText"] as? String
    if let spoken {
      speak(spoken)
    }
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let spoken = response.notification.request.content.userInfo["spokenText"] as? String {
      speak(spoken)
    }
    completionHandler()
  }
}

#if canImport(AppIntents)
@available(iOS 16.0, *)
struct RememberThisIntent: AppIntent {
  static var title: LocalizedStringResource = "Remember This"
  static var description = IntentDescription("Open Resource Memory so you can save something before you forget it.")
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult & ProvidesDialog {
    UserDefaults.standard.set("remember", forKey: "resource_memory_pending_shortcut")
    return .result(dialog: "Opening Resource Memory.")
  }
}

@available(iOS 16.0, *)
struct WhatAmIForgettingIntent: AppIntent {
  static var title: LocalizedStringResource = "What Am I Forgetting?"
  static var description = IntentDescription("Open your active commitments in Resource Memory.")
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult & ProvidesDialog {
    UserDefaults.standard.set("commitments", forKey: "resource_memory_pending_shortcut")
    return .result(dialog: "Opening your reminders.")
  }
}

@available(iOS 16.0, *)
struct ResourceMemoryShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RememberThisIntent(),
      phrases: [
        "Remember this in \(.applicationName)",
        "Save this in \(.applicationName)"
      ],
      shortTitle: "Remember this",
      systemImageName: "bookmark"
    )
    AppShortcut(
      intent: WhatAmIForgettingIntent(),
      phrases: [
        "What am I forgetting in \(.applicationName)",
        "Show my reminders in \(.applicationName)"
      ],
      shortTitle: "What am I forgetting?",
      systemImageName: "bell"
    )
  }
}
#endif
