import 'package:flutter/material.dart';

/// Карточка команды с рамкой под GIF и отображением очков.
class TeamPanel extends StatelessWidget {
  const TeamPanel({
    super.key,
    required this.name,
    required this.score,
    required this.onGifTap,
    this.gifAssetPath,
    this.isActive = false,
  });

  final String name;
  final int score;
  final VoidCallback onGifTap;
  final String? gifAssetPath;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isActive ? Colors.amberAccent : Colors.white24;
    final List<BoxShadow> shadows = isActive
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ];

    return Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
        color: Colors.black.withOpacity(0.55),
        boxShadow: shadows,
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onGifTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: gifAssetPath == null
                    ? Center(
                        child: Text(
                          'GIF',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Image.asset(
                        gifAssetPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                          return Center(
                            child: Text(
                              'Нет GIF',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.stars,
                      color: isActive ? Colors.amberAccent : Colors.white60,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Очки: $score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
