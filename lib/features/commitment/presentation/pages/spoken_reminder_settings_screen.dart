import 'package:flutter/material.dart';
import 'package:resource_memory/app/theme/app_colors.dart';
import 'package:resource_memory/app/theme/app_typography.dart';
import 'package:resource_memory/features/commitment/data/spoken_reminder_service.dart';
import 'package:resource_memory/features/commitment/data/phone_bridge.dart';

class SpokenReminderSettingsScreen extends StatefulWidget {
  const SpokenReminderSettingsScreen({super.key});

  @override
  State<SpokenReminderSettingsScreen> createState() => _SpokenReminderSettingsScreenState();
}

class _SpokenReminderSettingsScreenState extends State<SpokenReminderSettingsScreen> {
  bool enabled = true;
  bool natural = true;
  bool repeat = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await SpokenReminderService.loadSettings();
    if (!mounted) return;
    setState(() {
      enabled = value.enabled;
      natural = value.preferNaturalVoice;
      repeat = value.repeatUntilAcknowledged;
      loading = false;
    });
  }

  Future<void> _save() => SpokenReminderService.saveSettings(
    SpokenReminderSettings(
      enabled: enabled,
      preferNaturalVoice: natural,
      repeatUntilAcknowledged: repeat,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Spoken reminders'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                Text('Voice', style: AppTypography.h2),
                const SizedBox(height: 6),
                Text(
                  'Resource Memory can say important reminders out loud instead of relying only on a notification.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                _SettingsGroup(children: [
                  SwitchListTile(
                    title: const Text('Speak reminders'),
                    value: enabled,
                    onChanged: (value) async { setState(() => enabled = value); if (value) await PhoneBridge.requestNotificationPermission(); await _save(); },
                  ),
                  Divider(height: 1, indent: 16, color: AppColors.kBorderColor),
                  SwitchListTile(
                    title: const Text('Natural voice'),
                    subtitle: const Text('Uses enhanced voice when available; device voice is the fallback.'),
                    value: natural,
                    onChanged: enabled ? (value) { setState(() => natural = value); _save(); } : null,
                  ),
                  Divider(height: 1, indent: 16, color: AppColors.kBorderColor),
                  SwitchListTile(
                    title: const Text('Repeat until acknowledged'),
                    value: repeat,
                    onChanged: enabled ? (value) { setState(() => repeat = value); _save(); } : null,
                  ),
                ]),
                const SizedBox(height: 20),
                _SettingsGroup(children: [
                  ListTile(
                    title: const Text('Test voice'),
                    trailing: const Icon(Icons.volume_up_outlined),
                    onTap: enabled ? SpokenReminderService.test : null,
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  'Important reminders still use normal system notifications as a backup.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}
