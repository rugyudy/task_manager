import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavDestinationItem {
  const NavDestinationItem({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}

/// サイドバー（Drawer / NavigationRail）で切り替える画面の一覧。
const navDestinations = <NavDestinationItem>[
  NavDestinationItem(path: '/', label: 'ホーム', icon: Icons.dashboard_outlined),
  NavDestinationItem(
    path: '/tasks',
    label: 'タスク',
    icon: Icons.check_circle_outline,
  ),
  NavDestinationItem(
    path: '/schedules',
    label: 'スケジュール',
    icon: Icons.calendar_month_outlined,
  ),
  NavDestinationItem(path: '/memos', label: 'メモ', icon: Icons.note_outlined),
];

const _wideBreakpoint = 720.0;

/// 画面幅に応じて Drawer(スマホ) / NavigationRail(タブレット・PC) を
/// 切り替える共通レイアウト。go_router の ShellRoute から利用する。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final index = navDestinations.indexWhere(
      (d) => d.path == location || (d.path != '/' && location.startsWith(d.path)),
    );
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final isWide = MediaQuery.of(context).size.width >= _wideBreakpoint;

    void onSelect(int index) => context.go(navDestinations[index].path);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in navDestinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(navDestinations[selectedIndex].label)),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'タスク管理アプリ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              for (var i = 0; i < navDestinations.length; i++)
                ListTile(
                  leading: Icon(navDestinations[i].icon),
                  title: Text(navDestinations[i].label),
                  selected: i == selectedIndex,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}
