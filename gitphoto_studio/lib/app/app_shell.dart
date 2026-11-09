import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/pixel_mascot.dart';
import 'destinations.dart';
import 'theme/app_theme.dart';

/// Coquille de navigation adaptative :
/// - écran large : menu latéral permanent avec les neuf écrans ;
/// - téléphone : barre inférieure (4 écrans principaux + « Plus ») et tiroir.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _goTo(AppDestination destination) {
    _scaffoldKey.currentState?.closeDrawer();
    context.go(destination.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = AppDestination.fromLocation(widget.location);
    final isWide = MediaQuery.sizeOf(context).width >= AppTheme.wideBreakpoint;

    final drawer = _StudioNavigationDrawer(current: current, onSelected: _goTo);

    if (isWide) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          children: [
            SizedBox(width: 280, child: drawer),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    final primaryIndex = AppDestination.primary.indexOf(current);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(current.label(l10n)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l10n.navMenu,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: drawer,
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: primaryIndex >= 0
            ? primaryIndex
            : AppDestination.primary.length,
        onDestinationSelected: (index) {
          if (index < AppDestination.primary.length) {
            _goTo(AppDestination.primary[index]);
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        destinations: [
          for (final d in AppDestination.primary)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label(l10n),
            ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}

class _StudioNavigationDrawer extends StatelessWidget {
  const _StudioNavigationDrawer({
    required this.current,
    required this.onSelected,
  });

  final AppDestination current;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return NavigationDrawer(
      selectedIndex: current.index,
      onDestinationSelected: (i) => onSelected(AppDestination.values[i]),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          child: Row(
            children: [
              const PixelMascot(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(l10n.appTagline, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final d in AppDestination.values)
          NavigationDrawerDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label(l10n)),
          ),
      ],
    );
  }
}
