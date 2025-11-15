import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'game_logic.dart';
import 'models.dart';
import 'widgets/letter_keyboard.dart';
import 'widgets/score_row.dart';
import 'widgets/wheel_widget.dart';

Future<List<GameQuestion>> loadQuestions() async {
  final String jsonString = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
  return decoded
      .map((dynamic item) => GameQuestion(
            question: item['question'] as String,
            answer: (item['answer'] as String).toUpperCase(),
          ))
      .toList();
}

void main() {
  runApp(const PoleChudesApp());
}

class PoleChudesApp extends StatelessWidget {
  const PoleChudesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Поле чудес',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1D2750),
          contentTextStyle: TextStyle(fontWeight: FontWeight.w600),
          behavior: SnackBarBehavior.floating,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4777FF),
          secondary: Color(0xFFFFC857),
          background: Colors.transparent,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(letterSpacing: 0.4),
        ),
      ),
      home: const GameLoader(),
    );
  }
}

class GameLoader extends StatelessWidget {
  const GameLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GameQuestion>>(
      future: loadQuestions(),
      builder: (BuildContext context, AsyncSnapshot<List<GameQuestion>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: _GameBackground(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: _GameBackground(
              child: Center(
                child: Text('Не удалось загрузить вопросы.'),
              ),
            ),
          );
        }

        return GameScreen(questions: snapshot.data!);
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.questions});

  final List<GameQuestion> questions;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  late List<WheelSector> _sectors;
  late int _initialWheelIndex;
  final GlobalKey<WheelWidgetState> _wheelKey = GlobalKey<WheelWidgetState>();
  final List<String> _letters = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'.split('');

  bool _isSpinning = false;
  bool _finalDialogShown = false;
  WheelSector? _lastSector;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(questions: widget.questions);
    _sectors = buildDefaultSectors();
    _initialWheelIndex = _engine.randomStartIndex(_sectors.length);
  }

  void _handleSpin() {
    if (_isSpinning || _engine.isGameFinished) {
      return;
    }
    setState(() {
      _isSpinning = true;
    });
    _wheelKey.currentState?.spinWheel();
  }

  void _onSectorComplete(WheelSector sector) {
    final String? message = _engine.applySector(sector);
    setState(() {
      _isSpinning = false;
      _lastSector = sector;
    });

    if (sector.type == SectorType.prize || sector.type == SectorType.mystery) {
      _showDialog(sector.label, message ?? 'Особый сектор!');
    } else if (message != null && mounted) {
      _showSnack(message);
    }
  }

  void _onLetterPressed(String letter) {
    if (_engine.isGameFinished) {
      return;
    }

    final int previousQuestion = _engine.currentQuestionNumber;
    final bool found = _engine.guessLetter(letter);
    final bool questionChanged = _engine.currentQuestionNumber != previousQuestion;
    setState(() {
      if (questionChanged) {
        _initialWheelIndex = _engine.randomStartIndex(_sectors.length);
      }
    });

    if (found) {
      _showSnack('Есть такая буква!');
    } else {
      _showSnack('Нет такой буквы. Ход переходит дальше.');
    }

    if (_engine.isGameFinished && !_finalDialogShown) {
      _finalDialogShown = true;
      _showDialog('Игра окончена', 'Все вопросы отгаданы! Сыграем ещё раз?');
    } else if (questionChanged) {
      _showSnack('Слово отгадано! Следующий вопрос.');
    }
  }

  void _resetGame() {
    setState(() {
      _engine.resetGame();
      _initialWheelIndex = _engine.randomStartIndex(_sectors.length);
      _finalDialogShown = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _showDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Продолжить'),
            ),
            if (_engine.isGameFinished)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetGame();
                },
                child: const Text('Сыграть снова'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionBlock() {
    final GameQuestion? question = _engine.currentQuestion;
    if (question == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Игра завершена!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _GradientButton(
            label: 'Начать заново',
            icon: Icons.refresh,
            onPressed: _resetGame,
          ),
        ],
      );
    }

    final List<String> chars = _engine.answerCharacters;
    final List<bool> revealed = _engine.revealedLetters;

    return Column(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<String>(question.question),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.03),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 16,
          children: List<Widget>.generate(chars.length, (int index) {
            final String char = chars[index];
            if (char == ' ') {
              return const SizedBox(width: 32, height: 80);
            }
            final bool isRevealed = revealed[index];
            return _AnswerTile(
              character: char,
              revealed: isRevealed,
              index: index,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWheelSection() {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: WheelWidget(
            key: _wheelKey,
            sectors: _sectors,
            initialIndex: _initialWheelIndex,
            onSpinComplete: _onSectorComplete,
            size: 300,
          ),
        ),
        const SizedBox(height: 20),
        _GradientButton(
          label: _isSpinning ? 'Вращаем...' : 'Крутить',
          icon: Icons.casino,
          onPressed: (_isSpinning || _engine.isGameFinished) ? null : _handleSpin,
        ),
        if (_lastSector != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Последний сектор: ${_lastSector!.label}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScoreRow(
                  teamNames: _engine.teamNames,
                  scores: _engine.scores,
                  activeIndex: _engine.activeTeamIndex,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: <Widget>[
                        _buildQuestionBlock(),
                        const SizedBox(height: 36),
                        _buildWheelSection(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LetterKeyboard(
                  letters: _letters,
                  disabledLetters: _engine.usedLetters,
                  onLetterPressed: _onLetterPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.character,
    required this.revealed,
    required this.index,
  });

  final String character;
  final bool revealed;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      width: 58,
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(revealed ? 0.7 : 0.25)),
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withOpacity(revealed ? 0.18 : 0.06),
            Colors.white.withOpacity(revealed ? 0.05 : 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: revealed
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final Animation<double> curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  );
                  return ScaleTransition(scale: curved, child: child);
                },
                child: revealed
                    ? Text(
                        character,
                        key: ValueKey<String>('revealed-$index'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      )
                    : SizedBox(
                        key: ValueKey<String>('hidden-$index'),
                      ),
              ),
            ),
          ),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.amberAccent.shade200,
                  Colors.orangeAccent.shade200,
                  Colors.deepOrangeAccent.shade100,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.amberAccent.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GameBackground extends StatelessWidget {
  const _GameBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFF050A2B),
            Color(0xFF171045),
            Color(0xFF1D0D48),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            left: -60,
            child: _Spotlight(
              radius: 260,
              colors: <Color>[
                Colors.deepPurpleAccent.withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _Spotlight(
              radius: 300,
              colors: <Color>[
                Colors.blueAccent.withOpacity(0.28),
                Colors.transparent,
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  radius: 1.2,
                  center: const Alignment(0, -0.6),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.radius, required this.colors});

  final double radius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
        ),
      ),
    );
  }
}
