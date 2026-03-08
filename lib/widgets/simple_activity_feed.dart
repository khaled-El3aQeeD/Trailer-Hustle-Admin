import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Real-time activity stream widget.

class SimpleActivityFeed extends StatelessWidget {
  const SimpleActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: Hardcoded activity entries for demonstration
    // Replace with real activity feed from your backend/audit system
    final activities = [
      {'text': 'New user registration', 'time': '2 min ago'},
      {'text': 'Large sale completed', 'time': '5 min ago'},
      {'text': 'System maintenance', 'time': '12 min ago'},
      {'text': 'Premium subscription', 'time': '25 min ago'},
    ];

    return FCard.raw(
      style: FCardStyle(
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.theme.colors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.theme.colors.foreground.withValues(alpha: 0.12),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        contentStyle: FCardContentStyle(
          titleTextStyle: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
          ),
          subtitleTextStyle: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ).call,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activity',
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.theme.colors.foreground,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: activities.map((activity) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity['text']!,
                            style: context.theme.typography.sm,
                          ),
                        ),
                        Text(
                          activity['time']!,
                          style: context.theme.typography.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
