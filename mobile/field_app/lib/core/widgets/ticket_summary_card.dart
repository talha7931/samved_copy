import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../constants/status_labels.dart';

class TicketSummaryCard extends StatelessWidget {
  const TicketSummaryCard({
    super.key,
    required this.ticket,
  });

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final severity = (ticket.severityTier ?? 'MEDIUM').toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.ticketRef,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(
                label: Text(severity),
                padding: EdgeInsets.zero,
                labelStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                side: BorderSide.none,
                backgroundColor: cs.tertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ticket.addressText ?? ticket.roadName ?? 'Location unavailable',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _chip(context, 'Status: ${ticketStatusLabel(ticket.status)}'),
              if (ticket.workType != null) _chip(context, ticket.workType!),
              if (ticket.estimatedCost != null)
                _chip(context, 'Est. Rs ${ticket.estimatedCost!.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
