import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:resource_memory/app/routing/go_router.dart';
import 'package:resource_memory/app/theme/app_theme.dart';
import 'package:resource_memory/features/commitment/data/commitment_store.dart';
import 'package:resource_memory/features/commitment/data/phone_bridge.dart';
import 'package:resource_memory/features/resource/data/cloud_sync_service.dart';
import 'package:resource_memory/features/resource/data/incoming_share_service.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await CloudSyncService.initialize();
  await ResourceStore.initialize();
  await CommitmentStore.initialize();
  if (CloudSyncService.isSignedIn) {
    await ResourceStore.syncNow();
  }
  runApp(const ResourceMemoryApp());
}

class ResourceMemoryApp extends StatefulWidget {
  const ResourceMemoryApp({super.key});

  @override
  State<ResourceMemoryApp> createState() => _ResourceMemoryAppState();
}

class _ResourceMemoryAppState extends State<ResourceMemoryApp> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _listenForShares();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePhoneShortcut());
  }

  Future<void> _handlePhoneShortcut() async {
    try {
      final shortcut = await PhoneBridge.getPendingShortcut();
      if (!mounted || shortcut == null) return;
      if (shortcut == 'commitments') {
        goRouter.go('/commitments');
      } else if (shortcut == 'remember') {
        goRouter.go('/voice-memory');
      }
    } catch (_) {}
  }

  Future<void> _listenForShares() async {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _consumeSharedItems,
      onError: (_) {},
    );

    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      await _consumeSharedItems(initial);
      await ReceiveSharingIntent.instance.reset();
    } catch (_) {}
  }

  Future<void> _consumeSharedItems(List<SharedMediaFile> items) async {
    if (items.isEmpty) return;
    final saved = await IncomingShareService.saveSharedItems(items);
    if (saved > 0) {
      goRouter.go('/library');
    }
    await ReceiveSharingIntent.instance.reset();
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep MaterialApp.router at the root. Wrapping the entire router in a
    // full-screen GestureDetector can win the hit-test arena on iOS standalone
    // PWAs and leave the UI rendered but controls effectively untappable.
    // Individual input screens handle focus dismissal where needed.
    return MaterialApp.router(
      title: 'NanyNany',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
    );
  }
}
