import 'package:flutter/material.dart';

class MenuItemData {
  final String id;
  final String title;
  final IconData icon;
  final Widget page;
  final List<int> rolesAllowed; // 1 admin, 2 RH, 3 empleado

  const MenuItemData({
    required this.id,
    required this.title,
    required this.icon,
    required this.page,
    required this.rolesAllowed,
  });
}


