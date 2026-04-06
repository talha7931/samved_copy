import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/sticky_bottom_cta.dart';
import '../../core/widgets/ticket_summary_card.dart';
import '../../models/rate_card.dart';
import '../../models/ticket_dimensions.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class JeMeasureScreen extends ConsumerStatefulWidget {
  const JeMeasureScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<JeMeasureScreen> createState() => _JeMeasureScreenState();
}

class _JeMeasureScreenState extends ConsumerState<JeMeasureScreen> {
  final _len = TextEditingController();
  final _wid = TextEditingController();
  final _dep = TextEditingController();
  RateCard? _card;
  List<RateCard> _cards = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _damageCause;

  static const Map<String, String> _causeMap = {
    'Roads': 'poor_construction',
    'Water Supply': 'utility_water',
    'Drainage': 'utility_drainage',
    'MSEDCL': 'utility_electricity',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(profileProvider.future);
    final zoneId = profile?.zoneId;
    final cards =
        await ref.read(rateCardServiceProvider).activeForZone(zoneId);
    if (mounted) {
      setState(() {
        _cards = cards;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _len.dispose();
    _wid.dispose();
    _dep.dispose();
    super.dispose();
  }

  double get _area {
    final l = double.tryParse(_len.text) ?? 0;
    final w = double.tryParse(_wid.text) ?? 0;
    return l * w;
  }

  double? get _cost {
    final c = _card;
    if (c == null) return null;
    if (c.unit == 'sqm') return _area * c.ratePerUnit;
    return _area * c.ratePerUnit;
  }

  Future<void> _save() async {
    final c = _card;
    if (c == null || _damageCause == null) {
      setState(() => _error = 'Select work type and damage cause.');
      return;
    }
    final l = double.tryParse(_len.text);
    final w = double.tryParse(_wid.text);
    final d = double.tryParse(_dep.text) ?? 0;
    if (l == null || w == null || l <= 0 || w <= 0) {
      setState(() => _error = 'Enter valid length and width (metres).');
      return;
    }
    final area = l * w;
    final cost = area * c.ratePerUnit;
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(ticketServiceProvider).updateJeMeasure(
            ticketId: widget.ticketId,
            dimensions: TicketDimensions(
              lengthM: l,
              widthM: w,
              depthM: d,
              areaSqm: area,
            ),
            workType: c.workType,
            damageCause: _damageCause!,
            rateCardId: c.id,
            ratePerUnit: c.ratePerUnit,
            estimatedCost: cost,
          );
      await ref.read(ticketEventServiceProvider).insertEvent(
            ticketId: widget.ticketId,
            actorRole: 'je',
            eventType: 'measurement_recorded',
            oldStatus: 'open',
            newStatus: 'verified',
            notes: 'JE recorded dimensions and estimate',
            metadata: {
              'length_m': l,
              'width_m': w,
              'depth_m': d / 100,
              'area_sqm': area,
              'work_type': c.workType,
              'rate_card_id': c.id,
              'estimated_cost': cost,
              'damage_cause': _damageCause,
            },
          );
      if (!mounted) return;
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(jeInboxProvider);
      context.go('/je/tickets/${widget.ticketId}/assign');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimate saved')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Measure & estimate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          ticketAsync.when(
            data: (ticket) => ticket == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TicketSummaryCard(ticket: ticket),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
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
            child: Text(
              'Capture dimensions and lock estimate using approved rate cards.',
              style: tt.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Pothole dimensions',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('#${widget.ticketId.substring(0, 4)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<RateCard>(
                  decoration: const InputDecoration(labelText: 'Work type (rate card)'),
                  items: _cards
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.workType} (${c.ratePerUnit} / ${c.unit})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _card = v),
                  initialValue: _card,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _len,
                  decoration: const InputDecoration(labelText: 'Length (m)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _wid,
                  decoration: const InputDecoration(labelText: 'Width (m)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dep,
                  decoration: const InputDecoration(labelText: 'Depth (cm)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area: ${_area.toStringAsFixed(2)} sqm',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (_cost != null)
                  Text(
                    'Estimated cost: ₹${_cost!.toStringAsFixed(2)}',
                    style: tt.titleMedium?.copyWith(color: cs.primary),
                  ),
                if (_card != null)
                  Text(
                    '${_area.toStringAsFixed(2)} sqm × ₹${_card!.ratePerUnit.toStringAsFixed(2)} = ₹${_cost?.toStringAsFixed(2) ?? '-'}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _causeMap.entries
                .map(
                  (e) => _CauseChip(
                    label: e.key,
                    selected: _damageCause == e.value,
                    onTap: () => setState(() => _damageCause = e.value),
                  ),
                )
                .toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
        ],
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: 'Approve & Assign Contractor',
        onPrimaryTap: _saving ? null : _save,
      ),
    );
  }
}

class _CauseChip extends StatelessWidget {
  const _CauseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? cs.primary : null,
              ),
        ),
      ),
    );
  }
}
