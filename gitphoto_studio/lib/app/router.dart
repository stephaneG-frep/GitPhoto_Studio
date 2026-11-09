import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_agent/presentation/agent_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/gallery/presentation/media_viewer_screen.dart';
import '../features/github/presentation/github_screen.dart';
import '../features/github/presentation/repo_browser_screen.dart';
import '../features/help/presentation/help_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/media_editor/presentation/media_edit_page.dart';
import '../features/media_editor/presentation/media_editor_screen.dart';
import '../features/publishing/presentation/publish_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';
import 'destinations.dart';

Widget _screenFor(AppDestination destination) => switch (destination) {
  AppDestination.dashboard => const DashboardScreen(),
  AppDestination.gallery => const GalleryScreen(),
  AppDestination.editor => const MediaEditorScreen(),
  AppDestination.github => const GithubScreen(),
  AppDestination.publish => const PublishScreen(),
  AppDestination.agent => const AgentScreen(),
  AppDestination.history => const HistoryScreen(),
  AppDestination.settings => const SettingsScreen(),
  AppDestination.help => const HelpScreen(),
};

GoRouter createRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final d in AppDestination.values)
            GoRoute(
              path: d.path,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: d == AppDestination.publish
                    ? PublishScreen(
                        owner: state.uri.queryParameters['owner'],
                        repo: state.uri.queryParameters['repo'],
                        branch: state.uri.queryParameters['branch'],
                        folder: state.uri.queryParameters['folder'],
                      )
                    : _screenFor(d),
              ),
            ),
          GoRoute(
            path: '/editor/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: MediaEditPage(
                mediaId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
              ),
            ),
          ),
          GoRoute(
            path: '/github/repo/:owner/:name',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: RepoBrowserScreen(
                owner: state.pathParameters['owner']!,
                name: state.pathParameters['name']!,
              ),
            ),
          ),
        ],
      ),
      // Visionneuse plein écran, hors de la coquille de navigation.
      GoRoute(
        path: '/media/:id',
        builder: (context, state) => MediaViewerScreen(
          mediaId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
    ],
  );
}
