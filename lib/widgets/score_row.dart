import 'package:flutter/material.dart';

/// Виджет с карточками команд и их очками.
class ScoreRow extends StatelessWidget {
  const ScoreRow({
    super.key,
    required this.teamNames,
    required this.scores,
    required this.activeIndex,
  }) : assert(teamNames.length == scores.length);

  final List<String> teamNames;
  final List<int> scores;
  final int activeIndex;

  static const List<Color> _cardColors = <Color>[
    Color(0xFFFFC53D),
    Color(0xFF3A7BFF),
    Color(0xFF24C28C),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(teamNames.length, (int index) {
        final bool isActive = index == activeIndex;
        final Color baseColor = _cardColors[index % _cardColors.length];
        final List<Color> gradientColors = <Color>[
          baseColor.withOpacity(isActive ? 0.95 : 0.75),
          Color.alphaBlend(Colors.black.withOpacity(0.2), baseColor),
        ];
        return Expanded(
          child: AnimatedScale(
            scale: isActive ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white30,
                  width: isActive ? 3 : 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: isActive
                        ? Colors.amberAccent.withOpacity(0.55)
                        : Colors.black.withOpacity(0.35),
                    blurRadius: isActive ? 26 : 12,
                    spreadRadius: isActive ? 3 : 1,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedOpacity(
                        opacity: isActive ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 24,
                        ),
                      ),
                      if (isActive) const SizedBox(width: 6),
                      Text(
                        teamNames[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    scores[index].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
