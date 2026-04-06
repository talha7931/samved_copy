import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/repair_workflow_stepper.dart';
import '../../core/widgets/ticket_summary_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class MukadamJobScreen extends ConsumerWidget {
  const MukadamJobScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ticketDetailProvider(ticketId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job detail')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Not found'));
          final area = ticket.dimensions?.areaSqm;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              TicketSummaryCard(ticket: ticket),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primaryContainer],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.ticketRef.isEmpty ? 'Work order' : ticket.ticketRef,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusBadge(status: ticket.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Executed by SMC Department Work Gang. No billing applies.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Executed by SMC work gang under Mukadam supervision.',
                  style: tt.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (ticket.departmentNote != null || area != null || ticket.addressText != null)
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.departmentNote != null)
                        Text('Instructions: ${ticket.departmentNote}'),
                      if (area != null)
                        Text(
                          'Measured area: ${area.toStringAsFixed(2)} sqm',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      if (ticket.addressText != null) Text(ticket.addressText!),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (ticket.primaryBeforePhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: ticket.primaryBeforePhoto!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: RepairWorkflowStepper(
                  currentIndex: switch (ticket.status) {
                    'assigned' => 0,
                    'in_progress' => 1,
                    _ => 2,
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel:
            async.valueOrNull?.status == 'assigned' ? 'Start Work' : 'Upload Completion Proof',
        onPrimaryTap: () async {
          final ticket = async.valueOrNull;
          if (ticket == null) return;
          if (ticket.status == 'assigned') {
            final old = ticket.status;
            await ref.read(ticketServiceProvider).startWork(ticket.id);
            await ref.read(ticketEventServiceProvider).insertEvent(
                  ticketId: ticket.id,
                  actorRole: 'mukadam',
                  eventType: 'status_change',
                  oldStatus: old,
                  newStatus: 'in_progress',
                  notes: 'Gang deployment started by Mukadam',
                );
            ref.invalidate(ticketDetailProvider(ticketId));
            ref.invalidate(mukadamInboxProvider);
            if (context.mounted) context.go('/mukadam/inprogress/${ticket.id}');
            return;
          }
          if (context.mounted) context.push('/mukadam/camera/${ticket.id}');
        },
      ),
    );
  }
}
