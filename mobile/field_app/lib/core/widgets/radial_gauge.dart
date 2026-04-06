import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadialGauge extends StatelessWidget {
  const RadialGauge({
    super.key,
    required this.value,
    required this.max,
    required this.centerText,
    required this.subText,
  });

  final double value;
  final double max;
  final String centerText;
  final String subText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _GaugePainter(
          ratio: ratio,
          track: cs.surfaceContainerHighest,
          progress: cs.primary,
          innerTrack: cs.outline.withValues(alpha: 0.20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.ratio,
    required this.track,
    required this.progress,
    required this.innerTrack,
  });

  final double ratio;
  final Color track;
  final Color progress;
  final Color innerTrack;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18
      ..color = track;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18
      ..color = progress;

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = innerTrack;

    final rect = Rect.fromCircle(center: center, radius: radius - 18);
    canvas.drawArc(rect, start, sweep, false, trackPaint);
    canvas.drawArc(rect, start, sweep * ratio, false, progressPaint);
    canvas.drawCircle(center, radius - 6, inner);
    canvas.drawCircle(center, radius - 24, inner);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.track != track ||
      oldDelegate.progress != progress ||
      oldDelegate.innerTrack != innerTrack;
}
