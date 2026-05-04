import 'dart:math';
import 'package:flutter/material.dart';

/// Animated SVG-style progress ring matching the Colectio wireframe design.
class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? color2; // gradient end color
  final Color bgColor;
  final Widget? center;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 9,
    required this.color,
    this.color2,
    this.bgColor = const Color(0x1A000000),
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final effectiveColor2 = color2 ?? color;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              value: clamped,
              strokeWidth: strokeWidth,
              color: color,
              color2: effectiveColor2,
              bgColor: bgColor,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color color;
  final Color color2;
  final Color bgColor;

  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.color2,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final sweepAngle = 2 * pi * value;
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Gradient along the arc
    if (color != color2) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      fgPaint.shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi,
        colors: [color, color2],
      ).createShader(rect);
    } else {
      fgPaint.color = color;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start from top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      value != oldDelegate.value ||
      color != oldDelegate.color ||
      color2 != oldDelegate.color2;
}
