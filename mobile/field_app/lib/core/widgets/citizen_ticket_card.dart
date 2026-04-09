import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../theme/theme.dart';

/// Compact horizontal stepper (4 milestones) aligned with Stitch "Recent Grievances" cards.
int _citizenVisualStep(String status) {
  switch (status) {
    case 'open':
      return 0;
    case 'verified':
      return 1;
    case 'assigned':
    case 'in_progress':
      return 2;
    case 'audit_pending':
      return 3;
    case 'resolved':
      return 4;
    default:
      return 0;
  }
}

const _stepLabels = ['Received', 'Verified', 'Fixing', 'Resolved'];

class CitizenTicketCard extends StatelessWidget {
  const CitizenTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final Ticket ticket;
  final VoidCallback onTap;

  Color _severityBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppDesign.severityBackground(cs, ticket.severityTier);
  }

  Color _severityFg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppDesign.severityColor(cs, ticket.severityTier);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final thumb = ticket.photoBefore.isNotEmpty ? ticket.photoBefore.first : null;
    final step = _citizenVisualStep(ticket.status);
    final loc = ticket.addressText?.trim().isNotEmpty == true
        ? ticket.addressText!
        : '${ticket.latitude.toStringAsFixed(4)}, ${ticket.longitude.toStringAsFixed(4)}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesign.cardShadow(cs),
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: thumb != null
                          ? CachedNetworkImage(
                              imageUrl: thumb,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: cs.surfaceContainerHighest,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application number',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.ticketRef.isEmpty ? 'Pending ref' : ticket.ticketRef,
                          style: AppDesign.mono(
                            tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        if (ticket.severityTier != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _severityBg(context),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                ticket.severityTier!,
                                style: tt.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _severityFg(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
                _MiniStepper(step: step, colorScheme: cs, textTheme: tt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.step,
    required this.colorScheme,
    required this.textTheme,
  });

  final int step;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final done = step > i;
      final current = step == i && step < 4;
      final filled = done || current;
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          boxShadow: current
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          done ? Icons.check : Icons.circle_outlined,
          size: done ? 16 : 12,
          color: filled
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      );
    }

    Widget bar(int i) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step > i
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dot(0),
            bar(0),
            dot(1),
            bar(1),
            dot(2),
            bar(2),
            dot(3),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final active = step == i && step < 4;
            final past = step > i;
            return Expanded(
              child: Text(
                _stepLabels[i],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  color: past
                      ? colorScheme.onSurfaceVariant
                      : active
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
