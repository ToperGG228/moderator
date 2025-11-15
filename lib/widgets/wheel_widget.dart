import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models.dart';

/// Виджет барабана с анимацией вращения.
class WheelWidget extends StatefulWidget {
  const WheelWidget({
    super.key,
    required this.sectors,
    this.onSpinComplete,
    this.initialIndex = 0,
    this.size = 300,
  });

  final List<WheelSector> sectors;
  final ValueChanged<WheelSector>? onSpinComplete;
  final int initialIndex;
  final double size;

  @override
  State<WheelWidget> createState() => WheelWidgetState();
}

class WheelWidgetState extends State<WheelWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();

  double _rotation = 0;
  double _startRotation = 0;
  double _targetRotation = 0;
  double _currentOffset = 0;
  double _landingOffset = 0;
  int _currentIndex = 0;
  int _targetIndex = 0;
  bool _spinning = false;
  bool _dramaticNeighbor = false;
  double _accelPortion = 0.2;
  double _cruisePortion = 0.55;
  double _decelPortion = 0.25;

  double get _segmentAngle => 2 * pi / widget.sectors.length;

  double get _pointerSize => widget.size * 0.22;

  double get _baseRotation => -pi / 2 - _segmentAngle / 2;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.sectors.length;
    _targetIndex = _currentIndex;
    _currentOffset = 0;
    _landingOffset = 0;
    _rotation = _baseRotation - _currentIndex * _segmentAngle + _currentOffset;
    _startRotation = _rotation;
    _targetRotation = _rotation;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )
      ..addListener(() {
        // Преобразуем прогресс контроллера через драматичный профиль скорости.
        final double curvedValue = _computeSpinProgress(_controller.value);
        setState(() {
          _rotation = lerpDouble(_startRotation, _targetRotation, curvedValue)!;
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _finishSpin();
        }
      });
  }

  @override
  void didUpdateWidget(covariant WheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex && !_spinning) {
      _currentIndex = widget.initialIndex % widget.sectors.length;
      _targetIndex = _currentIndex;
      _currentOffset = 0;
      _landingOffset = 0;
      _rotation = _baseRotation - _currentIndex * _segmentAngle + _currentOffset;
      _startRotation = _rotation;
      _targetRotation = _rotation;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Запускает вращение барабана и возвращает выбранный сектор.
  Future<WheelSector> spinWheel() {
    if (_spinning) {
      return Future<WheelSector>.value(widget.sectors[_currentIndex]);
    }

    _spinning = true;
    final int targetIndex = _chooseTargetIndex();
    int extra = (_currentIndex - targetIndex) % widget.sectors.length;
    if (extra <= 0) {
      extra += widget.sectors.length;
    }
    final int fullTurns = 5 + _random.nextInt(3); // 5–7 полных оборотов.

    _dramaticNeighbor = _shouldDramatize(targetIndex);
    _landingOffset = _randomLandingOffset();
    final double deltaOffset = _landingOffset - _currentOffset;
    final double totalAngle = fullTurns * 2 * pi + extra * _segmentAngle + deltaOffset;

    _targetIndex = targetIndex;
    _startRotation = _rotation;
    _targetRotation = _rotation + totalAngle;

    _configureDurations();

    final Completer<WheelSector> completer = Completer<WheelSector>();

    _controller.forward(from: 0).whenComplete(() {
      final WheelSector sector = widget.sectors[_targetIndex];
      completer.complete(sector);
    });

    return completer.future;
  }

  void _finishSpin() {
    // Пересчитываем индекс сектора под стрелкой.
    _currentIndex = _targetIndex % widget.sectors.length;

    // Нормализуем угол, чтобы он не рос бесконечно.
    _currentOffset = _landingOffset;
    _rotation = _baseRotation - _currentIndex * _segmentAngle + _currentOffset;
    _startRotation = _rotation;
    _targetRotation = _rotation;

    _spinning = false;
    _dramaticNeighbor = false;
    final WheelSector sector = widget.sectors[_currentIndex];
    widget.onSpinComplete?.call(sector);
    setState(() {});
  }

  int _chooseTargetIndex() {
    final List<double> weights = widget.sectors
        .map((WheelSector sector) => _sectorWeight(sector))
        .toList();
    final double totalWeight =
        weights.fold<double>(0, (double sum, double value) => sum + value);
    double roll = _random.nextDouble() * totalWeight;
    for (int i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        return i;
      }
    }
    return weights.length - 1;
  }

  double _sectorWeight(WheelSector sector) {
    switch (sector.type) {
      case SectorType.points:
        return 1.0;
      case SectorType.bonus:
        return 0.45;
      case SectorType.mystery:
        return 0.45;
      case SectorType.prize:
        return 0.45;
      case SectorType.bankrupt:
        return 1.5;
      case SectorType.doubleScore:
        return 0.7;
      case SectorType.miss:
        return 0.9;
    }
  }

  double _computeSpinProgress(double t) {
    final double value = _dramaticNeighbor ? _dramaticProfile(t) : _defaultProfile(t);
    return value.clamp(0.0, 1.0);
  }

  double _defaultProfile(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final double accelEnd = _accelPortion;
    final double cruiseEnd = _accelPortion + _cruisePortion;
    if (t < accelEnd) {
      final double normalized = t / accelEnd;
      return 0.2 * Curves.easeInCubic.transform(normalized);
    }
    if (t < cruiseEnd) {
      final double normalized = (t - accelEnd) / _cruisePortion;
      return 0.2 + 0.58 * Curves.linear.transform(normalized);
    }
    final double normalized = (t - cruiseEnd) / _decelPortion;
    return 0.78 + 0.22 * Curves.easeOutCubic.transform(normalized);
  }

  double _dramaticProfile(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final double accelEnd = _accelPortion;
    final double cruiseEnd = _accelPortion + _cruisePortion;
    if (t < accelEnd) {
      final double normalized = t / accelEnd;
      return 0.24 * Curves.easeInCubic.transform(normalized);
    }
    if (t < cruiseEnd) {
      final double normalized = (t - accelEnd) / _cruisePortion;
      return 0.24 + 0.52 * Curves.linear.transform(normalized);
    }
    if (t < 1 - _decelPortion * 0.35) {
      final double normalized =
          (t - cruiseEnd) / (_decelPortion * 0.65).clamp(0.0001, 1.0);
      return 0.76 + 0.16 * Curves.easeOutQuart.transform(normalized);
    }
    final double tailDuration = _decelPortion * 0.35;
    final double normalized = (t - (1 - tailDuration)) / tailDuration.clamp(0.0001, 1.0);
    return 0.92 + 0.08 * Curves.easeOutExpo.transform(normalized);
  }

  bool _shouldDramatize(int targetIndex) {
    bool isSpecial(int index) {
      final SectorType type = widget.sectors[index].type;
      return type == SectorType.bonus ||
          type == SectorType.mystery ||
          type == SectorType.prize ||
          type == SectorType.bankrupt;
    }

    if (isSpecial(targetIndex)) {
      return false;
    }

    final int length = widget.sectors.length;
    final int prev = (targetIndex - 1 + length) % length;
    final int next = (targetIndex + 1) % length;
    return isSpecial(prev) || isSpecial(next);
  }

  double _randomLandingOffset() {
    // Лёгкое смещение, чтобы стрелка не оказывалась точно на границе.
    final double span = _dramaticNeighbor ? 0.32 : 0.55;
    double value;
    do {
      value = (_random.nextDouble() - 0.5) * _segmentAngle * span;
    } while (value.abs() < _segmentAngle * 0.12);
    return value;
  }

  void _configureDurations() {
    final double accelSeconds = 1.0 + _random.nextDouble() * 0.5;
    final double cruiseSeconds = 2.0 + _random.nextDouble() * 0.5;
    final double decelSeconds = 2.0 + _random.nextDouble() * 1.25;
    final double total = accelSeconds + cruiseSeconds + decelSeconds;
    _accelPortion = accelSeconds / total;
    _cruisePortion = cruiseSeconds / total;
    _decelPortion = decelSeconds / total;
    _controller.duration = Duration(milliseconds: (total * 1000).round());
  }

  @override
  Widget build(BuildContext context) {
    final double pointerOffset = _pointerSize * 0.35;
    final double pointerHeadroom = _pointerSize * 0.18;
    return SizedBox(
      width: widget.size,
      height: widget.size + pointerOffset + pointerHeadroom,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: pointerHeadroom + pointerOffset,
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _WheelBasePainter(
                      sectors: widget.sectors,
                      rotation: _rotation,
                    ),
                    foregroundPainter: _WheelLabelPainter(
                      sectors: widget.sectors,
                      rotation: _rotation,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: pointerHeadroom - _pointerSize * 0.28,
            child: IgnorePointer(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(1.0, -1.0, 1.0),
                child: _WheelPointer(size: _pointerSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelBasePainter extends CustomPainter {
  _WheelBasePainter({required this.sectors, required this.rotation});

  final List<WheelSector> sectors;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final double segmentAngle = 2 * pi / sectors.length;
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;

    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < sectors.length; i++) {
      final WheelSector sector = sectors[i];
      final Color baseColor = sector.color ?? const Color(0xFF283593);
      final Paint paint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            baseColor.withOpacity(0.95),
            Color.alphaBlend(Colors.black.withOpacity(0.25), baseColor),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      final double startAngle = rotation + i * segmentAngle;
      canvas.drawArc(rect, startAngle, segmentAngle, true, paint);

      // Добавляем тонкую границу между секторами.
      final Paint borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, segmentAngle, true, borderPaint);
    }

    // Центральный круг.
    final Paint centerPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withOpacity(0.95),
          Colors.blueGrey.withOpacity(0.25),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.24))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, centerPaint);

    final TextPainter centerText = TextPainter(
      text: const TextSpan(
        text: 'ПОЛЕ\nЧУДЕС',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    centerText.paint(
      canvas,
      Offset(center.dx - centerText.width / 2, center.dy - centerText.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelBasePainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.sectors != sectors;
  }
}

class _WheelLabelPainter extends CustomPainter {
  _WheelLabelPainter({required this.sectors, required this.rotation});

  final List<WheelSector> sectors;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final double segmentAngle = 2 * pi / sectors.length;
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;

    for (int i = 0; i < sectors.length; i++) {
      final WheelSector sector = sectors[i];
      final double startAngle = rotation + i * segmentAngle;
      final double angle = startAngle + segmentAngle / 2;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -radius * 0.935);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sector.label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            shadows: <Shadow>[
              Shadow(color: Colors.white70, blurRadius: 12),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset textOffset = Offset(-textPainter.width / 2, -textPainter.height / 2);
      final RRect bubble = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textOffset.dx - 7,
          textOffset.dy - 5,
          textPainter.width + 14,
          textPainter.height + 10,
        ),
        const Radius.circular(7),
      );

      final Paint bubblePaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.95),
            Colors.blue.shade100.withOpacity(0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bubble.outerRect);
      canvas.drawRRect(bubble, bubblePaint);

      final Paint bubbleBorder = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(bubble, bubbleBorder);

      textPainter.paint(canvas, textOffset);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelLabelPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.sectors != sectors;
  }
}

class _WheelPointer extends StatelessWidget {
  const _WheelPointer({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final double width = size * 0.6;
    final double height = size;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PointerPainter(),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width * 0.82, size.height * 0.28)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.02,
        size.width * 0.18,
        size.height * 0.28,
      )
      ..close();

    canvas.drawShadow(path, Colors.orangeAccent.withOpacity(0.8), 16, true);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.deepOrangeAccent.shade100,
          Colors.amberAccent.shade200,
          Colors.deepOrangeAccent.shade400,
        ],
        stops: const <double>[0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, borderPaint);

    final Path innerPath = Path()
      ..moveTo(size.width / 2, size.height * 0.92)
      ..lineTo(size.width * 0.74, size.height * 0.36)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.12,
        size.width * 0.26,
        size.height * 0.36,
      );
    final Paint innerHighlight = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(innerPath, innerHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
