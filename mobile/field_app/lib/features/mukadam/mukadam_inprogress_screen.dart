import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/ticket_providers.dart';

class MukadamInProgressScreen extends ConsumerStatefulWidget {
  const MukadamInProgressScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<MukadamInProgressScreen> createState() => _MukadamInProgressScreenState();
}

class _MukadamInProgressScreenState extends ConsumerState<MukadamInProgressScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final List<bool> _checked = [false, false, false, false];
  final _notes = TextEditingController();

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
      appBar: AppBar(title: const Text('Gang Deployment')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found'));
          final area = ticket.dimensions?.areaSqm.toStringAsFixed(2) ?? '-';
          final depth = ((ticket.dimensions?.depthM ?? 0) * 100).toStringAsFixed(0);
          final canSubmitProof = ticket.status == 'in_progress';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!canSubmitProof) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Status: ${ticket.status.replaceAll('_', ' ')}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.status == 'audit_pending'
                              ? 'Completion proof is submitted. Waiting for quality audit.'
                              : 'This job is no longer in progress. Proof upload is only available during in progress.',
                        ),
                        if (ticket.status == 'audit_pending' ||
                            ticket.status == 'resolved') ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () =>
                                context.push('/mukadam/camera/${ticket.id}'),
                            child: const Text('View completion proof'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Live timer: ${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}'),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.workType ?? 'Road repair', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('Area: $area sqm'),
                      Text('Depth: $depth cm'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Site checklist', style: TextStyle(fontWeight: FontWeight.w800)),
              ...[
                'Base layer cleared and prepared',
                'Repair material applied to surface',
                'Surface compacted and levelled',
                'Site cleaned and debris removed',
              ].asMap().entries.map((entry) {
                final i = entry.key;
                return CheckboxListTile(
                  title: Text(entry.value),
                  value: _checked[i],
                  onChanged: canSubmitProof
                      ? (v) => setState(() => _checked[i] = v ?? false)
                      : null,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 6),
              Text('${_checked.where((e) => e).length} of 4 complete'),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                maxLines: 3,
                enabled: canSubmitProof,
                decoration: const InputDecoration(
                  labelText: 'Field notes (optional)',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: canSubmitProof
                    ? () => context.push('/mukadam/issue/${ticket.id}')
                    : null,
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Flag Blocker'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canSubmitProof && _checked.every((e) => e)
                    ? () => context.push(
                          '/mukadam/camera/${ticket.id}',
                          extra: _notes.text.trim(),
                        )
                    : null,
                child: const Text('Submit Completion Proof'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submitting proof is final. Ensure all repairs are complete.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
