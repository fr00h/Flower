import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';
import '../state/cart_notifier.dart';
import 'destinations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final path = GoRouterState.of(context).uri.path;
    final size = screenSizeOf(context);

    final destinations = destinationsFor(auth.user?.role);
    final cart = context.watch<CartNotifier>().count;

    final index = destinations.lastIndexWhere(
      (d) => d.path == '/' ? path == '/' : path.startsWith(d.path),
    );
    final selectedIndex = index == -1 ? null : index;
    void onSelected(int i) => context.go(destinations[i].path);

    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: child,
      ),
    );

    final appBar = AppBar(
      title: const Text('Цветочный магазин'),
      actions: [
        if (cart > 0)
          IconButton(
            tooltip: 'Корзина',
            onPressed: () => context.go('/cart'),
            icon: Badge(
              label: Text('$cart'),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        if (size != ScreenSize.compact) Text(auth.user?.name ?? ''),
        IconButton(
          tooltip: 'Выйти',
          icon: const Icon(Icons.logout),
          onPressed: () {
            context.read<CartNotifier>().clear();
            context.read<AuthNotifier>().logout();
          },
        ),
        const SizedBox(width: 8),
      ],
    );

    if (size == ScreenSize.compact) {
      final main = destinations.take(4).toList();
      final more = destinations.skip(4).toList();
      final barIndex = selectedIndex == null || selectedIndex >= 4
          ? (more.isEmpty ? 0 : 4)
          : selectedIndex;

      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: barIndex,
          onDestinationSelected: (i) {
            if (i < 4) {
              onSelected(i);
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              builder: (sheetContext) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final d in more)
                      ListTile(
                        leading: Icon(d.icon),
                        title: Text(d.label),
                        selected: path.startsWith(d.path),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.go(d.path);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in main)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
            if (more.isNotEmpty)
              const NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: 'Ещё',
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onSelected,
                    extended: size == ScreenSize.expanded,
                    labelType: size == ScreenSize.expanded
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
