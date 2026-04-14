import 'package:flutter/material.dart';

/// Represents an app screen a push notification can navigate to.
class LandingScreen {
  final String notificationType;
  final String label;
  final IconData icon;
  final String hint;
  final List<String> keywords;

  const LandingScreen({
    required this.notificationType,
    required this.label,
    required this.icon,
    required this.hint,
    required this.keywords,
  });

  /// All available landing screens for push notifications.
  static const List<LandingScreen> all = [
    LandingScreen(
      notificationType: '4',
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      hint: 'Users will land on the Notifications screen',
      keywords: ['notification', 'alert', 'update', 'announce', 'news'],
    ),
    LandingScreen(
      notificationType: '5',
      label: 'Giveaways',
      icon: Icons.card_giftcard_outlined,
      hint: 'Users will land on the Giveaways tab',
      keywords: ['giveaway', 'raffle', 'winner', 'prize', 'sweepstake'],
    ),
    LandingScreen(
      notificationType: '9',
      label: 'Subscription',
      icon: Icons.workspace_premium_outlined,
      hint: 'Users will land on the Subscription screen',
      keywords: [
        'subscribe',
        'subscription',
        'upgrade',
        'plan',
        'premium',
        'pro',
      ],
    ),
    LandingScreen(
      notificationType: '10',
      label: 'Home / Map',
      icon: Icons.home_outlined,
      hint: 'Users will land on the Home map screen',
      keywords: ['home', 'map', 'explore', 'browse', 'discover', 'trailer'],
    ),
    LandingScreen(
      notificationType: '11',
      label: 'Inbox',
      icon: Icons.chat_outlined,
      hint: 'Users will land on the Inbox tab',
      keywords: ['message', 'chat', 'inbox', 'dm', 'conversation'],
    ),
    LandingScreen(
      notificationType: '12',
      label: 'Profile',
      icon: Icons.person_outlined,
      hint: 'Users will land on their Profile tab',
      keywords: ['profile', 'account'],
    ),
  ];

  /// Default landing screen (Notifications).
  static LandingScreen get defaultScreen => all.first;

  /// Detect the best landing screen from title and body text.
  /// Returns the matching screen or [defaultScreen] if no keywords match.
  static LandingScreen detectFromContent(String title, String body) {
    final combined = '${title.toLowerCase()} ${body.toLowerCase()}';
    for (final screen in all) {
      for (final keyword in screen.keywords) {
        if (combined.contains(keyword)) {
          return screen;
        }
      }
    }
    return defaultScreen;
  }

  /// Find a landing screen by its notification type value.
  static LandingScreen? fromType(String type) {
    for (final screen in all) {
      if (screen.notificationType == type) return screen;
    }
    return null;
  }

  /// Human-readable label for a notification type value.
  static String labelForType(String type) {
    return fromType(type)?.label ?? 'Notifications';
  }
}
