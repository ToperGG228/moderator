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
  double _endRotation = 0;
  double _landingOffset = 0;
  double _t1 = 0.3;
  double _t2 = 0.75;
  int _currentIndex = 0;
  int _targetIndex = 0;
  bool _spinning = false;
  Completer<WheelSector>? _spinCompleter;

  double get _segmentAngle => 2 * pi / widget.sectors.length;

  double get _pointerSize => widget.size * 0.22;

  double get _baseRotation => -pi / 2 - _segmentAngle / 2;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.sectors.length;
    _targetIndex = _currentIndex;
    _landingOffset = 0;
    _rotation = _normalizeAngle(_angleForIndex(_currentIndex, _landingOffset));
    _startRotation = _rotation;
    _endRotation = _rotation;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..addListener(() {
        final double curvedValue = _profile(_controller.value);
        setState(() {
          _rotation =
              lerpDouble(_startRotation, _endRotation, curvedValue) ?? _endRotation;
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
      _landingOffset = 0;
      _rotation = _normalizeAngle(_angleForIndex(_currentIndex, _landingOffset));
      _startRotation = _rotation;
      _endRotation = _rotation;
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
    _targetIndex = _pickWeightedSectorIndex();
    _landingOffset = _randomLandingOffset();

    final int fullTurns = 4 + _random.nextInt(3); // 4–6 полных оборотов.
    final double baseAngle = _rotation;
    final double idealAngle =
        _normalizeAngle(_angleForIndex(_targetIndex, _landingOffset));

    double delta = idealAngle - baseAngle;
    while (delta <= 0) {
      delta += 2 * pi;
    }

    final double totalAngle = fullTurns * 2 * pi + delta;

    _startRotation = baseAngle;
    _endRotation = baseAngle + totalAngle;

    _configureTimings();

    _spinCompleter = Completer<WheelSector>();
    _controller.forward(from: 0);

    return _spinCompleter!.future;
  }

  void _finishSpin() {
    _currentIndex = _targetIndex % widget.sectors.length;
    _rotation =
        _normalizeAngle(_angleForIndex(_currentIndex, _landingOffset));
    _startRotation = _rotation;
    _endRotation = _rotation;

    _spinning = false;
    final WheelSector sector = widget.sectors[_currentIndex];
    try {
      widget.onSpinComplete?.call(sector);
    } finally {
      _spinCompleter?.complete(sector);
      _spinCompleter = null;
      if (mounted) {
        setState(() {});
      }
    }
  }

  double _sectorWeight(WheelSector sector) {
    switch (sector.type) {
      case SectorType.points:
        return 1.0;
      case SectorType.bonus:
      case SectorType.mystery:
      case SectorType.prize:
        return 0.6;
      case SectorType.bankrupt:
        return 1.4;
      case SectorType.doubleScore:
        return 0.9;
      case SectorType.miss:
        return 0.8;
    }
  }

  int _pickWeightedSectorIndex() {
    final List<double> weights =
        widget.sectors.map<double>(_sectorWeight).toList(growable: false);
    final double total =
        weights.fold<double>(0, (double sum, double weight) => sum + weight);
    double roll = _random.nextDouble() * total;
    for (int i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        return i;
      }
    }
    return weights.length - 1;
  }

  double _profile(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;

    const double accelProgress = 0.3;
    const double cruiseProgress = 0.85;

    if (t < _t1) {
      final double normalized = (t / _t1).clamp(0.0, 1.0);
      return accelProgress * Curves.easeInQuad.transform(normalized);
    }

    if (t < _t2) {
      final double normalized = ((t - _t1) / (_t2 - _t1)).clamp(0.0, 1.0);
      return accelProgress +
          (cruiseProgress - accelProgress) * Curves.linear.transform(normalized);
    }

    final double normalized = ((t - _t2) / (1 - _t2)).clamp(0.0, 1.0);
    return cruiseProgress +
        (1 - cruiseProgress) * Curves.easeOutCubic.transform(normalized);
  }

  double _randomLandingOffset() {
    double offset;
    do {
      offset = (_random.nextDouble() - 0.5) * _segmentAngle * 0.4;
    } while (offset.abs() < _segmentAngle * 0.05);
    return offset;
  }

  void _configureTimings() {
    const double accelSeconds = 1.5;
    final double cruiseSeconds = 0.8 + _random.nextDouble() * 2.0;
    final double decelSeconds = 0.4 + _random.nextDouble() * 1.0;
    final double total = accelSeconds + cruiseSeconds + decelSeconds;
    _t1 = accelSeconds / total;
    _t2 = (accelSeconds + cruiseSeconds) / total;
    _controller.duration = Duration(milliseconds: (total * 1000).round());
  }

  double _normalizeAngle(double angle) {
    final double tau = 2 * pi;
    double value = angle % tau;
    if (value < 0) {
      value += tau;
    }
    return value;
  }

  double _angleForIndex(int index, double offset) {
    return _baseRotation - index * _segmentAngle + offset;
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
