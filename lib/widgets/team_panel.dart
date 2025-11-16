import 'package:flutter/material.dart';

import '../models.dart';

class TeamPanel extends StatelessWidget {
  const TeamPanel({
    super.key,
    required this.team,
    required this.isActive,
    required this.onGifTap,
  });

  final TeamState team;
  final bool isActive;
  final VoidCallback onGifTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.amberAccent : Colors.white24,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: isActive ? Colors.amberAccent : Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  team.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                team.score.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.amberAccent : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onGifTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                  gradient: const LinearGradient(
                    colors: [Color(0xAA1E1E2C), Color(0x552A2A40)],
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: team.gifAsset == null
                    ? Center(
                        child: Text(
                          'Выбрать GIF',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Image.asset(
                        team.gifAsset!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
