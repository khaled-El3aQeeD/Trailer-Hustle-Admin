import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:trailerhustle_admin/models/navigation_item.dart';
import 'package:trailerhustle_admin/models/document_item.dart';

/// Service for managing navigation data and operations.
///
/// Provides navigation hierarchy and document links for the dashboard sidebar.
/// Currently uses sample data for demonstration purposes.
class NavigationService {
  
  /// Get primary navigation items
  static List<NavigationItem> getMainNavigation({required String activeUrl}) {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: FIcons.layoutDashboard,
        url: '/dashboard',
        isActive: activeUrl == '/dashboard',
      ),
      NavigationItem(
        title: 'Giveaways',
        icon: FIcons.gift,
        url: '/giveaways',
        isActive: activeUrl == '/giveaways',
      ),
      NavigationItem(
        title: 'Trailers',
        icon: Icons.local_movies_outlined,
        url: '/trailers',
        isActive: activeUrl.startsWith('/trailers'),
        children: [
          NavigationItem(
            title: 'Review submitted trailers',
            icon: Icons.rate_review_outlined,
            url: '/trailers/review',
            isActive: activeUrl == '/trailers/review',
          ),
          NavigationItem(
            title: 'Edit Trailer Types',
            icon: Icons.category_outlined,
            url: '/trailers/types',
            isActive: activeUrl == '/trailers/types',
          ),
          NavigationItem(
            title: 'Edit Manufacturers',
            icon: Icons.factory_outlined,
            url: '/trailers/manufacturers',
            isActive: activeUrl == '/trailers/manufacturers',
          ),
          NavigationItem(
            title: 'View all Trailers',
            icon: Icons.list_alt_outlined,
            url: '/trailers/all',
            isActive: activeUrl == '/trailers/all',
          ),
        ],
      ),
      NavigationItem(
        title: 'Notifications',
        icon: Icons.notifications_none_outlined,
        url: '/notifications',
        isActive: activeUrl == '/notifications',
      ),
    ];
  }

  /// Get secondary navigation items
  static List<NavigationItem> getSecondaryNavigation() {
    return [
      NavigationItem(
        title: 'Settings',
        icon: FIcons.settings,
        url: '#',
      ),
    ];
  }

  /// Get document items
  static List<DocumentItem> getDocuments() {
    return [
      // Intentionally empty: document links removed from the sidebar menu.
    ];
  }
}