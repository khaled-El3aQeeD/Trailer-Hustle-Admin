import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// KPI display widget with trend indicators.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? percentage;
  final String? trend;
  final String? description;
  final bool isPositive;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.percentage,
    this.trend,
    this.description,
    this.isPositive = true,
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
          padding: const EdgeInsets.all(24),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: context.theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                if (percentage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.colors.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? FIcons.trendingUp : FIcons.trendingDown,
                          size: 12,
                          color: context.theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          percentage!,
                          style: context.theme.typography.xs.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Main value
            Text(
              value,
              style: context.theme.typography.xl3.copyWith(
                fontWeight: FontWeight.bold,
                color: context.theme.colors.foreground,
              ),
            ),

            const SizedBox(height: 8),

            // Trend and description
            if (trend != null || description != null) ...[
              if (trend != null)
                Row(
                  children: [
                    Icon(
                      isPositive ? FIcons.trendingUp : FIcons.trendingDown,
                      size: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend!,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                  ],
                ),
              if (trend != null && description != null)
                const SizedBox(height: 4),
              if (description != null)
                Text(
                  description!,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
