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
      child: Row(
        children: [
          GestureDetector(
            onTap: onGifTap,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xAA1E1E2C), Color(0x552A2A40)],
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: team.gifAsset == null
                  ? Center(
                      child: Text(
                        'GIF',
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: isActive ? Colors.amberAccent : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Очки',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
