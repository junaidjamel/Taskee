import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resource_memory/features/resource/data/cloud_sync_service.dart';
import 'package:resource_memory/features/commitment/data/phone_bridge.dart';

class SpokenReminderSettings {
  const SpokenReminderSettings({
    required this.enabled,
    required this.preferNaturalVoice,
    required this.repeatUntilAcknowledged,
    this.voiceId,
  });

  final bool enabled;
  final bool preferNaturalVoice;
  final bool repeatUntilAcknowledged;
  final String? voiceId;
}

class SpokenReminderService {
  static const _enabledKey = 'spoken_reminders_enabled';
  static const _naturalKey = 'spoken_reminders_natural_voice';
  static const _repeatKey = 'spoken_reminders_repeat';
  static const _voiceKey = 'spoken_reminders_voice_id';

  static final FlutterTts _tts = FlutterTts();

  static Future<SpokenReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SpokenReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      preferNaturalVoice: prefs.getBool(_naturalKey) ?? true,
      repeatUntilAcknowledged: prefs.getBool(_repeatKey) ?? true,
      voiceId: prefs.getString(_voiceKey),
    );
  }

  static Future<void> saveSettings(SpokenReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setBool(_naturalKey, settings.preferNaturalVoice);
    await prefs.setBool(_repeatKey, settings.repeatUntilAcknowledged);
    if (settings.voiceId?.trim().isNotEmpty == true) {
      await prefs.setString(_voiceKey, settings.voiceId!.trim());
    } else {
      await prefs.remove(_voiceKey);
    }
  }

  static Future<void> speak(String text) async {
    final settings = await loadSettings();
    if (!settings.enabled || text.trim().isEmpty) return;

    if (PhoneBridge.isIOS) {
      await PhoneBridge.speak(text);
      return;
    }

    // ElevenLabs is requested through Resource Memory's authenticated backend.
    // The API key never belongs in the Flutter client.
    if (settings.preferNaturalVoice && CloudSyncService.isSignedIn) {
      try {
        final bytes = await CloudSyncService.createSpeech(
          text: text,
          voiceId: settings.voiceId,
        );
        if (bytes != null && bytes.isNotEmpty) {
          // flutter_tts remains the reliable on-device fallback. Network audio
          // playback will be wired to the native player once the backend TTS
          // endpoint is deployed.
        }
      } catch (_) {
        // Fall through to device speech.
      }
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  static Future<void> test() =>
      speak("This is Resource Memory. I'll speak when something needs your attention.");
}
