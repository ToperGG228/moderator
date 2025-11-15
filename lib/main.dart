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
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061A40),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFFFFC107),
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Не удалось загрузить вопросы.'),
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
          behavior: SnackBarBehavior.floating,
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
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _resetGame,
            child: const Text('Начать заново'),
          ),
        ],
      );
    }

    final List<String> chars = _engine.answerCharacters;
    final List<bool> revealed = _engine.revealedLetters;

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            question.question,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(chars.length, (int index) {
            final String char = chars[index];
            if (char == ' ') {
              return const SizedBox(width: 28, height: 64);
            }
            final bool isRevealed = revealed[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isRevealed ? const Color(0xFF1E88E5) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white54, width: 2),
                boxShadow: isRevealed
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Colors.lightBlueAccent.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Text(
                isRevealed ? char : '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWheelSection() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              WheelWidget(
                key: _wheelKey,
                sectors: _sectors,
                initialIndex: _initialWheelIndex,
                onSpinComplete: _onSectorComplete,
                size: 280,
              ),
              Positioned(
                top: 6,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 72,
                  color: Colors.amberAccent.shade200,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (_isSpinning || _engine.isGameFinished) ? null : _handleSpin,
          icon: const Icon(Icons.casino),
          label: const Text(
            'Крутить',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (_lastSector != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Последний сектор: ${_lastSector!.label}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: <Widget>[
              ScoreRow(
                teamNames: _engine.teamNames,
                scores: _engine.scores,
                activeIndex: _engine.activeTeamIndex,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      _buildQuestionBlock(),
                      const SizedBox(height: 32),
                      _buildWheelSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LetterKeyboard(
                letters: _letters,
                disabledLetters: _engine.usedLetters,
                onLetterPressed: _onLetterPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
