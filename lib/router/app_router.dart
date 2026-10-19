/// GoRouter configuration for the app shell.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/archive/screens/archive_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/clients/screens/client_detail_screen.dart';
import '../features/clients/screens/client_form_screen.dart';
import '../features/common/placeholder_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/lock/screens/lock_screen.dart';
import '../features/setup/screens/setup_wizard_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../l10n/app_localizations.dart';

/// Provides the app router.
///
/// Redirects are intentionally omitted while SplashScreen performs the initial
/// asynchronous KeyManager check. Add centralized redirects when the route
/// graph grows, keyed to the current KeyManager session state.
final routerProvider = Provider<GoRouter>((Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context).recovery_title,
          message: AppLocalizations.of(context).coming_soon,
        ),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) =>
            ClientDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) =>
            ClientFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context).settings_title,
          message: AppLocalizations.of(context).coming_soon,
        ),
      ),
      GoRoute(
        path: '/policies/new',
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context).client_add_policy,
          message: AppLocalizations.of(context).coming_soon,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
