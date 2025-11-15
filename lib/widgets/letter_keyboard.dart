import 'package:flutter/material.dart';

/// Панель с буквами русского алфавита.
class LetterKeyboard extends StatelessWidget {
  const LetterKeyboard({
    super.key,
    required this.letters,
    required this.disabledLetters,
    required this.onLetterPressed,
    this.isEnabled = true,
  });

  final List<String> letters;
  final Set<String> disabledLetters;
  final ValueChanged<String> onLetterPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double tileSize;
        if (maxWidth < 360) {
          tileSize = 36;
        } else if (maxWidth < 520) {
          tileSize = 42;
        } else {
          tileSize = 46;
        }
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: letters.map((String letter) {
            final bool isDisabled = disabledLetters.contains(letter) || !isEnabled;
            return _LetterTile(
              letter: letter,
              disabled: isDisabled,
              size: tileSize,
              onPressed: () => onLetterPressed(letter),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LetterTile extends StatefulWidget {
  const _LetterTile({
    required this.letter,
    required this.disabled,
    required this.onPressed,
    required this.size,
  });

  final String letter;
  final bool disabled;
  final VoidCallback onPressed;
  final double size;

  @override
  State<_LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<_LetterTile> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.disabled) {
      setState(() => _pressed = true);
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled && _pressed) {
      setState(() => _pressed = false);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.disabled) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.disabled;
    final double scale = isDisabled
        ? 1.0
        : _pressed
            ? 0.94
            : 1.0;
    final Color baseColor = isDisabled ? Colors.white12 : const Color(0xFF2B5CF6);
    final List<Color> gradient = <Color>[
      baseColor.withOpacity(isDisabled ? 0.35 : 0.9),
      isDisabled ? Colors.white10 : const Color(0xFF5D8BFF),
    ];
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapCancel: _handleTapCancel,
          onTapUp: _handleTapUp,
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: isDisabled ? Colors.white10 : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: isDisabled
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.letter,
              style: TextStyle(
                fontSize: widget.size * 0.48,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
