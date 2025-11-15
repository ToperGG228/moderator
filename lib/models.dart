import 'package:flutter/material.dart';

/// Типы секторов барабана.
enum SectorType {
  points,
  bankrupt,
  doubleScore,
  bonus,
  prize,
  mystery,
  miss,
}

/// Модель сектора барабана.
class WheelSector {
  const WheelSector({
    required this.label,
    required this.type,
    this.points,
    this.color,
  });

  /// Подпись на секторе.
  final String label;

  /// Тип сектора, определяющий поведение.
  final SectorType type;

  /// Количество очков (для очковых и бонусных секторов).
  final int? points;

  /// Цвет сектора для визуального разнообразия.
  final Color? color;
}

/// Результат обработки сектора барабана.
class SectorResolution {
  const SectorResolution({
    this.message,
    this.allowLetterGuess = true,
    this.turnEnds = false,
    this.requiresMysteryQuestion = false,
    this.allowLetterSelection = false,
  });

  /// Сообщение для отображения игроку.
  final String? message;

  /// Можно ли угадывать букву после сектора.
  final bool allowLetterGuess;

  /// Завершает ли сектор ход команды.
  final bool turnEnds;

  /// Требуется ли показать дополнительный вопрос.
  final bool requiresMysteryQuestion;

  /// Может ли команда выбрать букву для открытия.
  final bool allowLetterSelection;
}

/// Модель вопроса и ответа игры.
class GameQuestion {
  const GameQuestion({
    required this.question,
    required this.answer,
  });

  /// Текст вопроса.
  final String question;

  /// Ответ в верхнем регистре.
  final String answer;

  /// Разбиение ответа на символы.
  List<String> get characters => answer.split('');
}
