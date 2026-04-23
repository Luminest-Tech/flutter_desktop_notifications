import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Journal / ledger aesthetic. Parchment background, caramel ink sparkline
/// that feels hand-drawn, sage trend chip.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  static const _series = [
    0.35, 0.38, 0.42, 0.40, 0.48, 0.55, 0.52,
    0.58, 0.63, 0.61, 0.68, 0.72, 0.78, 0.82,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF5E8), Color(0xFFEFE2C8)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ACTIVE READERS · TODAY',
                style: TextStyle(
                  color: Color(0xFF8A7863),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A6B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 11, color: Color(0xFF5A6E3F)),
                    SizedBox(width: 2),
                    Text(
                      '12.4%',
                      style: TextStyle(
                        color: Color(0xFF5A6E3F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '24,817',
            style: TextStyle(
              fontFamily: 'Georgia',
              color: Color(0xFF2B2019),
              fontSize: 40,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'vs 22,078 yesterday',
            style: TextStyle(
              color: Color(0xFFA89479),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: CustomPaint(
              painter: _SparklinePainter(_series),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values);
  final List<double> values;

  static const _ink = Color(0xFFB8764C);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final dx = size.width / (values.length - 1);
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).clamp(1e-6, double.infinity);
    Offset point(int i) => Offset(
          i * dx,
          size.height - ((values[i] - min) / range) * size.height,
        );

    final linePath = Path()..moveTo(0, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      linePath.lineTo(point(i).dx, point(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _ink.withValues(alpha: 0.28),
            _ink.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = _ink
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Last-point dot with cream halo.
    final last = point(values.length - 1);
    canvas.drawCircle(
      last,
      5,
      Paint()..color = const Color(0xFFFBF5E8),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}
