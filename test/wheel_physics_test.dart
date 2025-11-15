import 'dart:math';

import 'package:test/test.dart';

import 'package:pole_chudes/wheel_physics.dart';

void main() {
  group('WheelPhysics.angleForIndex', () {
    test('разница между соседними индексами равна углу сектора', () {
      final WheelPhysics physics = WheelPhysics(
        sectorCount: 16,
        baseRotation: -pi / 2 - (2 * pi / 16) / 2,
      );

      final double expectedDiff = physics.segmentAngle;

      for (int i = 0; i < 16; i++) {
        final double diff =
            physics.angleForIndex(i) - physics.angleForIndex((i + 1) % 16);
        expect(diff, closeTo(expectedDiff, 1e-9));
      }

      final double looped =
          physics.angleForIndex(0) - physics.angleForIndex(16);
      expect(looped % (2 * pi), closeTo(0, 1e-9));
    });
  });

  group('WheelPhysics.computeSpin', () {
    test('возвращает тот же targetIndex', () {
      final WheelPhysics physics = WheelPhysics(
        sectorCount: 16,
        baseRotation: -pi / 2 - (2 * pi / 16) / 2,
      );
      final Random random = Random(123);

      for (final int index in <int>[0, 3, 7, 10, 15]) {
        final WheelSpinResult result = physics.computeSpin(
          currentRotation: 0,
          targetIndex: index,
          random: random,
        );
        expect(result.targetIndex, index);

        final double delta = _deltaToTarget(
          physics: physics,
          targetIndex: index,
          rotation: result.endRotation,
        );
        expect(delta.abs(), lessThan(physics.segmentAngle / 2));
      }
    });

    test('любой targetIndex приводит сектор под стрелку', () {
      final WheelPhysics physics = WheelPhysics(
        sectorCount: 16,
        baseRotation: -pi / 2 - (2 * pi / 16) / 2,
      );
      final Random random = Random(42);

      for (int i = 0; i < 100; i++) {
        final int targetIndex = random.nextInt(physics.sectorCount);
        final double currentRotation = random.nextDouble() * 2 * pi;

        final WheelSpinResult result = physics.computeSpin(
          currentRotation: currentRotation,
          targetIndex: targetIndex,
          random: random,
        );

        final double delta = _deltaToTarget(
          physics: physics,
          targetIndex: result.targetIndex,
          rotation: result.endRotation,
        );

        expect(delta.abs(), lessThan(physics.segmentAngle / 2));
      }
    });
  });
}

double _deltaToTarget({
  required WheelPhysics physics,
  required int targetIndex,
  required double rotation,
}) {
  final double targetAngle = physics.angleForIndex(targetIndex);
  double delta = rotation - targetAngle;
  const double tau = 2 * pi;
  delta = ((delta + pi) % tau) - pi;
  return delta;
}
