import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243B55), Color(0xFF141E30)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'San Francisco',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '64°',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Partly cloudy · H:69° L:55°',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.wb_cloudy_rounded,
                color: Colors.white,
                size: 44,
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Forecast(label: 'Wed', icon: Icons.wb_sunny_rounded, temp: '71°'),
              _Forecast(label: 'Thu', icon: Icons.wb_cloudy_rounded, temp: '65°'),
              _Forecast(
                  label: 'Fri', icon: Icons.cloudy_snowing, temp: '58°'),
              _Forecast(label: 'Sat', icon: Icons.wb_sunny_rounded, temp: '68°'),
              _Forecast(label: 'Sun', icon: Icons.wb_sunny_rounded, temp: '74°'),
            ],
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
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(height: 2),
        Text(
          temp,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
