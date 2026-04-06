import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/radial_gauge.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../core/widgets/ticket_summary_card.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class JeCheckInScreen extends ConsumerStatefulWidget {
  const JeCheckInScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<JeCheckInScreen> createState() => _JeCheckInScreenState();
}

class _JeCheckInScreenState extends ConsumerState<JeCheckInScreen> {
  bool _busy = false;
  String? _error;
  double? _distanceM;
  (double lat, double lng)? _ticketPoint;
  (double lat, double lng)? _myPoint;
  Timer? _gpsTimer;

  static const double _maxM = AppConstants.geofenceRadiusM;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _busy) return;
      final ticket = await ref.read(ticketServiceProvider).fetchTicket(widget.ticketId);
      if (ticket == null) return;
      final loc = ref.read(locationServiceProvider);
      final ok = await loc.ensureLocationPermission();
      if (!ok) return;
      final pos = await loc.currentPosition();
      if (pos == null) return;
      final d = loc.distanceMeters(
        ticketLat: ticket.latitude,
        ticketLng: ticket.longitude,
        hereLat: pos.latitude,
        hereLng: pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        _ticketPoint = (ticket.latitude, ticket.longitude);
        _myPoint = (pos.latitude, pos.longitude);
        _distanceM = d;
      });
    });
  }

  Future<void> _checkIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ticket = await ref.read(ticketServiceProvider).fetchTicket(widget.ticketId);
    if (ticket == null) {
      setState(() => _busy = false);
      return;
    }
    final loc = ref.read(locationServiceProvider);
    final ok = await loc.ensureLocationPermission();
    if (!ok) {
      setState(() {
        _error = 'Location permission is required for check-in.';
        _busy = false;
      });
      return;
    }
    final pos = await loc.currentPosition();
    if (pos == null) {
      setState(() {
        _error = 'Could not read GPS. Try again outdoors.';
        _busy = false;
      });
      return;
    }
    final d = loc.distanceMeters(
      ticketLat: ticket.latitude,
      ticketLng: ticket.longitude,
      hereLat: pos.latitude,
      hereLng: pos.longitude,
    );
    setState(() {
      _ticketPoint = (ticket.latitude, ticket.longitude);
      _myPoint = (pos.latitude, pos.longitude);
      _distanceM = d;
    });
    if (d > _maxM) {
      setState(() {
        _error =
            'You are about ${d.toStringAsFixed(0)} m from the reported point. Move within $_maxM m to check in.';
        _busy = false;
      });
      return;
    }
    try {
      await ref.read(ticketServiceProvider).updateJeCheckIn(
            ticketId: widget.ticketId,
            lat: pos.latitude,
            lng: pos.longitude,
            distanceM: d,
          );
      await ref.read(ticketEventServiceProvider).insertEvent(
            ticketId: widget.ticketId,
            actorRole: 'je',
            eventType: 'je_checkin',
            oldStatus: ticket.status,
            newStatus: 'verified',
            notes: 'JE checked in at site. Distance: ${d.toStringAsFixed(1)}m',
            metadata: {
              'checkin_lat': pos.latitude,
              'checkin_lng': pos.longitude,
              'distance_m': d,
            },
          );
      if (!mounted) return;
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(jeInboxProvider);
      context.go('/je/tickets/${widget.ticketId}/measure');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in recorded')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    return Scaffold(
      appBar: AppBar(title: const Text('Site check-in')),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TicketSummaryCard(ticket: ticket),
                const SizedBox(height: 20),
                RadialGauge(
                  value: (_distanceM ?? _maxM).clamp(0, _maxM),
                  max: _maxM,
                  centerText: _distanceM == null ? '-- m' : '${_distanceM!.toStringAsFixed(0)} m',
                  subText: 'of ${_maxM.toStringAsFixed(0)} m threshold',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: (_distanceM ?? (_maxM + 1)) <= _maxM
                        ? const Color(0xFF22C55E)
                        : cs.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Text(
                    (_distanceM ?? (_maxM + 1)) <= _maxM
                        ? 'Within range - ready to verify'
                        : 'Out of range - move closer',
                    style: tt.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                if (_ticketPoint != null && _myPoint != null)
                  Row(
                    children: [
                      Expanded(
                        child: _gpsCard(
                          context,
                          'Reported spot GPS',
                          '${_ticketPoint!.$1.toStringAsFixed(4)}, ${_ticketPoint!.$2.toStringAsFixed(4)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _gpsCard(
                          context,
                          'Your location GPS',
                          '${_myPoint!.$1.toStringAsFixed(4)}, ${_myPoint!.$2.toStringAsFixed(4)}',
                        ),
                      ),
                    ],
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: 'Verify site',
        onPrimaryTap: (_busy || ((_distanceM ?? (_maxM + 1)) > _maxM)) ? null : _checkIn,
        secondaryLabel: 'GPS check-in is recorded with timestamp',
      ),
    );
  }

  Widget _gpsCard(BuildContext context, String title, String value) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: tt.labelSmall),
          const SizedBox(height: 8),
          Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
