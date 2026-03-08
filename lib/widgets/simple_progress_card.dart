import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Goal tracking widget with progress bar.

class SimpleProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final String label;

  const SimpleProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.theme.colors.foreground,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(value, style: context.theme.typography.sm),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: FProgress(value: progress),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
