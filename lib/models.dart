import 'dart:math';

import 'package:flutter/material.dart';

class GameQuestion {
  GameQuestion({required this.question, required String answer})
      : answer = answer.toUpperCase();

  final String question;
  final String answer;
}

enum WheelSectorType { score, skip, bankrupt, mystery, freeLetter }

class WheelSector {
  const WheelSector({
    required this.label,
    required this.color,
    required this.type,
    this.value = 0,
  });

  final String label;
  final Color color;
  final WheelSectorType type;
  final int value;
}

class TeamState {
  TeamState({required this.name});

  final String name;
  int score = 0;
  String? gifAsset;
}

class MysteryQuestionBag {
  MysteryQuestionBag(this._questions)
      : _random = Random(),
        _used = <int>{};

  final List<GameQuestion> _questions;
  final Random _random;
  final Set<int> _used;

  int get length => _questions.length;

  GameQuestion? draw() {
    if (_questions.isEmpty) {
      return null;
    }
    if (_used.length == _questions.length) {
      _used.clear();
    }
    int index;
    do {
      index = _random.nextInt(_questions.length);
    } while (_used.contains(index));
    _used.add(index);
    return _questions[index];
  }

  void replaceQuestions(List<GameQuestion> questions) {
    _questions
      ..clear()
      ..addAll(questions);
    _used.clear();
  }
}
