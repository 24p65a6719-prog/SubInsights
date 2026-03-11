import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular progress widget showing dwell countdown.
class DwellTimerWidget extends StatelessWidget {
  final Duration elapsed;
  final Duration threshold;
  final double size;
  final bool triggered;

  const DwellTimerWidget({
    super.key,
    required this.elapsed,
    required this.threshold,
    this.size = 56,
    this.triggered = false,
  });

  double get _progress =>
      (elapsed.inSeconds / threshold.inSeconds).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final remaining = threshold - elapsed;
    final label = triggered
        ? '!'
        : remaining.inSeconds > 60
            ? '${remaining.inMinutes}m'
            : '${remaining.inSeconds}s';
    final color =
        triggered ? AppColors.success : Color.lerp(AppColors.warning, AppColors.success, _progress)!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: _progress,
              color: color,
              bgColor: Colors.grey.shade200,
              strokeWidth: 4,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
