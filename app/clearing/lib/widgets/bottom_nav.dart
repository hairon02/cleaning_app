import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        indicatorColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: _NavIcon(Icons.camera_alt_outlined),
            selectedIcon: _NavIcon(Icons.camera_alt, selected: true),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: _NavIcon(Icons.map_outlined),
            selectedIcon: _NavIcon(Icons.map, selected: true),
            label: 'Map',
          ),
          NavigationDestination(
            icon: _NavIcon(Icons.flag_outlined),
            selectedIcon: _NavIcon(Icons.flag, selected: true),
            label: 'Challenges',
          ),
          NavigationDestination(
            icon: _NavIcon(Icons.leaderboard_outlined),
            selectedIcon: _NavIcon(Icons.leaderboard, selected: true),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: _NavIcon(Icons.menu_book_outlined),
            selectedIcon: _NavIcon(Icons.menu_book, selected: true),
            label: 'Journal',
          ),
        ],
      );
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.icon, {this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        color: selected ? AppColors.terracotta : AppColors.iconSurface,
        size: 25,
      );
}
