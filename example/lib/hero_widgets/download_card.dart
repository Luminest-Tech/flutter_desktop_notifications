import 'package:flutter/material.dart';

class DownloadCard extends StatelessWidget {
  const DownloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5EDDD), Color(0xFFE8DBC0)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B9A6B).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: Color(0xFF5A6E3F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Downloading update',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: Color(0xFF2B2019),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'windows_notification · v2.1.0-x64.msix',
                      style: TextStyle(
                        color: const Color(0xFF7A6851).withValues(alpha: 0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: const [
              _Stat(label: 'DOWNLOADED', value: '504 MB'),
              SizedBox(width: 18),
              _Stat(label: 'OF', value: '1.2 GB'),
              SizedBox(width: 18),
              _Stat(label: 'SPEED', value: '14.2 MB/s'),
              Spacer(),
              _Stat(label: 'REMAINING', value: '1m 12s', align: TextAlign.right),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  color: const Color(0xFFC9B69A).withValues(alpha: 0.4),
                ),
                FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Container(
                    height: 7,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B9A6B), Color(0xFFB8764C)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.align = TextAlign.left,
  });
  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA89479),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2B2019),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
