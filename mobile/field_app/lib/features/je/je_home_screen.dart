import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/profile_app_bar.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/ticket.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class JeHomeScreen extends ConsumerStatefulWidget {
  const JeHomeScreen({
    super.key,
    this.initialMapOnly = false,
    this.initialRoutesOnly = false,
    this.initialProfileOnly = false,
  });

  final bool initialMapOnly;
  final bool initialRoutesOnly;
  final bool initialProfileOnly;

  @override
  ConsumerState<JeHomeScreen> createState() => _JeHomeScreenState();
}

class _JeHomeScreenState extends ConsumerState<JeHomeScreen> {
  String _statusFilter = 'all';
  bool _mapFirst = true;
  (double lat, double lng)? _myPoint;

  @override
  void initState() {
    super.initState();
    _resolveCurrentPoint();
  }

  Future<void> _resolveCurrentPoint() async {
    final loc = ref.read(locationServiceProvider);
    final ok = await loc.ensureLocationPermission();
    if (!ok) return;
    final pos = await loc.currentPosition();
    if (pos == null || !mounted) return;
    setState(() => _myPoint = (pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(jeInboxProvider);
    final allAsync = ref.watch(jeZoneAllTicketsProvider);
    final profileAsync = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ProfileAppBar(
        greeting: 'Zone tasks',
        name: profileAsync.value?.fullName ?? 'JE',
        subtitle: profileAsync.value?.zoneId != null
            ? 'Zone ${profileAsync.value!.zoneId}'
            : null,
        actions: [
          IconButton(
            icon: Icon(_mapFirst ? Icons.list_alt_rounded : Icons.map_outlined),
            tooltip: _mapFirst ? 'List first' : 'Map first',
            onPressed: () => setState(() => _mapFirst = !_mapFirst),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: activeAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(jeInboxProvider),
        ),
        data: (activeTickets) => allAsync.when(
          loading: () => const ShimmerList(),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(jeZoneAllTicketsProvider),
          ),
          data: (allTickets) {
            if (widget.initialProfileOnly) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  EmptyState(
                    title: 'JE profile',
                    subtitle: 'Profile and settings controls will appear here.',
                    icon: Icons.person_outline_rounded,
                  ),
                ],
              );
            }
            if (widget.initialRoutesOnly) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  EmptyState(
                    title: 'Route planner',
                    subtitle: 'Routing optimization is planned in a backend-integrated pass.',
                    icon: Icons.route_outlined,
                  ),
                ],
              );
            }
            final open = allTickets.where((t) => t.status == 'open').length;
            final verified = allTickets.where((t) => t.status == 'verified').length;
            final assigned = allTickets.where((t) => t.status == 'assigned').length;
            final inProgress = allTickets.where((t) => t.status == 'in_progress').length;
            final qualityCheck =
                allTickets.where((t) => t.status == 'audit_pending').length;
            final resolved = allTickets.where((t) => t.status == 'resolved').length;

