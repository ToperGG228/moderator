import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

/// Управляет состоянием игры, командами, вопросами и барабаном.
class GameEngine {
  GameEngine({
    required this.questions,
    required this.specialQuestions,
  })  : teamNames = const ['Команда 1', 'Команда 2', 'Команда 3'],
        scores = List<int>.filled(3, 0),
        _random = Random() {
    _prepareQuestion();
  }

  /// Названия команд (можно расширять при необходимости).
  final List<String> teamNames;

  /// Текущие очки команд.
  final List<int> scores;

  /// Все вопросы игры.
  final List<GameQuestion> questions;

  /// Дополнительные вопросы для сектора «?».
  final List<GameQuestion> specialQuestions;

  /// Текущий индекс вопроса.
  int _currentQuestionIndex = 0;

  /// Индекс активной команды.
  int activeTeamIndex = 0;

  /// Набор уже выбранных букв.
  final Set<String> usedLetters = <String>{};

  /// Символы ответа.
  late List<String> _answerCharacters;

  /// Флаги, показывающие открытые буквы.
  late List<bool> _revealed;

  /// Признак завершения игры.
  bool _gameFinished = false;

  final Random _random;

  /// Текущий вопрос или null, если игра завершена.
  GameQuestion? get currentQuestion =>
      _gameFinished ? null : questions[_currentQuestionIndex];

  /// Возвращает копию списка открытых букв.
  List<bool> get revealedLetters => List<bool>.unmodifiable(_revealed);

  /// Признак завершённости игры.
  bool get isGameFinished => _gameFinished;

  /// Возвращает символы ответа текущего вопроса.
  List<String> get answerCharacters => List<String>.unmodifiable(_answerCharacters);

  /// Список букв, которые ещё можно открыть вручную.
  List<String> get availableLettersForReveal {
    final Set<String> result = <String>{};
    for (int i = 0; i < _answerCharacters.length; i++) {
      if (_answerCharacters[i] != ' ' && !_revealed[i]) {
        result.add(_answerCharacters[i]);
      }
    }
    final List<String> sorted = result.toList()..sort();
    return sorted;
  }

  /// Номер текущего вопроса.
  int get currentQuestionNumber => _currentQuestionIndex;

  /// Сбрасывает состояние игры на первый вопрос.
  void resetGame() {
    scores.fillRange(0, scores.length, 0);
    activeTeamIndex = 0;
    _currentQuestionIndex = 0;
    _gameFinished = false;
    _prepareQuestion();
  }

  /// Обрабатывает сектор барабана и возвращает описание эффекта.
  SectorResolution applySector(WheelSector sector) {
    switch (sector.type) {
      case SectorType.points:
        final int points = sector.points ?? 0;
        scores[activeTeamIndex] += points;
        return SectorResolution(message: 'Команда получает $points очков!');
      case SectorType.bankrupt:
        scores[activeTeamIndex] = 0;
        _nextTeam();
        return const SectorResolution(
          message: 'Банкрот! Ход переходит следующей команде.',
          allowLetterGuess: false,
          turnEnds: true,
        );
      case SectorType.doubleScore:
        scores[activeTeamIndex] *= 2;
        return const SectorResolution(message: 'Очки команды удваиваются!');
      case SectorType.bonus:
        final int bonus = sector.points ?? 100;
        scores[activeTeamIndex] += bonus;
        return SectorResolution(
          message: 'Бонус +$bonus очков! Выберите букву для открытия.',
          allowLetterSelection: true,
        );
      case SectorType.prize:
        scores[activeTeamIndex] += 500;
        return const SectorResolution(
          message: 'Сектор «Приз»! +500 очков команде.',
        );
      case SectorType.mystery:
        return const SectorResolution(
          message: 'Сектор «?»! Ответьте на дополнительный вопрос.',
          requiresMysteryQuestion: true,
        );
      case SectorType.miss:
        _nextTeam();
        return const SectorResolution(
          message: 'Ничего не происходит. Ход переходит следующей команде.',
          allowLetterGuess: false,
          turnEnds: true,
        );
    }
  }

