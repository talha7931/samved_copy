import 'package:flutter/material.dart';

import 'gradient_primary_button.dart';

class StickyBottomCta extends StatelessWidget {
  const StickyBottomCta({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradientPrimaryButton(
              label: primaryLabel,
              onPressed: onPrimaryTap,
              icon: Icons.arrow_forward_rounded,
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onSecondaryTap,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
