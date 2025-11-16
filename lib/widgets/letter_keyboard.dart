import 'package:flutter/material.dart';

class LetterKeyboard extends StatelessWidget {
  const LetterKeyboard({
    super.key,
    required this.usedLetters,
    required this.onLetterPressed,
  });

  final Set<String> usedLetters;
  final ValueChanged<String> onLetterPressed;

  static const alphabet = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';

  List<List<String>> _buildRows() {
    const rowLength = 8;
    final rows = <List<String>>[];
    for (int i = 0; i < alphabet.length; i += rowLength) {
      rows.add(alphabet.substring(i, (i + rowLength).clamp(0, alphabet.length)).split(''));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final tileSize = (maxWidth - 32) / 8;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: row
                        .map(
                          (letter) => _LetterButton(
                            letter: letter,
                            size: tileSize.clamp(44, 72).toDouble(),
                            isUsed: usedLetters.contains(letter),
                            onTap: usedLetters.contains(letter)
                                ? null
                                : () => onLetterPressed(letter),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _LetterButton extends StatelessWidget {
  const _LetterButton({
    required this.letter,
    required this.size,
    required this.isUsed,
    required this.onTap,
  });

  final String letter;
  final double size;
  final bool isUsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: isUsed ? 0 : 3,
          backgroundColor: isUsed ? Colors.grey.shade700 : Colors.blueGrey.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(
          letter,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
