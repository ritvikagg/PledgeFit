import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PledgeMainShell extends StatelessWidget {
  const PledgeMainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Goal',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Light app bar with optional back.
class PledgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PledgeAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
  });

  final String title;
  final bool showBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : null,
      actions: actions,
    );
  }
}

class PledgePageScaffold extends StatelessWidget {
  const PledgePageScaffold({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    required this.body,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget body;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PledgeAppBar(
        title: title,
        showBack: showBack,
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
