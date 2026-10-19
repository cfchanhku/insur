/// Provides the shared app bar and responsive feature navigation.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// A scaffold with optional Home, Archive, and Settings navigation.
class AppScaffold extends StatelessWidget {
  /// Creates an application feature scaffold.
  const AppScaffold({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.drawer,
    required this.body,
    this.floatingActionButton,
    this.showBottomNav = true,
    this.currentNavIndex = 0,
  });

  /// App bar title.
  final String title;

  /// Optional leading app bar widget.
  final Widget? leading;

  /// Optional app bar actions.
  final List<Widget>? actions;

  /// Optional drawer shown by a leading menu action.
  final Widget? drawer;

  /// Main feature content.
  final Widget body;

  /// Optional floating action button for the feature body.
  final Widget? floatingActionButton;

  /// Whether feature navigation is visible.
  final bool showBottomNav;

  /// Selected navigation destination (Home=0, Archive=1, Settings=2).
  final int currentNavIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = <(IconData, String, String)>[
      (Icons.people, l10n.nav_home, '/home'),
      (Icons.archive, l10n.nav_archive, '/archive'),
      (Icons.settings, l10n.nav_settings, '/settings'),
    ];
    final isDesktop = MediaQuery.sizeOf(context).width > 1024;

    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: showBottomNav && isDesktop
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: currentNavIndex,
                  onDestinationSelected: (int index) =>
                      context.go(destinations[index].$3),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        ((IconData, String, String) destination) =>
                            NavigationRailDestination(
                              icon: Icon(destination.$1),
                              label: Text(destination.$2),
                            ),
                      )
                      .toList(growable: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: showBottomNav && !isDesktop
          ? NavigationBar(
              selectedIndex: currentNavIndex,
              onDestinationSelected: (int index) =>
                  context.go(destinations[index].$3),
              destinations: destinations
                  .map(
                    ((IconData, String, String) destination) =>
                        NavigationDestination(
                          icon: Icon(destination.$1),
                          label: destination.$2,
                        ),
                  )
                  .toList(growable: false),
            )
          : null,
    );
  }
}
