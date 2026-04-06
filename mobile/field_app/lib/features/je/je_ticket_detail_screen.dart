import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/status_badge.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class JeTicketDetailScreen extends ConsumerWidget {
  const JeTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTicket = ref.watch(ticketDetailProvider(ticketId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket detail')),
      body: asyncTicket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Not found'));
          }
          final lookupAsync = ref.watch(ticketLookupProvider(ticket));
          final evidence = <String>[
            ...ticket.photoBefore,
            if (ticket.photoJeInspection != null && ticket.photoJeInspection!.isNotEmpty)
              ticket.photoJeInspection!,
          ];

          return ListView(
            padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketRef.isEmpty ? 'New ticket' : ticket.ticketRef,
                            style: tt.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (ticket.severityTier != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Severity: ${ticket.severityTier}',
                              style: tt.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(status: ticket.status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Evidence',
                style: tt.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (evidence.isEmpty)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 34,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No photo evidence available',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: evidence.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final url = evidence[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          width: 320,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: cs.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Center(
                                child: Text(
                                  'Photo unavailable',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              if (ticket.citizenName != null || ticket.citizenPhone != null)
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${ticket.citizenName ?? ''} ${ticket.citizenPhone ?? ''}'.trim(),
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (ticket.addressText != null || ticket.nearestLandmark != null)
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.addressText != null)
                        Text(
                          ticket.addressText!,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      if (ticket.nearestLandmark != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Landmark: ${ticket.nearestLandmark}',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              lookupAsync.when(
                data: (lookup) => Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Meta(label: 'Zone', value: lookup.zoneName ?? '-'),
                      ),
                      Expanded(
                        child: _Meta(label: 'Prabhag', value: lookup.prabhagName ?? '-'),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              GradientPrimaryButton(
                onPressed: () => context.push('/je/tickets/${ticket.id}/checkin'),
                label: 'Site check-in',
                icon: Icons.pin_drop_outlined,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/je/tickets/${ticket.id}/measure'),
                      icon: const Icon(Icons.straighten_rounded),
                      label: const Text('Measure'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/je/tickets/${ticket.id}/assign'),
                      icon: const Icon(Icons.group_work_outlined),
                      label: const Text('Assign'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final rows = await ref.read(supabaseClientProvider).from('departments').select('id, name').eq('is_active', true);
                  if (!context.mounted) return;
                  final selected = await showModalBottomSheet<int>(
                    context: context,
                    builder: (ctx) => ListView(
                      children: (rows as List<dynamic>)
                          .map((e) => ListTile(
                                title: Text((e as Map)['name'] as String? ?? 'Department'),
                                onTap: () => Navigator.of(ctx).pop((e)['id'] as int),
                              ))
                          .toList(),
                    ),
                  );
                  if (selected == null) return;
                  await ref.read(supabaseClientProvider).from('tickets').update({'department_id': selected}).eq('id', ticket.id);
                  ref.invalidate(ticketDetailProvider(ticket.id));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Department updated')),
                    );
                  }
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Change Department'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final reasonCtrl = TextEditingController();
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reject complaint'),
                      content: TextField(
                        controller: reasonCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter rejection reason',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted || reason == null || reason.isEmpty) return;
                  await ref.read(ticketServiceProvider).rejectTicket(
                        ticketId: ticket.id,
                        reason: reason,
                      );
                  await ref.read(ticketEventServiceProvider).insertEvent(
                        ticketId: ticket.id,
                        actorRole: 'je',
                        eventType: 'status_change',
                        oldStatus: ticket.status,
                        newStatus: 'rejected',
                        notes: reason,
                      );
                  ref.invalidate(ticketDetailProvider(ticket.id));
                  ref.invalidate(jeInboxProvider);
                  ref.invalidate(jeZoneAllTicketsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint rejected')),
                    );
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Reject complaint'),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: 'Begin Site Check-In',
        onPrimaryTap: () => context.push('/je/tickets/$ticketId/checkin'),
        secondaryLabel: 'Reject complaint',
        onSecondaryTap: () async {
          final reasonCtrl = TextEditingController();
          final reason = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reject complaint'),
              content: TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Enter rejection reason'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
                  child: const Text('Reject'),
                ),
              ],
            ),
          );
          if (reason == null || reason.isEmpty) return;
          await ref.read(ticketServiceProvider).rejectTicket(
                ticketId: ticketId,
                reason: reason,
              );
          await ref.read(ticketEventServiceProvider).insertEvent(
                ticketId: ticketId,
                actorRole: 'je',
                eventType: 'status_change',
                oldStatus: 'open',
                newStatus: 'rejected',
                notes: reason,
              );
          ref.invalidate(ticketDetailProvider(ticketId));
          ref.invalidate(jeInboxProvider);
        },
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: tt.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
