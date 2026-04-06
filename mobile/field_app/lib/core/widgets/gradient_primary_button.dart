import 'package:flutter/material.dart';

/// Primary → primary-container gradient pill (Stitch CTA).
class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled || loading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: disabled
                    ? [
                        cs.primary.withValues(alpha: 0.4),
                        cs.primaryContainer.withValues(alpha: 0.4),
                      ]
                    : [cs.primary, cs.primaryContainer],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 22),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
