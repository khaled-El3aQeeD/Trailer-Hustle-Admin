import 'package:flutter/material.dart';
import 'package:trailerhustle_admin/services/push_notification_service.dart';

/// Displays recent push campaigns in a compact table.
class CampaignHistoryTable extends StatelessWidget {
  final List<PushCampaign> campaigns;

  const CampaignHistoryTable({super.key, required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (campaigns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No campaigns sent yet',
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 40,
              horizontalMargin: 12,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(
                colors.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              columns: [
                DataColumn(
                  label: Text('Date',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Title',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Filters',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  numeric: true,
                  label: Text('Sent',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  numeric: true,
                  label: Text('Failed',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Status',
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: campaigns.map((c) {
                return DataRow(cells: [
                  DataCell(Text(
                    _formatDate(c.createdAt),
                    style: textTheme.bodySmall,
                  )),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        c.title,
                        style: textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(
                    c.filterSummary ?? '—',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  )),
                  DataCell(Text(
                    c.totalSent.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                  DataCell(Text(
                    c.totalFailed.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: c.totalFailed > 0
                          ? const Color(0xFFDC2626)
                          : colors.onSurfaceVariant,
                      fontWeight:
                          c.totalFailed > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  )),
                  DataCell(_StatusBadge(status: c.status)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'completed' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          'Completed'
        ),
      'sending' => (
          const Color(0xFFFEF9C3),
          const Color(0xFFCA8A04),
          'Sending...'
        ),
      'partial' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          'Partial'
        ),
      'failed' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          'Failed'
        ),
      _ => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
