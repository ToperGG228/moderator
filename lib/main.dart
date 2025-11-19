import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'game_logic.dart';
import 'gif_catalog.dart';
import 'models.dart';
import 'widgets/letter_keyboard.dart';
import 'widgets/team_panel.dart';
import 'widgets/wheel_widget.dart';
import 'widgets/wheel_smoke_effect.dart';

void main() {
  runApp(const WheelGameApp());
}

class WheelGameApp extends StatelessWidget {
  const WheelGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Поле чудес',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1021),
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final StreamController<int> _fortuneController = StreamController<int>.broadcast();
  late final List<WheelSector> _sectors;
  GameEngine? _engine;
  bool _isLoading = true;
  bool _isSpinning = false;
  bool _canGuessLetter = false;
  int _pointsPerLetter = 0;
  WheelSector? _lastSector;
  int _pendingSectorIndex = 0;
  List<String> _gifOptions = const [];
  String? _statusMessage;
  late final AudioPlayer _spinPlayer = AudioPlayer();
  late final AudioPlayer _stopPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _smokeEnabled = true;
  List<GameQuestion> _defaultQuestions = const [];
  List<GameQuestion> _defaultMystery = const [];

  @override
  void initState() {
    super.initState();
    _sectors = _createDefaultSectors();
    _loadInitialData();
  }

  @override
  void dispose() {
    _fortuneController.close();
    _spinPlayer.dispose();
    _stopPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final questions = await QuestionLoader.loadFromAsset('assets/questions.json');
    final mystery = await QuestionLoader.loadFromAsset('assets/mystery_questions.json');
    final catalog = await GifAssetCatalog.load();
    setState(() {
      _defaultQuestions = List<GameQuestion>.from(questions);
      _defaultMystery = List<GameQuestion>.from(mystery);
      _gifOptions = catalog.items;
      _engine = GameEngine(questions: questions, mysteryQuestions: mystery);
      _isLoading = false;
    });
  }

  List<WheelSector> _createDefaultSectors() {
    return const [
      WheelSector(label: '+100', color: Color(0xFF5E60CE), type: WheelSectorType.score, value: 100),
      WheelSector(label: '+200', color: Color(0xFF5390D9), type: WheelSectorType.score, value: 200),
      WheelSector(label: 'Пропуск', color: Color(0xFFE5989B), type: WheelSectorType.skip),
      WheelSector(label: '+300', color: Color(0xFF64DFDF), type: WheelSectorType.score, value: 300),
      WheelSector(label: 'Банкрот', color: Color(0xFFFB6F92), type: WheelSectorType.bankrupt),
      WheelSector(label: 'Секрет', color: Color(0xFFFFC857), type: WheelSectorType.mystery),
      WheelSector(label: '+500', color: Color(0xFF6930C3), type: WheelSectorType.score, value: 500),
      WheelSector(label: 'Бесплатная буква', color: Color(0xFF80FFDB), type: WheelSectorType.freeLetter),
      WheelSector(label: '+150', color: Color(0xFF4EA8DE), type: WheelSectorType.score, value: 150),
      WheelSector(label: '+400', color: Color(0xFF56CFE1), type: WheelSectorType.score, value: 400),
    ];
  }

  void _handleSpin() {
    final engine = _engine;
    if (engine == null || engine.isGameOver) {
      return;
    }
    if (_isSpinning || _canGuessLetter) {
      _showSnack('Сначала завершите текущий ход.');
      return;
    }
    setState(() {
      _isSpinning = true;
      _statusMessage = 'Колесо в пути...';
      _pointsPerLetter = 0;
    });
    _startSpinSound();
    final random = Random().nextInt(_sectors.length);
    _pendingSectorIndex = random;
    _fortuneController.add(random);
  }

  void _onWheelAnimationEnd() {
    if (!_isSpinning) return;
    final sector = _sectors[_pendingSectorIndex];
    _stopSpinSound();
    _playStopSound();
    setState(() {
      _isSpinning = false;
      _lastSector = sector;
    });
    _onSectorComplete(sector);
  }

