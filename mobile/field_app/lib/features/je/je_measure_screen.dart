import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/gradient_primary_button.dart';
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
  RateCard? _card;
  List<RateCard> _cards = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
    if (c == null) {
      setState(() => _error = 'Select a work type / rate card.');
      return;
    }
    final l = double.tryParse(_len.text);
    final w = double.tryParse(_wid.text);
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
              depthM: 0,
              areaSqm: area,
            ),
            workType: c.workType,
            rateCardId: c.id,
            ratePerUnit: c.ratePerUnit,
            estimatedCost: cost,
          );
      if (!mounted) return;
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(jeInboxProvider);
      context.pop();
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Measure & estimate')),
      body: ListView(
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
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 24),
          GradientPrimaryButton(
            onPressed: _saving ? null : _save,
            label: 'Save estimate',
            icon: Icons.save_outlined,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
