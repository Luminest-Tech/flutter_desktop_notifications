import 'package:flutter/material.dart';

/// Vinyl / warm walnut aesthetic. Dark wood background, copper album tile with
/// concentric-ring highlights, gold accents.
class MusicCard extends StatelessWidget {
  const MusicCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1E14), Color(0xFF3D2E1F)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _RecordAlbum(),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'NOW SPINNING',
                  style: TextStyle(
                    color: Color(0xFFD9A77A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Harvest Moon',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFFF5E6CF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Neil Young · Harvest Moon",
                  style: TextStyle(
                    color: const Color(0xFFF5E6CF).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.42,
                    minHeight: 2,
                    backgroundColor:
                        const Color(0xFFD9A77A).withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFD9A77A)),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1:42',
                      style: TextStyle(
                        color:
                            const Color(0xFFF5E6CF).withValues(alpha: 0.55),
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '-3:18',
                      style: TextStyle(
                        color:
                            const Color(0xFFF5E6CF).withValues(alpha: 0.55),
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordAlbum extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8764C), Color(0xFF8B5A3C), Color(0xFF5A3A24)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle concentric rings like a vinyl record
          ...List.generate(3, (i) {
            final size = 48.0 + i * 20;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF5E6CF).withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            );
          }),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD9A77A),
            ),
            child: const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF2A1E14),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
