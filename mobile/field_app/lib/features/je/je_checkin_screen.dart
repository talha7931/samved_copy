import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/gradient_primary_button.dart';
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

  static const double _maxM = 20;

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
      if (!mounted) return;
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(jeInboxProvider);
      context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Site check-in')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You must be within $_maxM m of the reported location.',
                      style: tt.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
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
            const Spacer(),
            GradientPrimaryButton(
              onPressed: _busy ? null : _checkIn,
              label: 'Confirm check-in',
              icon: Icons.verified_rounded,
              loading: _busy,
            ),
          ],
        ),
      ),
    );
  }
}
