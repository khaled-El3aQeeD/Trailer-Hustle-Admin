import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Team leaderboard widget.

class SimplePerformersList extends StatelessWidget {
  const SimplePerformersList({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: Hardcoded performer data for demonstration
    // Replace with real team performance data from your API
    final performers = [
      {'name': 'Sarah Chen', 'value': '\$45,230'},
      {'name': 'Michael Johnson', 'value': '\$38,950'},
      {'name': 'Emily Rodriguez', 'value': '\$31,740'},
      {'name': 'David Park', 'value': '\$28,630'},
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
              child: Text('Top Performers', style: context.theme.typography.lg),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: performers.map((performer) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          performer['name']!,
                          style: context.theme.typography.sm,
                        ),
                        const Spacer(),
                        Text(
                          performer['value']!,
                          style: context.theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
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
