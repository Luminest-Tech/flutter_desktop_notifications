import 'package:flutter/material.dart';

/// Aged-paper calendar with a wine-red date stamp. Serif headings, warm
/// ivory surround.
class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7EFDF), Color(0xFFEADFC3)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF5E8),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B2019).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFC9B69A).withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B3A3A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'APR',
                    style: TextStyle(
                      color: Color(0xFFFBF5E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '23',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: Color(0xFF2B2019),
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thursday',
                          style: TextStyle(
                            color: Color(0xFF7A6851),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'IN 15 MINUTES',
                  style: TextStyle(
                    color: Color(0xFF8B3A3A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Design review',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFF2B2019),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _Meta(icon: Icons.access_time_rounded, text: '10:30 — 11:00 AM'),
                const SizedBox(height: 4),
                _Meta(
                    icon: Icons.place_outlined,
                    text: 'Room 2001 · Bldg. 135'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7A6851)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5E4A37),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
