import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/sticky_bottom_cta.dart';
import '../../core/widgets/ticket_summary_card.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';
import '../../services/ticket_service.dart';

enum _ExecutorKind { gang, contractor }

class JeAssignScreen extends ConsumerStatefulWidget {
  const JeAssignScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<JeAssignScreen> createState() => _JeAssignScreenState();
}

class _JeAssignScreenState extends ConsumerState<JeAssignScreen> {
  _ExecutorKind _kind = _ExecutorKind.gang;
  List<MukadamOption> _mukadams = [];
  List<ContractorOption> _contractors = [];
  String? _mukadamId;
  String? _contractorId;
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
    final z = profile?.zoneId;
    if (z == null) {
      setState(() => _loading = false);
      return;
    }
    final ts = ref.read(ticketServiceProvider);
    final m = await ts.listMukadamsInZone(z);
    final c = await ts.listContractorsInZone(z);
    if (mounted) {
      setState(() {
        _mukadams = m;
        _contractors = c;
        _loading = false;
      });
    }
  }

  bool get _canSubmit {
    if (_kind == _ExecutorKind.gang) return _mukadamId != null;
    return _contractorId != null;
  }

  Future<void> _submit() async {
    final ticket =
        await ref.read(ticketServiceProvider).fetchTicket(widget.ticketId);
    if (ticket == null) return;
    if (ticket.status != 'verified') {
      setState(() {
        _error = 'Executor assignment is only allowed after verification.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(ticketServiceProvider).assignExecutor(
            ticketId: widget.ticketId,
            ticketRef: ticket.ticketRef.isEmpty
                ? 'T-${widget.ticketId.substring(0, 8)}'
                : ticket.ticketRef,
            assignedMukadam: _kind == _ExecutorKind.gang ? _mukadamId : null,
            assignedContractor:
                _kind == _ExecutorKind.contractor ? _contractorId : null,
          );
      await ref.read(ticketEventServiceProvider).insertEvent(
            ticketId: widget.ticketId,
            actorRole: 'je',
            eventType: 'assignment',
            oldStatus: ticket.status,
            newStatus: 'assigned',
            notes: _kind == _ExecutorKind.gang
                ? 'Assigned to department gang'
                : 'Assigned to private contractor',
          );
      if (!mounted) return;
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(jeInboxProvider);
      ref.invalidate(jeZoneAllTicketsProvider);
      context.go('/je/tasks');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Executor assigned')),
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
      appBar: AppBar(title: const Text('Assign executor')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          FutureBuilder(
            future: ref.read(ticketServiceProvider).fetchTicket(widget.ticketId),
            builder: (context, snapshot) {
              final ticket = snapshot.data;
              if (ticket == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TicketSummaryCard(ticket: ticket),
              );
            },
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
              'Choose exactly one executor type. Department work gang uses Mukadam, private work uses contractor.',
              style: tt.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  context,
                  label: 'Department gang',
                  subtitle: 'Assign to Mukadam',
                  icon: Icons.groups_outlined,
                  selected: _kind == _ExecutorKind.gang,
                  onTap: () => setState(() {
                    _kind = _ExecutorKind.gang;
                    _mukadamId = null;
                    _contractorId = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeCard(
                  context,
                  label: 'Private contractor',
                  subtitle: 'Empanelled vendor',
                  icon: Icons.engineering_outlined,
                  selected: _kind == _ExecutorKind.contractor,
                  onTap: () => setState(() {
                    _kind = _ExecutorKind.contractor;
                    _mukadamId = null;
                    _contractorId = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_kind == _ExecutorKind.gang) ...[
            if (_mukadams.isEmpty)
              const Text('No active Mukadam profiles in your zone.')
            else
              ..._mukadams.map(
                (m) => _pickTile(
                  context,
                  selected: _mukadamId == m.id,
                  title: m.fullName,
                  subtitle: 'Department work gang',
                  onTap: () => setState(() => _mukadamId = m.id),
                ),
              ),
          ] else ...[
            if (_contractors.isEmpty)
              const Text('No contractors linked to your zone in the contractors table.')
            else
              ..._contractors.map(
                (c) => _pickTile(
                  context,
                  selected: _contractorId == c.id,
                  title: c.companyName,
                  subtitle: 'Private contractor',
                  onTap: () => setState(() => _contractorId = c.id),
                ),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOB ORDER PREVIEW',
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JO-${widget.ticketId.substring(0, 8)}',
                  style: tt.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  _kind == _ExecutorKind.gang
                      ? 'Executor: ${_selectedMukadamName()}'
                      : 'Executor: ${_selectedContractorName()}',
                  style: tt.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              'Once assigned, executor cannot be changed without Executive Engineer approval.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: 'Generate Job Order & Assign',
        onPrimaryTap: (_canSubmit && !_saving) ? _submit : null,
      ),
    );
  }

  Widget _modeCard(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.22) : cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickTile(
    BuildContext context, {
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? cs.primaryContainer.withValues(alpha: 0.12) : cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedMukadamName() {
    for (final m in _mukadams) {
      if (m.id == _mukadamId) return m.fullName;
    }
    return '-';
  }

  String _selectedContractorName() {
    for (final c in _contractors) {
      if (c.id == _contractorId) return c.companyName;
    }
    return '-';
  }
}
