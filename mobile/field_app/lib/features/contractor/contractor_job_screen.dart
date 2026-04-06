import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/status_labels.dart';
import '../../core/widgets/repair_workflow_stepper.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class ContractorJobScreen extends ConsumerWidget {
  const ContractorJobScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ticketDetailProvider(ticketId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
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
                        ticket.ticketRef.isEmpty ? 'Job' : ticket.ticketRef,
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
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billing', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      ticket.billId == null
                          ? 'No bill linked to this ticket yet.'
                          : 'Bill recorded in system (details on web dashboard).',
                    ),
                    if (ticket.ratePerUnit != null)
                      Text(
                        'Locked rate: ₹${ticket.ratePerUnit!.toStringAsFixed(2)}',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (ticket.estimatedCost != null)
                      Text(
                        'Estimated payable: ₹${ticket.estimatedCost!.toStringAsFixed(2)}',
                        style: tt.titleSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Status: ${ticketStatusLabelForRole(ticket.status, 'contractor')}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (ticket.addressText != null) Text(ticket.addressText!),
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/contractor/issue/${ticket.id}'),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Flag issue'),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: async.valueOrNull?.status == 'assigned'
            ? 'Start Work - Mark In Progress'
            : 'Upload After Photo & Submit for Audit',
        onPrimaryTap: () async {
          final ticket = async.valueOrNull;
          if (ticket == null) return;
          if (ticket.status == 'assigned') {
            final old = ticket.status;
            await ref.read(ticketServiceProvider).startWork(ticket.id);
            await ref.read(ticketEventServiceProvider).insertEvent(
                  ticketId: ticket.id,
                  actorRole: 'contractor',
                  eventType: 'status_change',
                  oldStatus: old,
                  newStatus: 'in_progress',
                  notes: 'Contractor started work',
                );
            ref.invalidate(ticketDetailProvider(ticketId));
            ref.invalidate(contractorInboxProvider);
            if (context.mounted) context.go('/contractor/inprogress/${ticket.id}');
            return;
          }
          if (context.mounted) context.push('/contractor/camera/${ticket.id}');
        },
      ),
    );
  }
}
