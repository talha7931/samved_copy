import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/profile_app_bar.dart';
import '../../core/constants/status_labels.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/ticket.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class ContractorHomeScreen extends ConsumerWidget {
  const ContractorHomeScreen({
    super.key,
    this.initialBillsOnly = false,
    this.initialProfileOnly = false,
  });

  final bool initialBillsOnly;
  final bool initialProfileOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractorInboxProvider);
    final profileAsync = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ProfileAppBar(
        greeting: 'My work orders',
        name: profileAsync.value?.fullName ?? 'Contractor',
        subtitle: 'Private contractor',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tickets) {
          if (initialBillsOnly) {
            return const EmptyState(
              title: 'Bills view',
              subtitle: 'Billing list will be enabled in the next backend-integrated phase.',
              icon: Icons.receipt_long_outlined,
            );
          }
          if (initialProfileOnly) {
            return const EmptyState(
              title: 'Contractor profile',
              subtitle: 'Company and profile settings will be available here.',
              icon: Icons.person_outline_rounded,
            );
          }
          if (tickets.isEmpty) {
            return const EmptyState(
              title: 'No contractor assignments',
              subtitle: 'JE will assign private jobs to you when ready.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(contractorInboxProvider),
            child: ListView(
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
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Contractor work orders\n${tickets.length} active jobs',
                          style: tt.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const Icon(Icons.engineering, color: Colors.white, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _statChips(tickets, context),
                const SizedBox(height: 12),
                ...tickets
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Tile(ticket: t),
                        )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statChips(List<Ticket> tickets, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final open = tickets.where((t) => t.status == 'assigned').length;
    final progress = tickets.where((t) => t.status == 'in_progress').length;
    final done = tickets.where((t) => t.status == 'resolved').length;
    Widget chip(String label, int count, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$label: $count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );

    return Wrap(
      spacing: 8,
      children: [
        chip('Open', open, cs.primary),
        chip('In Progress', progress, cs.tertiary),
        chip('Done', done, const Color(0xFF16A34A)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final rate = ticket.ratePerUnit;
    final cost = ticket.estimatedCost;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/contractor/jobs/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketRef.isEmpty ? 'Job' : ticket.ticketRef,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 6),
              if (ticket.jobOrderRef != null)
                Text('JO: ${ticket.jobOrderRef}', style: tt.bodyMedium),
              if (rate != null)
                Text(
                  'Locked rate: ₹${rate.toStringAsFixed(2)} / unit',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              if (cost != null)
                Text(
                  'Payable (estimate): ₹${cost.toStringAsFixed(2)}',
                  style: tt.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                ticketStatusLabelForRole(ticket.status, 'contractor'),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
