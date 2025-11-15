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

  static const List<Color> _palette = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFFB8C00),
  ];

  Color _lighten(Color color, [double amount = 0.18]) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, [double amount = 0.18]) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double segmentAngle = 2 * pi / sectors.length;
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2;

    final double outerRim = radius;
    final double innerRim = radius * 0.94;
    final double wheelRadius = radius * 0.9;

    // Наружный металлический обод.
    final Paint rimPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFfdd835),
          const Color(0xFFc6a700),
          const Color(0xFF795548),
        ],
        stops: const <double>[0.25, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRim));
    canvas.drawCircle(center, outerRim, rimPaint);

    final Paint rimBorder = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025;
    canvas.drawCircle(center, outerRim, rimBorder);

    final Paint innerRimPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromCircle(center: center, radius: innerRim),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06;
    canvas.drawCircle(center, innerRim, innerRimPaint);

    final Rect wheelRect =
        Rect.fromCircle(center: center, radius: wheelRadius + radius * 0.08);
    final Rect wedgeRect = Rect.fromCircle(center: center, radius: wheelRadius);

    for (int i = 0; i < sectors.length; i++) {
      final WheelSector sector = sectors[i];
      final Color baseColor =
          sector.color ?? _palette[i % _palette.length];
      final Color light = _lighten(baseColor, 0.22);
      final Color dark = _darken(baseColor, 0.16);

      final double startAngle = rotation + i * segmentAngle;
      final Path segmentPath = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(wedgeRect, startAngle, segmentAngle, false)
        ..close();

      final Paint segmentPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + segmentAngle,
          colors: <Color>[light, baseColor, dark],
          stops: const <double>[0.1, 0.55, 1.0],
        ).createShader(wheelRect);
      canvas.drawPath(segmentPath, segmentPaint);

      // Подсветка по краю сектора.
      final Paint highlightPaint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.22),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: center, radius: wheelRadius * 0.98),
        );
      canvas.drawPath(segmentPath, highlightPaint);

      final Paint dividerPaint = Paint()
        ..color = Colors.black.withOpacity(0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.015
        ..strokeCap = StrokeCap.round;
      final Path dividerPath = Path()
        ..addArc(wedgeRect, startAngle, segmentAngle);
      canvas.drawPath(dividerPath, dividerPaint);

      final Paint spokePaint = Paint()
        ..color = Colors.black.withOpacity(0.32)
        ..strokeWidth = radius * 0.014
        ..strokeCap = StrokeCap.round;
      final Offset startPoint = Offset(
        center.dx + wheelRadius * cos(startAngle),
        center.dy + wheelRadius * sin(startAngle),
      );
      canvas.drawLine(center, startPoint, spokePaint);
    }

    // Декоративные болты по краю, создающие ощущение реального барабана.
    final RadialGradient studGradient = RadialGradient(
      colors: <Color>[
        Colors.white.withOpacity(0.9),
        Colors.amber.withOpacity(0.6),
        Colors.brown.withOpacity(0.4),
      ],
      stops: const <double>[0.0, 0.45, 1.0],
    );
    final Paint studBorder = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.005;

    final int studCount = sectors.length * 2;
    for (int i = 0; i < studCount; i++) {
      final double angle = rotation + i * 2 * pi / studCount;
      final Offset studCenter = Offset(
        center.dx + innerRim * cos(angle),
        center.dy + innerRim * sin(angle),
      );
      canvas.save();
      canvas.translate(studCenter.dx, studCenter.dy);
      final Paint studFill = Paint()
        ..shader = studGradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: radius * 0.03),
        );
      canvas.drawCircle(Offset.zero, radius * 0.03, studFill);
      canvas.drawCircle(Offset.zero, radius * 0.03, studBorder);
      canvas.restore();
    }

    // Внутренний диск.
    final double hubRadius = wheelRadius * 0.42;
    final Paint hubPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF263238),
          const Color(0xFF102027),
        ],
        stops: const <double>[0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    final Paint hubRidge = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromCircle(center: center, radius: hubRadius * 0.82),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = hubRadius * 0.15;
    canvas.drawCircle(center, hubRadius * 0.72, hubRidge);

    final Paint hubBorder = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = hubRadius * 0.08;
    canvas.drawCircle(center, hubRadius, hubBorder);

    final TextPainter centerText = TextPainter(
      text: const TextSpan(
        text: 'ПОЛЕ\nЧУДЕС',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 2.0,
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
      canvas.translate(0, -radius * 0.86);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sector.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            shadows: <Shadow>[
              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final double width = textPainter.width + 18;
      final double height = textPainter.height + 12;
      final RRect badge = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 0),
          width: width,
          height: height,
        ),
        const Radius.circular(10),
      );

      final Paint badgePaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(badge.outerRect);
      canvas.drawRRect(badge, badgePaint);

      final Paint badgeBorder = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawRRect(badge, badgeBorder);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
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
