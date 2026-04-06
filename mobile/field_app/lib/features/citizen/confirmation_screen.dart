import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmationArgs {
  const ConfirmationArgs({
    required this.ticketId,
    this.ticketRef,
    this.zoneId,
    this.prabhagId,
    this.severity,
    this.epdoScore,
    this.slaHours,
  });

  final String ticketId;
  final String? ticketRef;
  final int? zoneId;
  final int? prabhagId;
  final String? severity;
  final double? epdoScore;
  final int? slaHours;
}

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.args});

  final ConfirmationArgs args;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.primary,
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Submitted Successfully!',
                  textAlign: TextAlign.center,
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  args.ticketRef ?? 'Ticket ${args.ticketId.substring(0, 8)}',
                  textAlign: TextAlign.center,
                  style: tt.titleLarge?.copyWith(
                    color: const Color(0xFFE46500),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zone: ${args.zoneId?.toString() ?? '-'}'),
                      Text('Prabhag: ${args.prabhagId?.toString() ?? '-'}'),
                      Text('Severity: ${args.severity ?? '-'}'),
                      Text('EPDO: ${args.epdoScore?.toStringAsFixed(2) ?? '-'}'),
                      Text('Expected response: ${args.slaHours ?? '-'}h'),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/citizen/tracker?ticketId=${args.ticketId}'),
                  child: const Text('Track This Complaint'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.go('/citizen/home'),
                  child: const Text('Report Another'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
