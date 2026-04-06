import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/ticket_providers.dart';

class ContractorInProgressScreen extends ConsumerStatefulWidget {
  const ContractorInProgressScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<ContractorInProgressScreen> createState() =>
      _ContractorInProgressScreenState();
}

class _ContractorInProgressScreenState
    extends ConsumerState<ContractorInProgressScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final _notes = TextEditingController();
  final List<bool> _checked = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketDetailProvider(widget.ticketId));
    return Scaffold(
      appBar: AppBar(title: const Text('In Progress')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Live timer: ${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Evidence Readiness'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Before photo loaded: READY'),
                      Text('GPS location locked: READY'),
                      Text('Timestamp recording: ACTIVE'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...[
                'Road surface thoroughly cleaned before patching',
                'Hot mix applied at correct depth',
                'Surface compacted with roller or plate',
                'Debris removed and site cleared',
              ].asMap().entries.map((entry) {
                final i = entry.key;
                return CheckboxListTile(
                  title: Text(entry.value),
                  value: _checked[i],
                  onChanged: (v) => setState(() => _checked[i] = v ?? false),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 8),
              Text(
                '₹${ticket.estimatedCost?.toStringAsFixed(2) ?? '-'} at stake — complete on time',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Field notes'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _checked.every((e) => e)
                    ? () => context.push('/contractor/camera/${ticket.id}', extra: _notes.text.trim())
                    : null,
                child: const Text('Submit Proof of Repair'),
              ),
            ],
          );
        },
      ),
    );
  }
}
