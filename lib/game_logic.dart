import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class GameEngine {
  GameEngine({
    required List<GameQuestion> questions,
    required List<GameQuestion> mysteryQuestions,
    int teamCount = 3,
  })  : questions = List<GameQuestion>.from(questions),
        _mysteryBag = MysteryQuestionBag(List<GameQuestion>.from(mysteryQuestions)),
        teams = List.generate(teamCount, (index) => TeamState(name: 'Команда ${index + 1}')) {
    _initQuestion();
  }

  final List<GameQuestion> questions;
  final List<TeamState> teams;
  final MysteryQuestionBag _mysteryBag;

  int _currentQuestionIndex = 0;
  int activeTeamIndex = 0;
  bool isGameOver = false;
  late List<bool> _revealed;
  final Set<String> usedLetters = <String>{};

  GameQuestion? get currentQuestion {
    if (_currentQuestionIndex < questions.length) {
      return questions[_currentQuestionIndex];
    }
    return null;
  }

  List<bool> get revealedLetters => List<bool>.unmodifiable(_revealed);

  int get regularQuestionCount => questions.length;
  int get mysteryQuestionCount => _mysteryBag.length;

  void _initQuestion() {
    usedLetters.clear();
    final current = currentQuestion;
    if (current == null) {
      _revealed = <bool>[];
      isGameOver = true;
      return;
    }
    _revealed = current.answer.characters
        .map((char) => char == ' ')
        .toList();
  }

  void replaceQuestions({required List<GameQuestion> regular, required List<GameQuestion> mystery}) {
    questions
      ..clear()
      ..addAll(regular);
    _mysteryBag.replaceQuestions(mystery);
    _currentQuestionIndex = 0;
    activeTeamIndex = 0;
    isGameOver = false;
    for (final team in teams) {
      team.score = 0;
    }
    _initQuestion();
  }

  void reset() {
    _currentQuestionIndex = 0;
    activeTeamIndex = 0;
    isGameOver = false;
    for (final team in teams) {
      team.score = 0;
    }
    _initQuestion();
  }

  void nextTeam() {
    activeTeamIndex = (activeTeamIndex + 1) % teams.length;
  }

  int revealLetter(String letter) {
    if (currentQuestion == null) {
      return 0;
    }
    final normalized = letter.toUpperCase();
    if (usedLetters.contains(normalized)) {
      return 0;
    }
    usedLetters.add(normalized);
    int hits = 0;
    int index = 0;
    for (final char in currentQuestion!.answer.characters) {
      if (char == normalized) {
        _revealed[index] = true;
        hits++;
      }
      index++;
    }
    return hits;
  }

  bool get isWordSolved =>
      _revealed.isNotEmpty &&
      !_revealed.contains(false);

  void advanceQuestion() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex >= questions.length) {
      isGameOver = true;
      return;
    }
    _initQuestion();
  }

  void awardPoints(int points) {
    teams[activeTeamIndex].score += points;
  }

  void applyBankrupt() {
    teams[activeTeamIndex].score = 0;
    nextTeam();
  }

  void applySkipTurn() {
    nextTeam();
  }

  GameQuestion? drawMysteryQuestion() => _mysteryBag.draw();

  void assignTeamGif(int teamIndex, String assetPath) {
    if (teamIndex < 0 || teamIndex >= teams.length) return;
    teams[teamIndex].gifAsset = assetPath;
  }
}

class QuestionLoader {
  static Future<List<GameQuestion>> loadFromAsset(String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    final List<dynamic> data = jsonDecode(content) as List<dynamic>;
    return data
        .map((item) => GameQuestion(
              question: item['question'] as String,
              answer: (item['answer'] as String).toUpperCase(),
            ))
        .toList();
  }

  static Future<QuestionImportResult> loadFromFile(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final List<dynamic> data = jsonDecode(content) as List<dynamic>;
    return QuestionImportResult.fromJsonList(data);
  }

  static QuestionImportResult parseCombinedJson(String content) {
    final List<dynamic> data = jsonDecode(content) as List<dynamic>;
    return QuestionImportResult.fromJsonList(data);
  }
}

class QuestionImportResult {
  QuestionImportResult({required this.regular, required this.mystery});

  final List<GameQuestion> regular;
  final List<GameQuestion> mystery;

  factory QuestionImportResult.fromJsonList(List<dynamic> data) {
    final regular = <GameQuestion>[];
    final mystery = <GameQuestion>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final question = item['question'] as String?;
        final answer = item['answer'] as String?;
        final isMystery = item['isMystery'] as bool? ?? false;
        if (question == null || answer == null) continue;
        final model = GameQuestion(question: question, answer: answer.toUpperCase());
        if (isMystery) {
          mystery.add(model);
        } else {
          regular.add(model);
        }
      }
    }
    return QuestionImportResult(regular: regular, mystery: mystery);
  }
}
