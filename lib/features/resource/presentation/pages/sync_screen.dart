import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/routing/app_route.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _createAccount = false;

  Future<void> _connect() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 8) return;

    setState(() => _busy = true);
    try {
      if (_createAccount) {
        await CloudSyncService.signUp(email: email, password: password);
      } else {
        await CloudSyncService.signIn(email: email, password: password);
      }
      final count = await ResourceStore.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync connected. $count resources available.')),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not connect sync: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    try {
      final count = await ResourceStore.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $count resources.')),
      );
      setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await CloudSyncService.signOut();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = CloudSyncService.isConfigured;
    final signedIn = CloudSyncService.isSignedIn;
    final localCount = ResourceStore.getAll().length;

    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text('Sync devices', style: AppTypography.h3),
                    ]),
                    const SizedBox(height: 28),
                    Text('Desktop + mobile', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Use the same Resource Memory account on each device. Hive stays local for speed; Neon is the canonical synced library behind the Resource API.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/${Routes.installAppScreen}'),
                        icon: const Icon(Icons.install_mobile_outlined),
                        label: const Text('Install Resource Memory on this device'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!configured)
                      const _StatusCard(
                        icon: Icons.cloud_off_outlined,
                        title: 'Cloud sync needs configuration',
                        body: 'The app needs RESOURCE_API_URL for the Cloudflare Worker that connects to Neon.',
                      )
                    else if (signedIn) ...[
                      _StatusCard(
                        icon: Icons.cloud_done_outlined,
                        title: 'Sync is connected',
                        body: '${CloudSyncService.currentEmail ?? 'Signed in'} • $localCount resources on this device',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _syncNow,
                          icon: const Icon(Icons.sync),
                          label: Text(_busy ? 'Syncing…' : 'Sync now'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cross-device check: sync on desktop, then sync here. The resource count should match and your links, screenshots, and voice memories should appear in Library.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _busy ? null : _signOut,
                          child: const Text('Sign out of sync'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          helperText: 'At least 8 characters',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _connect,
                          icon: const Icon(Icons.cloud_sync_outlined),
                          label: Text(
                            _busy
                                ? 'Connecting…'
                                : (_createAccount
                                    ? 'Create sync account'
                                    : 'Connect sync'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _createAccount = !_createAccount),
                          child: Text(
                            _createAccount
                                ? 'I already have a sync account'
                                : 'Create a sync account',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StatusCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppColors.accentMuted,
          child: Icon(icon, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(body, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}
