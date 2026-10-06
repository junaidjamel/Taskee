import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/features/commitment/presentation/pages/commitments_screen.dart';
import 'package:resource_memory/features/commitment/presentation/pages/spoken_reminder_settings_screen.dart';
import 'package:resource_memory/features/project/presentation/pages/project_match_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/install_app_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/library_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/resource_detail_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/resource_home_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/save_resource_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/sync_screen.dart';
import 'package:resource_memory/features/resource/presentation/pages/voice_memory_screen.dart';

final List<RouteBase> resourceRoutes = <RouteBase>[
  GoRoute(path: Routes.homeScreen, builder: (context, state) => const ResourceHomeScreen(), routes: <RouteBase>[
    GoRoute(path: Routes.saveResourceScreen, builder: (context, state) => const SaveResourceScreen()),
    GoRoute(path: Routes.voiceMemoryScreen, builder: (context, state) => const VoiceMemoryScreen()),
    GoRoute(path: Routes.libraryScreen, builder: (context, state) => const LibraryScreen()),
    GoRoute(path: Routes.commitmentsScreen, builder: (context, state) => const CommitmentsScreen()),
    GoRoute(path: Routes.spokenReminderSettingsScreen, builder: (context, state) => const SpokenReminderSettingsScreen()),
    GoRoute(path: 'resource/:id', builder: (context, state) => ResourceDetailScreen(resourceId: state.pathParameters['id']!)),
    GoRoute(path: Routes.projectMatchScreen, builder: (context, state) => const ProjectMatchScreen()),
    GoRoute(path: Routes.syncScreen, builder: (context, state) => const SyncScreen()),
    GoRoute(path: Routes.installAppScreen, builder: (context, state) => const InstallAppScreen()),
  ]),
];
