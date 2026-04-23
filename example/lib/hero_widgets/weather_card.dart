import 'package:flutter/material.dart';

/// Sunrise palette. Warm peach/rose gradient, simple 5-day strip along the
/// bottom.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9D8B3), Color(0xFFE69A6F), Color(0xFFBA5A4A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'San Francisco',
                      style: TextStyle(
                        color: Color(0xFFFBF5E8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '64°',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: Color(0xFFFBF5E8),
                        fontSize: 52,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -3,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Partly cloudy · H 69° · L 55°',
                      style: TextStyle(
                        color: Color(0xFFFBF5E8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFBF5E8).withValues(alpha: 0.22),
                ),
                child: const Icon(
                  Icons.wb_twilight_rounded,
                  color: Color(0xFFFBF5E8),
                  size: 32,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF5E8).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Forecast(label: 'Wed', icon: Icons.wb_sunny_rounded, temp: '71°'),
                _Forecast(label: 'Thu', icon: Icons.cloud_rounded, temp: '65°'),
                _Forecast(label: 'Fri', icon: Icons.grain_rounded, temp: '58°'),
                _Forecast(label: 'Sat', icon: Icons.wb_sunny_rounded, temp: '68°'),
                _Forecast(label: 'Sun', icon: Icons.wb_sunny_rounded, temp: '74°'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({
    required this.label,
    required this.icon,
    required this.temp,
  });
  final String label;
  final IconData icon;
  final String temp;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFBF5E8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Icon(icon, color: const Color(0xFFFBF5E8), size: 16),
        const SizedBox(height: 3),
        Text(
          temp,
          style: const TextStyle(
            color: Color(0xFFFBF5E8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
