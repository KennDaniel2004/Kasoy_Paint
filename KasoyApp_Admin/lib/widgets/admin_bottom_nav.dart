import 'package:flutter/material.dart';

import '../main.dart';

enum AdminTab { home, requests, messages, users, profile }

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final AdminTab current;
  final ValueChanged<AdminTab> onTap;

  static const _items = [
    _Item(AdminTab.home, 'Home', Icons.home_outlined, Icons.home_rounded),
    _Item(AdminTab.requests, 'Requests', Icons.assignment_outlined,
        Icons.assignment_rounded),
    _Item(AdminTab.messages, 'Messages', Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_rounded),
    _Item(AdminTab.users, 'Users', Icons.people_outline_rounded,
        Icons.people_rounded),
    _Item(AdminTab.profile, 'Profile', Icons.person_outline_rounded,
        Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border:
            Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final item in _items)
                Expanded(
                  child: _Btn(
                    item: item,
                    selected: item.tab == current,
                    onTap: () => onTap(item.tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  const _Item(this.tab, this.label, this.icon, this.activeIcon);
  final AdminTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _Btn extends StatelessWidget {
  const _Btn({required this.item, required this.selected, required this.onTap});

  final _Item item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AdminColors.primaryOrange : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.activeIcon : item.icon,
                color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}