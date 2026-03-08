import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trailerhustle_admin/models/sponsor_data.dart';

/// Airbnb-style info card for a Sponsor (Business) record.
class SponsorInfoCard extends StatelessWidget {
  final SponsorData sponsor;

  const SponsorInfoCard({super.key, required this.sponsor});

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _valueOrDash(String v) => v.trim().isEmpty ? '—' : v.trim();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final name = _valueOrDash(sponsor.name);
    final email = _valueOrDash(sponsor.email);
    final phone = _valueOrDash(sponsor.phone);
    final created = _formatDate(sponsor.createdAt);

    final initial = name == '—' ? '?' : name.trim().characters.first.toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      theme.colors.primary.withValues(alpha: 0.20),
                      theme.colors.primary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: theme.colors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colors.primary,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sponsor',
                      style: theme.typography.xs.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colors.mutedForeground,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colors.foreground,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Text(
                  'ID ${sponsor.id}',
                  style: theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SponsorInfoGrid(
            createdAt: created,
            email: email,
            phone: phone,
            id: sponsor.id.toString(),
          ),
        ],
      ),
    );
  }
}

class _SponsorInfoGrid extends StatelessWidget {
  final String createdAt;
  final String email;
  final String phone;
  final String id;

  const _SponsorInfoGrid({required this.createdAt, required this.email, required this.phone, required this.id});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          final items = [
            _SponsorInfoItem(icon: Icons.badge_outlined, label: 'ID', value: id),
            _SponsorInfoItem(icon: Icons.event_outlined, label: 'Date created', value: createdAt),
            _SponsorInfoItem(icon: Icons.mail_outline, label: 'E-mail', value: email),
            _SponsorInfoItem(icon: Icons.phone_outlined, label: 'Phone', value: phone),
          ];

          if (isNarrow) {
            return Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  items[i],
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: items[0]),
              const SizedBox(width: 10),
              Expanded(child: items[1]),
              const SizedBox(width: 10),
              Expanded(child: items[2]),
              const SizedBox(width: 10),
              Expanded(child: items[3]),
            ],
          );
        },
      ),
    );
  }
}

class _SponsorInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SponsorInfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: theme.colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.typography.xs.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colors.foreground,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
