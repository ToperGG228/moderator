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
    Color(0xFFFBC02D),
    Color(0xFF1976D2),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(teamNames.length, (int index) {
        final bool isActive = index == activeIndex;
        final Color baseColor = _cardColors[index % _cardColors.length];
        final Color background = isActive ? baseColor : baseColor.withOpacity(0.65);
        final BoxShadow shadow = BoxShadow(
          color: isActive ? Colors.yellowAccent.withOpacity(0.6) : Colors.black26,
          blurRadius: isActive ? 16 : 6,
          spreadRadius: isActive ? 2 : 0,
          offset: const Offset(0, 6),
        );
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[shadow],
              border: Border.all(
                color: isActive ? Colors.white : Colors.white24,
                width: isActive ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  teamNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  scores[index].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
