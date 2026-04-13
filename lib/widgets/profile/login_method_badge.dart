import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Large, color-coded badge showing the login method used by a business account.
class LoginMethodBadge extends StatelessWidget {
  const LoginMethodBadge({super.key, required this.method});

  final String method;

  Color _bgColor() {
    switch (method.toLowerCase()) {
      case 'email':
        return const Color(0xFF4A90D9);
      case 'phone':
        return const Color(0xFF34C759);
      case 'google':
        return const Color(0xFFEA4335);
      case 'apple':
        return const Color(0xFF333333);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _icon() {
    switch (method.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_android_outlined;
      case 'google':
        return Icons.g_mobiledata_outlined;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.login_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            method,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small colored pill for tier, status, etc.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
