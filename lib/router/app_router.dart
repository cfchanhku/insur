/// GoRouter configuration for the app shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/archive/screens/archive_screen.dart';
import '../features/audit/screens/audit_log_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/recovery_screen.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/backup/screens/restore_screen.dart';
import '../features/clients/screens/client_detail_screen.dart';
import '../features/clients/screens/client_form_screen.dart';
import '../features/common/placeholder_screen.dart';
import '../features/export/screens/export_pdf_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/lock/screens/lock_screen.dart';
import '../features/plans/screens/plan_form_screen.dart';
import '../features/policies/screens/policy_detail_screen.dart';
import '../features/policies/screens/policy_form_screen.dart';
import '../features/settings/screens/settings_screen.dart';
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
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const SetupWizardScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/lock',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const LockScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: '/recovery',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const RecoveryScreen()),
      ),
      GoRoute(
        path: '/clients/new',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const ClientFormScreen()),
      ),
      GoRoute(
        path: '/clients/:id',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          ClientDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          ClientFormScreen(id: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/clients/:clientId/policies/new',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PolicyFormScreen(clientId: state.pathParameters['clientId']!),
        ),
      ),
      GoRoute(
        path: '/policies/:id',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PolicyDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/policies/:id/edit',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PolicyFormScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/policies/:policyId/plans/new',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PlanFormScreen(policyId: state.pathParameters['policyId']!),
        ),
      ),
      GoRoute(
        path: '/plans/:id/edit',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PlanFormScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/archive',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const ArchiveScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/audit',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const AuditLogScreen()),
      ),
      GoRoute(
        path: '/backup',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const BackupScreen()),
      ),
      GoRoute(
        path: '/restore',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const RestoreScreen()),
      ),
      GoRoute(
        path: '/export',
        pageBuilder: (context, state) =>
            _fadePage(context, state, const ExportPdfScreen()),
      ),
      GoRoute(
        path: '/policies/new',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          PlaceholderScreen(
            title: AppLocalizations.of(context).client_add_policy,
            message: AppLocalizations.of(context).coming_soon,
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

CustomTransitionPage<void> _fadePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 200),
  reverseTransitionDuration: const Duration(milliseconds: 150),
  transitionsBuilder:
      (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) => FadeTransition(opacity: animation, child: child),
);