  Future<void> _startSpinSound() async {
    if (!_soundEnabled) return;
    try {
      await _spinPlayer.stop();
      await _spinPlayer.setReleaseMode(ReleaseMode.loop);
      await _spinPlayer.setSourceAsset('sounds/wheel_spin.mp3');
      await _spinPlayer.resume();
    } catch (_) {}
  }

  Future<void> _stopSpinSound() async {
    try {
      await _spinPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playStopSound() async {
    if (!_soundEnabled) return;
    try {
      await _stopPlayer.stop();
      await _stopPlayer.setSourceAsset('sounds/wheel_stop.mp3');
      await _stopPlayer.resume();
    } catch (_) {}
  }

  void _onSectorComplete(WheelSector sector) {
    final engine = _engine;
    if (engine == null) return;
    switch (sector.type) {
      case WheelSectorType.score:
        setState(() {
          _pointsPerLetter = sector.value;
          _canGuessLetter = true;
          _statusMessage = 'Выберите букву на сумму ${sector.value}';
        });
        break;
      case WheelSectorType.skip:
        engine.applySkipTurn();
        _statusMessage = 'Пропуск хода. Ход переходит дальше';
        setState(() {});
        break;
      case WheelSectorType.bankrupt:
        engine.applyBankrupt();
        _statusMessage = 'Банкрот! Очки обнулены';
        setState(() {});
        break;
      case WheelSectorType.mystery:
        _showMysteryQuestionDialog();
        break;
      case WheelSectorType.freeLetter:
        _showLetterSelectionDialog();
        break;
    }
  }

  void _onLetterPressed(String letter) {
    final engine = _engine;
    if (engine == null) return;
    if (!_canGuessLetter) {
      _showSnack('Сначала вращайте колесо.');
      return;
    }
    final hits = engine.revealLetter(letter);
    setState(() {});
    if (hits > 0) {
      final gained = hits * _pointsPerLetter;
      engine.awardPoints(gained);
      _showSnack('Открыто $hits букв(ы). +$gained очков!');
      if (engine.isWordSolved) {
        _showSnack('Слово отгадано!');
        engine.advanceQuestion();
        if (engine.isGameOver) {
          _statusMessage = 'Игра завершена!';
        }
      }
    } else {
      _showSnack('Нет такой буквы. Ход переходит.');
      engine.nextTeam();
    }
    setState(() {
      _canGuessLetter = false;
      _pointsPerLetter = 0;
    });
  }

  Future<void> _showMysteryQuestionDialog() async {
    final engine = _engine;
    if (engine == null) return;
    final question = engine.drawMysteryQuestion();
    if (question == null) {
      _showSnack('Секретные вопросы закончились.');
      return;
    }
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Секретный вопрос'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question.question),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Ответ'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ответить')),
          ],
        );
      },
    );
    if (result ?? false) {
      final answer = controller.text.trim().toUpperCase();
      final isCorrect = answer == question.answer;
      if (isCorrect) {
        engine.awardPoints(500);
        _showSnack('Верно! +500 очков');
      } else {
        engine.awardPoints(-300);
        _showSnack('Неверно. -300 очков');
      }
      setState(() {});
    }
  }

  Future<void> _showLetterSelectionDialog() async {
    final engine = _engine;
    if (engine == null) return;
    final available = LetterKeyboard.alphabet
        .split('')
        .where((letter) => !engine.usedLetters.contains(letter))
        .toList();
    if (available.isEmpty) {
      _showSnack('Все буквы уже использованы.');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Откройте букву бесплатно'),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available
                .map(
                  (letter) => ActionChip(
                    label: Text(letter, style: const TextStyle(fontSize: 18)),
                    onPressed: () => Navigator.pop(context, letter),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      final hits = engine.revealLetter(selected);
      if (hits > 0) {
        _showSnack('Буква $selected открыта $hits раз.');
        if (engine.isWordSolved) {
          engine.advanceQuestion();
        }
      } else {
        _showSnack('Такой буквы нет.');
        engine.nextTeam();
      }
      setState(() {});
    }
  }

  void _showGifPickerDialog(int teamIndex) {
    if (_gifOptions.isEmpty) {
      _showSnack('Добавьте GIF в папку assets/gifs');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GIF для команды ${teamIndex + 1}'),
        content: SizedBox(
          width: 420,
          height: 320,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _gifOptions.length,
            itemBuilder: (context, index) {
              final asset = _gifOptions[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _engine?.assignTeamGif(teamIndex, asset);
                  });
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(asset, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetGame() {
    _engine?.reset();
    _stopSpinSound();
    setState(() {
      _isSpinning = false;
      _canGuessLetter = false;
      _pointsPerLetter = 0;
      _statusMessage = null;
      _lastSector = null;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAdminPanel() async {
    final engine = _engine;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Админ-панель'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Обычных вопросов: ${engine?.regularQuestionCount ?? _defaultQuestions.length}'),
              Text('Секретных вопросов: ${engine?.mysteryQuestionCount ?? _defaultMystery.length}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _importQuestionsFromFile();
                },
                icon: const Icon(Icons.file_open),
                label: const Text('Импортировать вопросы (.json)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetQuestionsToDefault();
                },
                icon: const Icon(Icons.restore),
                label: const Text('Сбросить на дефолт'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSettingsDialog() async {
    bool soundEnabled = _soundEnabled;
    bool smokeEnabled = _smokeEnabled;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Звук вращения колеса'),
              value: soundEnabled,
              onChanged: (value) {
                soundEnabled = value;
                setState(() {
                  _soundEnabled = value;
                });
                if (!value) {
                  _stopSpinSound();
                }
              },
            ),
            SwitchListTile(
              title: const Text('Визуальный эффект дыма'),
              value: smokeEnabled,
              onChanged: (value) {
                smokeEnabled = value;
                setState(() {
                  _smokeEnabled = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _importQuestionsFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) throw Exception('Файл не выбран.');
      final parsed = await QuestionLoader.loadFromFile(path);
      if (parsed.regular.isEmpty && parsed.mystery.isEmpty) {
        _showSnack('Не удалось загрузить вопросы из файла.');
        return;
      }
      if (_engine == null) {
        setState(() {
          _engine = GameEngine(
            questions: parsed.regular,
            mysteryQuestions: parsed.mystery,
          );
        });
      } else {
        _engine!.replaceQuestions(
          regular: parsed.regular,
          mystery: parsed.mystery,
        );
        setState(() {});
      }
      _showSnack('Вопросы обновлены: ${parsed.regular.length} обычных, ${parsed.mystery.length} секретных.');
    } catch (e) {
      _showSnack('Ошибка импорта: $e');
    }
  }

  Future<void> _resetQuestionsToDefault() async {
    if (_defaultQuestions.isEmpty && _defaultMystery.isEmpty) {
      await _loadInitialData();
      return;
    }
    if (_engine == null) {
      setState(() {
        _engine = GameEngine(
          questions: _defaultQuestions,
          mysteryQuestions: _defaultMystery,
        );
      });
    } else {
      _engine!.replaceQuestions(
        regular: List<GameQuestion>.from(_defaultQuestions),
        mystery: List<GameQuestion>.from(_defaultMystery),
      );
      setState(() {});
    }
    _showSnack('Загружены вопросы по умолчанию.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildGlowCircle(const Offset(120, 200), 220, Colors.pinkAccent.withOpacity(0.2)),
            _buildGlowCircle(const Offset(320, 600), 280, Colors.blueAccent.withOpacity(0.15)),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1100;
                        final content = _buildContent(isWide, constraints);
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: content,
                        );
                      },
                    ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 46),
                  onSelected: (value) {
                    switch (value) {
                      case 'admin':
                        _openAdminPanel();
                        break;
                      case 'settings':
                        _openSettingsDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'admin', child: Text('Admin')),
                    PopupMenuItem(value: 'settings', child: Text('Настройки')),
                  ],
                  child: Container(
                    width: 90,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4C44E9), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Меню',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isWide, BoxConstraints viewportConstraints) {
    final minHeight = viewportConstraints.maxHeight.isFinite
        ? viewportConstraints.maxHeight
        : MediaQuery.of(context).size.height;

    if (!isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: _buildNarrowLayout(),
        ),
      );
    }

    final wideConstraints = BoxConstraints(
      maxWidth: viewportConstraints.maxWidth,
      maxHeight: minHeight,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: _buildWideLayout(wideConstraints),
    );
  }

  Widget _buildNarrowLayout() {
    final engine = _engine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestionBlock(),
        const SizedBox(height: 20),
        _buildKeyboardCard(dense: true),
        const SizedBox(height: 28),
        _buildWheelAndButton(),
        const SizedBox(height: 28),
        if (engine != null) _buildTeamColumn(engine),
      ],
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    final engine = _engine;
    final totalWidth = constraints.maxWidth;
    final wheelColumnWidth = (totalWidth * 0.4).clamp(360.0, totalWidth).toDouble();
    const double teamColumnWidth = 320;
    final maxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: totalWidth,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: wheelColumnWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildWheelAndButton(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildQuestionBlock(),
                    const SizedBox(height: 40),
                    _buildAlphabetPanel(),
                  ],
                ),
              ),
            ),
          ),
          if (engine != null)
            SizedBox(
              width: teamColumnWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTeamColumn(engine),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlphabetPanel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: _buildKeyboardCard(dense: true),
    );
  }

  Widget _buildWheelAndButton() {
    final maxWidth = MediaQuery.of(context).size.width;
    final isWide = maxWidth >= 1100;
    double wheelSize;
    if (isWide) {
      final baseDiameter = maxWidth * 0.42;
      wheelSize = baseDiameter.clamp(480.0, 780.0).toDouble();
    } else {
      wheelSize = max(240.0, min(maxWidth * 0.6, 420.0));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 20)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              WheelWidget(
                sectors: _sectors,
                stream: _fortuneController.stream,
                size: wheelSize,
                isSpinning: _isSpinning,
                onAnimationEnd: _onWheelAnimationEnd,
              ),
              if (_smokeEnabled)
                WheelSmokeEffect(
                  active: _isSpinning,
                  size: wheelSize,
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isSpinning ? null : _handleSpin,
              child: Text(_isSpinning ? 'Вращаем…' : 'Крутить'),
            ),
          ),
          if (_lastSector != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Последний сектор: ${_lastSector!.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyboardCard({bool dense = false}) {
    return Card(
      color: Colors.black.withOpacity(0.35),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: dense ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6) : const EdgeInsets.all(16),
        child: LetterKeyboard(
          usedLetters: _engine?.usedLetters ?? <String>{},
          onLetterPressed: _onLetterPressed,
        ),
      ),
    );
  }

  Widget _buildTeamColumn(GameEngine engine) {
    return Column(
      children: List.generate(engine.teams.length, (index) {
        final team = engine.teams[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TeamPanel(
            team: team,
            isActive: engine.activeTeamIndex == index,
            onGifTap: () => _showGifPickerDialog(index),
          ),
        );
      }),
    );
  }

  Widget _buildQuestionBlock() {
    final engine = _engine;
    if (engine == null) {
      return const SizedBox.shrink();
    }
    if (engine.isGameOver) {
      return Column(
        children: [
          const Text(
            'Игра завершена!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _resetGame, child: const Text('Начать заново')),
        ],
      );
    }
    final question = engine.currentQuestion;
    final answer = question?.answer ?? '';
    final answerChars = answer.characters.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Card(
            key: ValueKey(question?.question),
            color: Colors.black.withOpacity(0.4),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                question?.question ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, height: 1.45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 14,
          children: List.generate(answerChars.length, (index) {
            final char = answerChars[index];
            if (char == ' ') {
              return const SizedBox(width: 32, height: 80);
            }
            final isRevealed = engine.revealedLetters.length > index && engine.revealedLetters[index];
            return _AnswerTile(letter: char, revealed: isRevealed);
          }),
        ),
      ],
    );
  }

  Widget _buildGlowCircle(Offset offset, double diameter, Color color) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 120, spreadRadius: 40),
          ],
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.letter, required this.revealed});

  final String letter;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52,
      height: 80,
      decoration: BoxDecoration(
        color: revealed ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: revealed
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: revealed
          ? Text(
              letter,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : Container(
              width: 32,
              height: 2,
              color: Colors.white24,
            ),
    );
  }
}
