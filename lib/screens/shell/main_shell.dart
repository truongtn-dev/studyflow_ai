import 'package:flutter/material.dart';

import '../home/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import 'placeholder_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _TabItem(Icons.task_alt_outlined, Icons.task_alt_rounded, 'Tasks'),
    _TabItem(Icons.timer_outlined, Icons.timer_rounded, 'Focus'),
    _TabItem(Icons.style_outlined, Icons.style_rounded, 'Cards'),
    _TabItem(Icons.person_outlined, Icons.person_rounded, 'Profile'),
  ];

  final _screens = const [
    DashboardScreen(),
    TasksTab(),
    FocusTab(),
    CardsTab(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: const Color(0xFF5B5FEF),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
