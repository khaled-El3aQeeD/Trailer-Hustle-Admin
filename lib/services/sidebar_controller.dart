import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global sidebar collapse state, persisted across sessions.
class SidebarController extends ChangeNotifier {
  static const _key = 'sidebar_collapsed';

  bool _collapsed = false;
  bool get collapsed => _collapsed;

  /// Whether the sidebar was auto-collapsed due to screen width.
  /// When true, manual toggle still works but auto-collapse won't fight it.
  bool _autoCollapsed = false;

  SidebarController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _collapsed = prefs.getBool(_key) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, _collapsed);
    } catch (_) {}
  }

  void toggle() {
    _collapsed = !_collapsed;
    _autoCollapsed = false;
    _persist();
    notifyListeners();
  }

  /// Called by layout builders when available width is narrow.
  /// Only collapses if user hasn't manually expanded.
  void autoCollapseIfNeeded(double screenWidth, {double threshold = 1280}) {
    if (screenWidth < threshold && !_collapsed) {
      _collapsed = true;
      _autoCollapsed = true;
      _persist();
      notifyListeners();
    } else if (screenWidth >= threshold && _collapsed && _autoCollapsed) {
      _collapsed = false;
      _autoCollapsed = false;
      _persist();
      notifyListeners();
    }
  }
}
