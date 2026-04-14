import 'package:flutter/material.dart';

import '../constants/status_labels.dart';
import '../theme/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  ({Color bg, Color fg}) _colors(ColorScheme cs) {
    switch (status) {
      case 'resolved':
        final color = AppDesign.severityColor(cs, 'resolved');
        return (bg: color.withValues(alpha: 0.14), fg: color);
      case 'rejected':
        return (bg: cs.errorContainer, fg: cs.onErrorContainer);
      case 'audit_pending':
        final color = AppDesign.severityColor(cs, 'high');
        return (bg: color.withValues(alpha: 0.14), fg: color);
      case 'in_progress':
        final color = AppDesign.severityColor(cs, 'medium');
        return (bg: color.withValues(alpha: 0.14), fg: color);
      case 'assigned':
      case 'verified':
      case 'open':
        return (
          bg: cs.primaryContainer.withValues(alpha: 0.14),
          fg: cs.primary,
        );
      default:
        return (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = _colors(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ticketStatusLabel(status),
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: c.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
