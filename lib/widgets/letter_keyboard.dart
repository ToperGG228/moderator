import 'package:flutter/material.dart';

/// Панель с буквами русского алфавита.
class LetterKeyboard extends StatelessWidget {
  const LetterKeyboard({
    super.key,
    required this.letters,
    required this.disabledLetters,
    required this.onLetterPressed,
  });

  final List<String> letters;
  final Set<String> disabledLetters;
  final ValueChanged<String> onLetterPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: letters.map((String letter) {
          final bool isDisabled = disabledLetters.contains(letter);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: ElevatedButton(
              onPressed: isDisabled ? null : () => onLetterPressed(letter),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey.shade700 : const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(letter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
