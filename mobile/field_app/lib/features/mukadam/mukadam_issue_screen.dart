import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

class MukadamIssueScreen extends ConsumerStatefulWidget {
  const MukadamIssueScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<MukadamIssueScreen> createState() => _MukadamIssueScreenState();
}

class _MukadamIssueScreenState extends ConsumerState<MukadamIssueScreen> {
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
    final issues = const [
      'Access Blocked',
      'Rain/Weather',
      'Material Delay',
      'Site Mismatch',
      'Safety Issue',
      'Other',
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
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (min 10 chars)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_busy || _issue == null || _notes.text.trim().length < 10)
                ? null
                : () async {
                    setState(() => _busy = true);
                    await ref.read(ticketEventServiceProvider).insertEvent(
                          ticketId: widget.ticketId,
                          actorRole: 'mukadam',
                          eventType: 'escalation',
                          notes: '${_issue!}: ${_notes.text.trim()}',
                          metadata: {'issue_type': _issue, 'urgency': _urgency},
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue flagged and sent to JE')),
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
