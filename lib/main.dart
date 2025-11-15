import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'game_logic.dart';
import 'models.dart';
import 'widgets/letter_keyboard.dart';
import 'widgets/team_panel.dart';
import 'widgets/wheel_widget.dart';

Future<List<GameQuestion>> _loadQuestions(String assetPath) async {
  final String jsonString = await rootBundle.loadString(assetPath);
  final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
  return decoded
      .map((dynamic item) => GameQuestion(
            question: item['question'] as String,
            answer: (item['answer'] as String).toUpperCase(),
          ))
      .toList();
}

Future<_GameBundle> loadGameData() async {
  final List<GameQuestion> mainQuestions = await _loadQuestions('assets/questions.json');
  final List<GameQuestion> mysteryQuestions =
      await _loadQuestions('assets/mystery_questions.json');
  return _GameBundle(questions: mainQuestions, mysteryQuestions: mysteryQuestions);
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
    return FutureBuilder<_GameBundle>(
      future: loadGameData(),
      builder: (BuildContext context, AsyncSnapshot<_GameBundle> snapshot) {
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

        if (!snapshot.hasData || snapshot.data!.questions.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: _GameBackground(
              child: Center(
                child: Text('Не удалось загрузить вопросы.'),
              ),
            ),
          );
        }

        return GameScreen(
          questions: snapshot.data!.questions,
          mysteryQuestions: snapshot.data!.mysteryQuestions,
        );
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.questions,
    required this.mysteryQuestions,
  });

  final List<GameQuestion> questions;
  final List<GameQuestion> mysteryQuestions;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> _gifOptions = <String>[];
  late GameEngine _engine;
  late List<WheelSector> _sectors;
  late int _initialWheelIndex;
  final GlobalKey<WheelWidgetState> _wheelKey = GlobalKey<WheelWidgetState>();
  final List<String> _letters = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'.split('');

  bool _isSpinning = false;
  bool _canGuessLetter = false;
  bool _finalDialogShown = false;
  WheelSector? _lastSector;
  late List<String?> _teamGifSelections;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(
      questions: widget.questions,
      specialQuestions: widget.mysteryQuestions,
    );
    _sectors = buildDefaultSectors();
    _initialWheelIndex = _engine.randomStartIndex(_sectors.length);
    _teamGifSelections = List<String?>.filled(_engine.teamNames.length, null);
    _loadGifOptions();
  }

  Future<void> _loadGifOptions() async {
    final List<String> assets = await GifAssetCatalog.load();
    if (!mounted) return;
    setState(() {
      _gifOptions = assets;
      for (int i = 0; i < _teamGifSelections.length && i < assets.length; i++) {
        _teamGifSelections[i] ??= assets[i];
      }
    });
  }

  void _handleSpin() {
    if (_isSpinning || _engine.isGameFinished) {
      return;
    }
    setState(() {
      _isSpinning = true;
      _canGuessLetter = false;
    });
    _wheelKey.currentState?.spinWheel();
  }

  Future<void> _handleGifTap(int teamIndex) async {
    final String? chosen = await _showGifPickerDialog(
      initialSelection: _teamGifSelections[teamIndex],
    );
    if (chosen != null) {
      setState(() {
        _teamGifSelections[teamIndex] = chosen;
      });
    }
  }

  Future<void> _onSectorComplete(WheelSector sector) async {
    final SectorResolution resolution = _engine.applySector(sector);
    setState(() {
      _isSpinning = false;
      _lastSector = sector;
    });

    if (resolution.message != null) {
      _showSnack(resolution.message!);
    }

    bool allowGuess = resolution.allowLetterGuess && !resolution.turnEnds;

    if (resolution.requiresMysteryQuestion) {
      final bool? success = await _showMysteryQuestionDialog();
      if (!mounted) {
        return;
      }
      if (success != null) {
        _engine.applyMysteryOutcome(success);
        setState(() {});
        _showSnack(
          success
              ? 'Верный ответ! +1000 очков команде.'
              : 'Неверный ответ. -200 очков.',
        );
      }
    }

    if (resolution.allowLetterSelection) {
      final bool questionCleared = await _showLetterSelectionDialog();
      if (!mounted) {
        return;
      }
      if (questionCleared) {
        allowGuess = false;
      }
    }

    if (_engine.isGameFinished && !_finalDialogShown) {
      _finalDialogShown = true;
      await _showDialog('Игра окончена', 'Все вопросы отгаданы! Сыграем ещё раз?');
      if (!mounted) {
        return;
      }
      allowGuess = false;
    }

    setState(() {
      _canGuessLetter = allowGuess && !_engine.isGameFinished;
    });
  }

  void _onLetterPressed(String letter) {
    if (_engine.isGameFinished) {
      return;
    }
    if (!_canGuessLetter) {
      _showSnack('Сначала раскрутите барабан!');
      return;
    }

    final int previousQuestion = _engine.currentQuestionNumber;
    final bool found = _engine.guessLetter(letter);
    final bool questionChanged = _engine.currentQuestionNumber != previousQuestion;
    setState(() {
      _canGuessLetter = false;
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
      _canGuessLetter = false;
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

  Future<bool?> _showMysteryQuestionDialog() async {
    if (!mounted) return null;
    final GameQuestion? question = _engine.drawMysteryQuestion();
    if (question == null) {
      _showSnack('Дополнительные вопросы закончились.');
      return null;
    }

    final TextEditingController controller = TextEditingController();
    String? errorText;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) dialogSetState) {
            return AlertDialog(
              title: const Text('Дополнительный вопрос'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    question.question,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Ответ',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    final String value = controller.text.trim().toUpperCase();
                    if (value.isEmpty) {
                      dialogSetState(() {
                        errorText = 'Введите ответ';
                      });
                      return;
                    }
                    Navigator.of(context).pop(value == question.answer);
                  },
                  child: const Text('Принять ответ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showLetterSelectionDialog() async {
    if (!mounted) return false;
    final List<String> available = _engine.availableLettersForReveal;
    if (available.isEmpty) {
      _showSnack('Все буквы уже открыты.');
      return false;
    }

    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите букву для открытия'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: available
                  .map(
                    (String letter) => ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(letter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334AC2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return false;
    }

    if (selected == null) {
      return false;
    }

    final int previousQuestion = _engine.currentQuestionNumber;
    final bool revealed = _engine.revealLetterFreely(selected);
    final bool questionChanged = _engine.currentQuestionNumber != previousQuestion;

    if (revealed) {
      setState(() {});
      _showSnack('Буква $selected открыта!');
    }

    if (questionChanged) {
      setState(() {
        _initialWheelIndex = _engine.randomStartIndex(_sectors.length);
      });
      _showSnack('Слово отгадано! Следующий вопрос.');
    }

    return questionChanged;
  }

  Future<String?> _showGifPickerDialog({String? initialSelection}) async {
    if (!mounted) return null;
    String? tempSelection = initialSelection ??
        (_gifOptions.isNotEmpty ? _gifOptions.first : null);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF0B1028),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setDialogState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Выберите гифку для команды',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 260,
                        child: _gifOptions.isEmpty
                            ? Center(
                                child: Text(
                                  'Добавьте GIF-файлы в папку assets/gifs',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _gifOptions.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (BuildContext context, int index) {
                                  final String asset = _gifOptions[index];
                                  final bool isSelected = asset == tempSelection;
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        tempSelection = asset;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amberAccent
                                              : Colors.white24,
                                          width: isSelected ? 3 : 1.4,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          asset,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: tempSelection == null
                                ? null
                                : () => Navigator.of(context).pop(tempSelection),
                            child: const Text('Подтвердить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                key: ValueKey<String>(question.question),
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
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Wrap(
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
        ),
      ],
    );
  }

  Widget _buildWheelSection({required double wheelSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: FittedBox(
            fit: BoxFit.contain,
            child: WheelWidget(
              key: _wheelKey,
              sectors: _sectors,
              initialIndex: _initialWheelIndex,
              onSpinComplete: (WheelSector sector) {
                _onSectorComplete(sector);
              },
              size: wheelSize,
            ),
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

  Widget _buildTeamColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(_engine.teamNames.length, (int index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _engine.teamNames.length - 1 ? 0 : 14,
          ),
          child: TeamPanel(
            name: _engine.teamNames[index],
            score: _engine.scores[index],
            gifAssetPath: _teamGifSelections[index],
            isActive: _engine.activeTeamIndex == index,
            onGifTap: () => _handleGifTap(index),
          ),
        );
      }),
    );
  }

  Widget _buildWheelAndTeams({
    required bool isWide,
    required double maxWidth,
  }) {
    final double baseDiameter = maxWidth * (isWide ? 0.45 : 0.78);
    final double minDiameter = isWide ? 560 : 300;
    final double maxDiameter = isWide ? 760 : maxWidth - 176;
    final double safeMaxDiameter = max(minDiameter, maxDiameter);
    double targetWheelDiameter = baseDiameter;
    if (targetWheelDiameter < minDiameter) {
      targetWheelDiameter = minDiameter;
    } else if (targetWheelDiameter > safeMaxDiameter) {
      targetWheelDiameter = safeMaxDiameter;
    }
    final double wheelColumnWidth = targetWheelDiameter + 176;

    Widget buildWheelBox() {
      return SizedBox(
        width: wheelColumnWidth,
        child: _buildWheelSection(wheelSize: targetWheelDiameter),
      );
    }

    final Widget wideWheel = Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: buildWheelBox(),
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wheelColumnWidth),
                child: buildWheelBox(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTeamColumn(),
        ],
      );
    }

    final Widget teams = SizedBox(
      width: 270,
      child: _buildTeamColumn(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 5, child: wideWheel),
          const SizedBox(width: 36),
          teams,
        ],
      ),
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
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isWide = constraints.maxWidth >= 1100;
                final Widget keyboard = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: LetterKeyboard(
                      letters: _letters,
                      disabledLetters: _engine.usedLetters,
                      isEnabled: _canGuessLetter && !_engine.isGameFinished,
                      onLetterPressed: _onLetterPressed,
                    ),
                  ),
                );

                if (!isWide) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 24),
                        _buildQuestionBlock(),
                        const SizedBox(height: 40),
                        keyboard,
                        const SizedBox(height: 60),
                        _buildWheelAndTeams(
                          isWide: false,
                          maxWidth: constraints.maxWidth,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 32),
                    _buildQuestionBlock(),
                    const SizedBox(height: 40),
                    keyboard,
                    const SizedBox(height: 60),
                      Expanded(
                        child: _buildWheelAndTeams(
                          isWide: true,
                          maxWidth: constraints.maxWidth,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBundle {
  const _GameBundle({
    required this.questions,
    required this.mysteryQuestions,
  });

  final List<GameQuestion> questions;
  final List<GameQuestion> mysteryQuestions;
}

/// Загружает список gif-файлов из каталога assets/gifs через AssetManifest.
class GifAssetCatalog {
  const GifAssetCatalog._();

  static Future<List<String>> load() async {
    try {
      final String manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
      final List<String> gifs = manifestMap.keys
          .where((String key) => key.startsWith('assets/gifs/') && key.toLowerCase().endsWith('.gif'))
          .toList()
        ..sort();
      return gifs;
    } catch (_) {
      return <String>[];
    }
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