            final filtered = _applyFilter(activeTickets, _statusFilter);
            final mapSource = filtered.isNotEmpty ? filtered : activeTickets;
            final recentFallback = allTickets.take(8).toList();
            final showEmpty = activeTickets.isEmpty && recentFallback.isEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(jeInboxProvider);
                ref.invalidate(jeZoneAllTicketsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          AppDesign.primaryNavy,
                          AppDesign.primaryContainerNavy,
                        ],
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
                                '${activeTickets.length} active · $open new',
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
                  _SummaryChips(
                    values: {
                      'Open': open,
                      'Verified': verified,
                      'Assigned': assigned,
                      'In Progress': inProgress,
                      'Quality': qualityCheck,
                      'Resolved': resolved,
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilterRow(
                    selected: _statusFilter,
                    onSelected: (v) => setState(() => _statusFilter = v),
                  ),
                  const SizedBox(height: 14),
                  if (widget.initialMapOnly || _mapFirst) ...[
                    _MapSection(tickets: mapSource),
                    if (!widget.initialMapOnly) ...[
                      const SizedBox(height: 16),
                      _listSection(
                        context,
                        title: 'Nearby tickets',
                        items: filtered,
                        emptyTitle: 'No tickets in selected filter',
                        emptySubtitle: 'Try switching status chips above.',
                      ),
                    ],
                  ] else ...[
                    _listSection(
                      context,
                      title: 'Nearby tickets',
                      items: filtered,
                      emptyTitle: 'No tickets in selected filter',
                      emptySubtitle: 'Try switching status chips above.',
                    ),
                    const SizedBox(height: 16),
                    _MapSection(tickets: mapSource),
                  ],
                  if (showEmpty) ...[
                    const SizedBox(height: 18),
                    const EmptyState(
                      title: 'No zone tickets yet',
                      subtitle: 'When citizens report in this zone, they appear here automatically.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ] else if (activeTickets.isEmpty && recentFallback.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Recent zone history',
                      style: tt.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recentFallback
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _JeTicketTile(
                                ticket: t,
                                distanceText: _distanceText(t),
                              ),
                        )),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Ticket> _applyFilter(List<Ticket> items, String filter) {
    if (filter == 'all') return items;
    return items.where((t) => t.status == filter).toList();
  }

  String? _distanceText(Ticket ticket) {
    final p = _myPoint;
    if (p == null) return null;
    final d = ref.read(ticketServiceProvider).distanceMeters(
          fromLat: p.$1,
          fromLng: p.$2,
          toLat: ticket.latitude,
          toLng: ticket.longitude,
        );
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} km away';
    return '${d.toStringAsFixed(0)} m away';
  }

  Widget _listSection(
    BuildContext context, {
    required String title,
    required List<Ticket> items,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    final tt = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.filter_alt_off_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...items
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _JeTicketTile(
                    ticket: t,
                    distanceText: _distanceText(t),
                  ),
                )),
      ],
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.values});

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.entries
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppDesign.cardShadow(cs),
              ),
              child: Text(
                '${e.key}: ${e.value}',
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _filters = {
    'all': 'All',
    'open': 'Open',
    'verified': 'Verified',
    'assigned': 'Assigned',
    'in_progress': 'In Progress',
    'audit_pending': 'Quality check',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.entries.map((f) {
          final active = selected == f.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.value),
              selected: active,
              onSelected: (_) => onSelected(f.key),
              selectedColor: cs.primaryContainer.withValues(alpha: 0.2),
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: active ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: cs.surface,
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.tickets});

  final List<Ticket> tickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
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
                color: _severityColor(cs, t.severityTier),
                size: 36,
              ),
            ),
          ),
        )
        .toList();
    final c = LatLng(tickets.first.latitude, tickets.first.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 230,
        child: FlutterMap(
          options: MapOptions(initialCenter: c, initialZoom: 12.5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'road_nirman_field',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  static Color _severityColor(ColorScheme cs, String? severity) {
    switch ((severity ?? '').toUpperCase()) {
      case 'CRITICAL':
        return cs.error;
      case 'HIGH':
        return cs.tertiary;
      case 'MEDIUM':
        return AppDesign.severityColor(cs, 'medium');
      default:
        return cs.primary;
    }
  }
}

class _JeTicketTile extends StatelessWidget {
  const _JeTicketTile({
    required this.ticket,
    this.distanceText,
  });

  final Ticket ticket;
  final String? distanceText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sevColor = _MapSection._severityColor(cs, ticket.severityTier);
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/je/tickets/${ticket.id}'),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                color: sevColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            style: AppDesign.mono(
                              tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.addressText ?? 'Lat/Lng ${ticket.latitude.toStringAsFixed(4)}, ${ticket.longitude.toStringAsFixed(4)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (distanceText != null)
                            Text(
                              distanceText!,
                              style: tt.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (distanceText != null) const SizedBox(height: 6),
                          Row(
                            children: [
                              if (ticket.severityTier != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sevColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    ticket.severityTier!,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: sevColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Flexible(child: StatusBadge(status: ticket.status)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: cs.outline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
