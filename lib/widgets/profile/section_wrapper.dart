import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A collapsible card section with an optional [Edit] toggle button.
///
/// When [onEdit] is provided, shows an Edit/Cancel toggle in the section header.
/// Children swap between [viewChild] and [editChild] based on [isEditing].
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.icon,
    this.isEditing = false,
    this.onEdit,
    this.onSave,
    this.onCancel,
    this.isSaving = false,
    required this.viewChild,
    this.editChild,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final bool isEditing;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final Widget viewChild;
  final Widget? editChild;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing ? theme.colors.primary.withValues(alpha: 0.4) : theme.colors.border,
          width: isEditing ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colors.muted.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colors.foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                if (onEdit != null && !isEditing)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      foregroundColor: theme.colors.primary,
                      textStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (isEditing) ...[
                  TextButton(
                    onPressed: isSaving ? null : onCancel,
                    child: Text('Cancel', style: TextStyle(color: theme.colors.mutedForeground)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                        : Icon(Icons.save_outlined, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                    label: Text(isSaving ? 'Saving…' : 'Save', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: isEditing && editChild != null ? editChild! : viewChild,
          ),
        ],
      ),
    );
  }
}

/// A single key-value row used in read-only sections.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueWidget,
    this.copyable = false,
    this.onCopy,
    this.monoValue = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? valueWidget;
  final bool copyable;
  final VoidCallback? onCopy;
  final bool monoValue;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final displayValue = value.trim().isEmpty ? '—' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colors.mutedForeground),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        displayValue,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                          fontFamily: monoValue ? 'monospace' : null,
                        ),
                      ),
                    ),
                    if (copyable && value.trim().isNotEmpty)
                      IconButton(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        iconSize: 14,
                        tooltip: 'Copy',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                          foregroundColor: theme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

/// Editable text field used inside edit-mode sections.
class EditableField extends StatelessWidget {
  const EditableField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
