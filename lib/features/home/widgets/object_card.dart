import 'package:flutter/material.dart';

/// Mini tilted card widget matching the Colectio hi-fi wireframe's
/// floating item cards around the progress ring.
class ObjectCard extends StatelessWidget {
  final Color color;
  final String? label;
  final double? width;
  final double? height;
  final double tilt;
  final String? size;

  static const _sizes = <String, _CardSize>{
    'sm': _CardSize(44, 56),
    'md': _CardSize(60, 76),
    'lg': _CardSize(80, 100),
  };

  const ObjectCard({
    super.key,
    required this.color,
    this.label,
    this.width,
    this.height,
    this.tilt = 0,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dims = _sizes[size] ?? _CardSize(width ?? 44, height ?? 56);
    return Transform.rotate(
      angle: tilt * (3.14159 / 180),
      child: Container(
        width: dims.w,
        height: dims.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.87)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              height: dims.h * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (label != null)
              Positioned(
                bottom: 5,
                left: 5,
                right: 5,
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardSize {
  final double w;
  final double h;
  const _CardSize(this.w, this.h);
}
