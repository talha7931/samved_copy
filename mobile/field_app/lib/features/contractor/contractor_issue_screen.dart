import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class ContractorIssueScreen extends ConsumerStatefulWidget {
  const ContractorIssueScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<ContractorIssueScreen> createState() =>
      _ContractorIssueScreenState();
}

class _ContractorIssueScreenState extends ConsumerState<ContractorIssueScreen> {
  String? _issue;
  String _urgency = 'medium';
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(ticketDetailProvider(widget.ticketId)).valueOrNull;
    final issues = const [
      'Access Blocked',
      'Rain/Weather',
      'Material Delay',
      'Site Mismatch',
      'Safety Issue',
      'Contract Dispute',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Flag Issue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issues
                .map(
                  (e) => ChoiceChip(
                    label: Text(e),
                    selected: _issue == e,
                    onSelected: (_) => setState(() => _issue = e),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'low', label: Text('Low')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'critical', label: Text('Critical')),
            ],
            selected: {_urgency},
            onSelectionChanged: (v) => setState(() => _urgency = v.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text('₹${ticket?.estimatedCost?.toStringAsFixed(2) ?? '-'} at risk'),
              subtitle: const Text('This issue will be permanently recorded in the audit trail.'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes (min 10 chars)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_busy || _issue == null || _notes.text.trim().length < 10)
                ? null
                : () async {
                    setState(() => _busy = true);
                    await ref.read(ticketEventServiceProvider).insertEvent(
                          ticketId: widget.ticketId,
                          actorRole: 'contractor',
                          eventType: 'escalation',
                          notes: '${_issue!}: ${_notes.text.trim()}',
                          metadata: {'issue_type': _issue, 'urgency': _urgency},
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue logged successfully')),
                    );
                    context.pop();
                  },
            child: const Text('Submit Issue'),
          ),
        ],
      ),
    );
  }
}
