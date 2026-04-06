import 'package:flutter/material.dart';

class SeverityStripeCard extends StatelessWidget {
  const SeverityStripeCard({
    super.key,
    required this.severity,
    required this.child,
  });

  final String severity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = severity.toUpperCase();
    final stripe = switch (normalized) {
      'CRITICAL' => cs.error,
      'HIGH' => cs.tertiary,
      'MEDIUM' => const Color(0xFF11B981),
      'LOW' => cs.primary,
      _ => cs.outline,
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 132,
            decoration: BoxDecoration(
              color: stripe,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
