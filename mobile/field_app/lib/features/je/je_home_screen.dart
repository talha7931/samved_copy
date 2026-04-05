import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/ticket.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class JeHomeScreen extends ConsumerWidget {
  const JeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(jeInboxProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Zone tasks'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ]),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyState(
              title: 'No open tickets',
              subtitle: 'New citizen reports in your zone appear here.',
              icon: Icons.inventory_2_outlined,
            );
          }
          final markers = tickets
              .map(
                (t) => Marker(
                  point: LatLng(t.latitude, t.longitude),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => context.push('/je/tickets/${t.id}'),
                    child: Icon(
                      Icons.place,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 36,
                    ),
                  ),
                ),
              )
              .toList();
          final c = LatLng(tickets.first.latitude, tickets.first.longitude);
          final open = tickets.where((t) => t.status == 'open').length;
          final pending = tickets
              .where((t) => !const {'resolved', 'rejected'}.contains(t.status))
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(jeInboxProvider),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JUNIOR ENGINEER',
                              style: tt.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Zone work inbox',
                              style: tt.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$pending active · $open new',
                              style: tt.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.engineering, color: Colors.white, size: 34),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(initialCenter: c, initialZoom: 12),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'road_nirman_field',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Task list',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...tickets
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _JeTicketTile(ticket: t),
                        )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JeTicketTile extends StatelessWidget {
  const _JeTicketTile({required this.ticket});

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
        onTap: () => context.push('/je/tickets/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketRef.isEmpty
                          ? ticket.id.substring(0, 8)
                          : ticket.ticketRef,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    if (ticket.damageType != null)
                      Text(
                        ticket.damageType!.replaceAll('_', ' '),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (ticket.addressText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        ticket.addressText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: ticket.status),
            ],
          ),
        ),
      ),
    );
  }
}
