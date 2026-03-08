import 'package:flutter/material.dart';

/// Navigation menu item with optional hierarchical children
class NavigationItem {
  final String title;
  final IconData icon;
  final String url;
  final bool isActive;
  final List<NavigationItem>? children;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.url,
    this.isActive = false,
    this.children,
  });
}