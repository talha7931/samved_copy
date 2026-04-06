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

class MukadamHomeScreen extends ConsumerWidget {
  const MukadamHomeScreen({
    super.key,
    this.initialTasksOnly = false,
    this.initialProfileOnly = false,
  });

  final bool initialTasksOnly;
  final bool initialProfileOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mukadamInboxProvider);
    final profileAsync = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ProfileAppBar(
        greeting: 'Department work orders',
        name: profileAsync.value?.fullName ?? 'Mukadam',
        subtitle: profileAsync.value?.zoneId != null
            ? 'Zone ${profileAsync.value!.zoneId}'
            : null,
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
          if (initialProfileOnly) {
            return const EmptyState(
              title: 'Mukadam profile',
              subtitle: 'Profile controls are available in the next iteration.',
              icon: Icons.person_outline_rounded,
            );
          }
          if (tickets.isEmpty) {
            return const EmptyState(
              title: 'No assignments',
              subtitle: 'JE will assign departmental work to you when ready.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(mukadamInboxProvider),
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
                          'Department work orders\n${tickets.length} active jobs',
                          style: tt.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (initialTasksOnly)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: EmptyState(
                      title: 'Tasks tab',
                      subtitle: 'Active tasks from this work-order list are shown below.',
                      icon: Icons.task_alt_outlined,
                    ),
                  ),
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
}

class _Tile extends StatelessWidget {
  const _Tile({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/mukadam/jobs/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.ticketRef.isEmpty ? 'Work order' : ticket.ticketRef,
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          ticket.workType ?? 'Road repair',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ticketStatusLabelForRole(ticket.status, 'mukadam'),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
