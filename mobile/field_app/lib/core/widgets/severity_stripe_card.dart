import 'package:flutter/material.dart';

import '../theme/theme.dart';

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
    final stripe = AppDesign.severityColor(cs, severity);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesign.cardShadow(cs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
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
