import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/status_badge.dart';
import '../../core/widgets/gradient_primary_button.dart';
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
              if (ticket.status == 'assigned')
                GradientPrimaryButton(
                  onPressed: () async {
                    await ref.read(ticketServiceProvider).startWork(ticket.id);
                    ref.invalidate(ticketDetailProvider(ticketId));
                    ref.invalidate(mukadamInboxProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Work started')),
                      );
                    }
                  },
                  label: 'Start work',
                  icon: Icons.play_arrow_rounded,
                ),
              if (ticket.status == 'in_progress') ...[
                GradientPrimaryButton(
                  onPressed: () =>
                      context.push('/mukadam/jobs/${ticket.id}/proof'),
                  label: 'Submit completion proof',
                  icon: Icons.verified_outlined,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
