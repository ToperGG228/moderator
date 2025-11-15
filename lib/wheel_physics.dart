import 'dart:math';

/// Описывает математику вращения барабана без привязки к UI.
class WheelPhysics {
  WheelPhysics({
    required this.sectorCount,
    required this.baseRotation,
    this.minFullTurns = 4,
    this.maxFullTurns = 6,
    this.accelerationSeconds = 1.5,
    this.minCruiseSeconds = 0.8,
    this.maxCruiseSeconds = 2.8,
    this.minDecelerationSeconds = 0.4,
    this.maxDecelerationSeconds = 1.4,
  }) : segmentAngle = 2 * pi / sectorCount;

  final int sectorCount;
  final double baseRotation;
  final double segmentAngle;
  final int minFullTurns;
  final int maxFullTurns;
  final double accelerationSeconds;
  final double minCruiseSeconds;
  final double maxCruiseSeconds;
  final double minDecelerationSeconds;
  final double maxDecelerationSeconds;

  /// Возвращает угол, при котором центр сектора [index] оказывается под стрелкой.
  double angleForIndex(int index) {
    final int normalized = ((index % sectorCount) + sectorCount) % sectorCount;
    return baseRotation - normalized * segmentAngle;
  }

  /// Рассчитывает параметры спина, чтобы выбранный сектор оказался под стрелкой.
  WheelSpinResult computeSpin({
    required double currentRotation,
    required int targetIndex,
    required Random random,
  }) {
    final int normalizedIndex = ((targetIndex % sectorCount) + sectorCount) % sectorCount;
    final double offset = _landingOffset(random);
    final double targetAngle = angleForIndex(normalizedIndex) + offset;
    final int fullTurns = _randomFullTurns(random);

    final double delta = _positiveDelta(currentRotation, targetAngle);
    final double totalAngle = fullTurns * 2 * pi + delta;

    final double cruiseSeconds =
        minCruiseSeconds + random.nextDouble() * (maxCruiseSeconds - minCruiseSeconds);
    final double decelSeconds = minDecelerationSeconds +
        random.nextDouble() * (maxDecelerationSeconds - minDecelerationSeconds);
    final double totalSeconds = accelerationSeconds + cruiseSeconds + decelSeconds;

    final double t1 = accelerationSeconds / totalSeconds;
    final double t2 = (accelerationSeconds + cruiseSeconds) / totalSeconds;

    return WheelSpinResult(
      targetIndex: normalizedIndex,
      startRotation: currentRotation,
      endRotation: currentRotation + totalAngle,
      duration: Duration(milliseconds: (totalSeconds * 1000).round()),
      t1: t1,
      t2: t2,
    );
  }

  /// Нормализует угол в диапазон [0, 2π).
  double normalizeAngle(double angle) {
    final double circle = 2 * pi;
    double value = angle % circle;
    if (value < 0) {
      value += circle;
    }
    return value;
  }

  double _landingOffset(Random random) {
    return (random.nextDouble() * 0.4 - 0.2) * segmentAngle;
  }

  int _randomFullTurns(Random random) {
    if (maxFullTurns <= minFullTurns) {
      return minFullTurns;
    }
    return minFullTurns + random.nextInt(maxFullTurns - minFullTurns + 1);
  }

  double _positiveDelta(double start, double target) {
    double delta = target - start;
    while (delta <= 0) {
      delta += 2 * pi;
    }
    return delta;
  }
}

/// Результат расчёта спина.
class WheelSpinResult {
  const WheelSpinResult({
    required this.targetIndex,
    required this.startRotation,
    required this.endRotation,
    required this.duration,
    required this.t1,
    required this.t2,
  });

  final int targetIndex;
  final double startRotation;
  final double endRotation;
  final Duration duration;
  final double t1;
  final double t2;
}
