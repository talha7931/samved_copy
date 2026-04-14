import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/status_labels.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/repair_workflow_stepper.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../core/widgets/ticket_summary_card.dart';
import '../../models/ticket.dart';
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
          final lookupAsync = ref.watch(ticketLookupProvider(ticket));
          final area = ticket.dimensions?.areaSqm;
          final depthCm = ticket.dimensions == null
              ? null
              : (ticket.dimensions!.depthM * 100).round();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              if (ticket.primaryBeforePhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: ticket.primaryBeforePhoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (ticket.primaryBeforePhoto != null) const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppDesign.navyGradient,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: ticket.status),
                        const SizedBox(height: 6),
                        if (ticket.severityTier != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesign.severityColor(cs, ticket.severityTier)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              ticket.severityTier!,
                              style: tt.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TicketSummaryCard(ticket: ticket),
              const SizedBox(height: 16),
              lookupAsync.when(
                data: (lookup) => Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(child: _meta(context, 'Zone', lookup.zoneName ?? '-')),
                      Expanded(child: _meta(context, 'Prabhag', lookup.prabhagName ?? '-')),
                      Expanded(
                        child: _meta(
                          context,
                          'JE',
                          lookup.assignedJeName ?? '-',
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppDesign.cardShadow(cs),
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
                  boxShadow: AppDesign.cardShadow(cs),
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
                    if (ticket.workType != null)
                      Text('Work type: ${ticket.workType!}', style: tt.bodyMedium),
                    if (area != null)
                      Text('Measured area: ${area.toStringAsFixed(2)} sqm', style: tt.bodyMedium),
                    if (depthCm != null)
                      Text('Depth: $depthCm cm', style: tt.bodyMedium),
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
              if (ticket.addressText != null)
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    ticket.addressText!,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              if (ticket.addressText != null) const SizedBox(height: 10),
              Text(
                'Status: ${ticketStatusLabelForRole(ticket.status, 'contractor')}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps(ticket),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('View on map'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: lookupAsync.when(
                      data: (lookup) => OutlinedButton.icon(
                        onPressed: () => _callAssignedJe(
                          context: context,
                          ref: ref,
                          assignedJeId: ticket.assignedJe,
                          fallbackJeName: lookup.assignedJeName,
                        ),
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text('Contact JE'),
                      ),
                      loading: () => OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text('Contact JE'),
                      ),
                      error: (_, __) => OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text('Contact JE'),
                      ),
                    ),
                  ),
                ],
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
        primaryLabel: _primaryLabel(async.valueOrNull?.status),
        onPrimaryTap: _isActionable(async.valueOrNull?.status)
            ? () async {
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
            ref.invalidate(contractorHomeProvider);
            if (context.mounted) context.go('/contractor/inprogress/${ticket.id}');
            return;
          }
          if (ticket.status == 'in_progress') {
            if (context.mounted) context.push('/contractor/camera/${ticket.id}');
            return;
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This work order is closed or awaiting review.'),
              ),
            );
          }
        }
            : null,
      ),
    );
  }

  String _primaryLabel(String? status) {
    switch (status) {
      case 'assigned':
        return 'Start Work - Mark In Progress';
      case 'in_progress':
        return 'Upload After Photo & Submit for Audit';
      case 'audit_pending':
        return 'Proof Submitted — Awaiting Verification';
      case 'resolved':
      case 'rejected':
        return 'Work Order Closed';
      default:
        return 'Action unavailable';
    }
  }

  bool _isActionable(String? status) {
    return status == 'assigned' || status == 'in_progress';
  }

  Widget _meta(BuildContext context, String label, String value) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppDesign.mono(
            tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _openMaps(Ticket ticket) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${ticket.latitude},${ticket.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callAssignedJe({
    required BuildContext context,
    required WidgetRef ref,
    required String? assignedJeId,
    required String? fallbackJeName,
  }) async {
    if (assignedJeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned JE not available for this ticket.')),
      );
      return;
    }
    final row = await ref
        .read(supabaseClientProvider)
        .from('profiles')
        .select('phone')
        .eq('id', assignedJeId)
        .maybeSingle();
    if (!context.mounted) return;
    final phone = row?['phone']?.toString().trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone not available for ${fallbackJeName ?? 'JE'}.')),
      );
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    await launchUrl(uri);
  }
}
