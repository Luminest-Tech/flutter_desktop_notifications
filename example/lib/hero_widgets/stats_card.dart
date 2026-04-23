import 'dart:math' as math;

import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  static const _series = [
    0.35, 0.38, 0.42, 0.40, 0.48, 0.55, 0.52, //
    0.58, 0.63, 0.61, 0.68, 0.72, 0.78, 0.82, //
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0D1117)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active users · today',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3F32),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 12, color: Color(0xFF4AE3B5)),
                    SizedBox(width: 2),
                    Text(
                      '12.4%',
                      style: TextStyle(
                        color: Color(0xFF4AE3B5),
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
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'vs 22,078 yesterday',
            style: TextStyle(
              color: Color(0xFF6B7A8F),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
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

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x554AE3B5), Color(0x004AE3B5)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF4AE3B5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final last = point(values.length - 1);
    canvas.drawCircle(last, 3.5, Paint()..color = const Color(0xFF4AE3B5));
    canvas.drawCircle(
      last,
      3.5,
      Paint()
        ..color = const Color(0xFF0D1117)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}
