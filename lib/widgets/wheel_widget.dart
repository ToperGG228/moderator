import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../models.dart';

class WheelWidget extends StatelessWidget {
  const WheelWidget({
    super.key,
    required this.sectors,
    required this.stream,
    required this.size,
    required this.isSpinning,
    required this.onAnimationEnd,
  });

  final List<WheelSector> sectors;
  final Stream<int> stream;
  final double size;
  final bool isSpinning;
  final VoidCallback onAnimationEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 6),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 24),
                ],
              ),
              child: ClipOval(
                child: FortuneWheel(
                  selected: stream,
                  onAnimationEnd: onAnimationEnd,
                  animateFirst: false,
                  indicators: const [
                    FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: TriangleIndicator(color: Colors.amber, width: 32, height: 24),
                    ),
                  ],
                  items: sectors
                      .map(
                        (sector) => FortuneItem(
                          child: Text(
                            sector.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: FortuneItemStyle(
                            color: sector.color,
                            borderColor: Colors.white24,
                            borderWidth: 1,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (isSpinning)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Вращаем...',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
