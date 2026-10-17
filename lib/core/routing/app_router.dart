import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/startup_gate.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/privacy_screen.dart';
import 'route_error_screen.dart';
import '../../features/viewer/presentation/document_viewer_screen.dart';
import '../../features/compression/presentation/compression_screen.dart';
import '../../features/editor/presentation/editor_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const StartupGate(),
      ),
      GoRoute(
        path: '/documents/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null || id <= 0
              ? const RouteErrorScreen()
              : EditorScreen(
                  documentId: id,
                  initialPage:
                      int.tryParse(state.uri.queryParameters['page'] ?? '') ??
                      0,
                );
        },
      ),
      GoRoute(
        path: '/documents/:id/compress',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null || id <= 0
              ? const RouteErrorScreen()
              : CompressionScreen(documentId: id);
        },
      ),
      GoRoute(
        path: '/documents/:id',
        name: 'document',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null || id <= 0
              ? const RouteErrorScreen()
              : DocumentViewerScreen(documentId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => const RouteErrorScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});
