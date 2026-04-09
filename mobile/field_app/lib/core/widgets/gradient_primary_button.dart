import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Primary → primary-container gradient pill (Stitch CTA).
class GradientPrimaryButton extends StatefulWidget {
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
  State<GradientPrimaryButton> createState() => _GradientPrimaryButtonState();
}

class _GradientPrimaryButtonState extends State<GradientPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: disabled || widget.loading ? null : widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: disabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withValues(alpha: 0.4),
                          cs.primaryContainer.withValues(alpha: 0.4),
                        ],
                      )
                    : AppDesign.navyGradient,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.loading)
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
                        widget.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(widget.icon, color: Colors.white, size: 22),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