  /// Обрабатывает попытку отгадать букву. Возвращает true, если буква найдена.
  bool guessLetter(String letter) {
    final String normalized = letter.toUpperCase();
    if (usedLetters.contains(normalized) || _gameFinished) {
      return false;
    }
    usedLetters.add(normalized);

    bool found = false;
    for (int i = 0; i < _answerCharacters.length; i++) {
      if (_answerCharacters[i] == normalized) {
        _revealed[i] = true;
        found = true;
      }
    }

    if (!found) {
      _nextTeam();
    } else if (_revealed.every((bool element) => element)) {
      // Все буквы открыты — переходим к следующему вопросу.
      _advanceQuestion();
    }

    return found;
  }

  /// Открывает выбранную букву без штрафа и возвращает true, если она нашлась.
  bool revealLetterFreely(String letter) {
    final String normalized = letter.toUpperCase();
    bool revealedAny = false;
    for (int i = 0; i < _answerCharacters.length; i++) {
      if (_answerCharacters[i] == normalized && !_revealed[i]) {
        _revealed[i] = true;
        revealedAny = true;
      }
    }
    if (revealedAny) {
      usedLetters.add(normalized);
      if (_revealed.every((bool value) => value)) {
        _advanceQuestion();
      }
    }
    return revealedAny;
  }

  /// Применяет результат ответа на дополнительный вопрос.
  void applyMysteryOutcome(bool isCorrect) {
    if (isCorrect) {
      scores[activeTeamIndex] += 1000;
    } else {
      scores[activeTeamIndex] -= 200;
    }
  }

  /// Возвращает случайный дополнительный вопрос.
  GameQuestion? drawMysteryQuestion() {
    if (specialQuestions.isEmpty) {
      return null;
    }
    return specialQuestions[_random.nextInt(specialQuestions.length)];
  }

  /// Переход к следующей команде.
  void _nextTeam() {
    activeTeamIndex = (activeTeamIndex + 1) % teamNames.length;
  }

  /// Переходит к следующему вопросу или завершает игру.
  void _advanceQuestion() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex >= questions.length) {
      _gameFinished = true;
    } else {
      usedLetters.clear();
      _prepareQuestion();
    }
  }

  /// Подготавливает данные для текущего вопроса.
  void _prepareQuestion() {
    final GameQuestion? question = currentQuestion;
    if (question == null) {
      _gameFinished = true;
      return;
    }
    _answerCharacters = question.characters;
    _revealed = _answerCharacters
        .map((String char) => char == ' ')
        .toList(growable: false);
    usedLetters.clear();
  }

  /// Генерирует случайный начальный сектор для красоты.
  int randomStartIndex(int sectorCount) => _random.nextInt(sectorCount);
}

/// Создаёт список секторов барабана.
List<WheelSector> buildDefaultSectors() {
  return <WheelSector>[
    WheelSector(label: '100', type: SectorType.points, points: 100, color: const Color(0xFFE0A106)),
    WheelSector(label: '150', type: SectorType.points, points: 150, color: const Color(0xFF1059C0)),
    WheelSector(label: '200', type: SectorType.points, points: 200, color: const Color(0xFF0F8F6D)),
    WheelSector(label: '300', type: SectorType.points, points: 300, color: const Color(0xFFB6338C)),
    WheelSector(label: '400', type: SectorType.points, points: 400, color: const Color(0xFF8240D7)),
    WheelSector(label: '450', type: SectorType.points, points: 450, color: const Color(0xFF3AA9DA)),
    WheelSector(label: '500', type: SectorType.points, points: 500, color: const Color(0xFF2F934D)),
    WheelSector(label: '0', type: SectorType.miss, points: 0, color: const Color(0xFF424242)),
    WheelSector(label: 'Банкрот', type: SectorType.bankrupt, color: const Color(0xFF111111)),
    WheelSector(label: 'x2', type: SectorType.doubleScore, color: const Color(0xFF1565C0)),
    WheelSector(label: '+100', type: SectorType.bonus, points: 100, color: const Color(0xFFF57F17)),
    WheelSector(label: 'Приз', type: SectorType.prize, color: const Color(0xFFD81B60)),
    WheelSector(label: '?', type: SectorType.mystery, color: const Color(0xFF5E35B1)),
    WheelSector(label: '250', type: SectorType.points, points: 250, color: const Color(0xFF00897B)),
    WheelSector(label: '350', type: SectorType.points, points: 350, color: const Color(0xFF3949AB)),
    WheelSector(label: '550', type: SectorType.points, points: 550, color: const Color(0xFFC62828)),
  ];
}
