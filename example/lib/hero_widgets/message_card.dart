import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    this.sender = 'Ada Lovelace',
    this.preview = 'Would love to grab lunch, are you around Thursday?',
    this.timeAgo = 'just now',
  });

  final String sender;
  final String preview;
  final String timeAgo;

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
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Transform.rotate(
              angle: 0.3,
              child: Icon(
                Icons.local_cafe_rounded,
                size: 110,
                color: const Color(0xFF8B5A3C).withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC66A4A), Color(0xFF8B3A2E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF8B3A2E).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  sender.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFFFBF5E8),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Color(0xFF2B2019),
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: Color(0xFFA89479),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5E4A37),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
