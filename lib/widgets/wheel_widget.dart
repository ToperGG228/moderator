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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 6200))
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
    if (t < 0.24) {
      final double normalized = t / 0.24;
      return 0.38 * Curves.easeInExpo.transform(normalized);
    }
    if (t < 0.82) {
      final double normalized = (t - 0.24) / 0.58;
      return 0.38 + 0.48 * Curves.linear.transform(normalized);
    }
    final double normalized = (t - 0.82) / 0.18;
    return 0.86 + 0.14 * Curves.easeOutQuint.transform(normalized);
  }

  double _dramaticProfile(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    if (t < 0.26) {
      final double normalized = t / 0.26;
      return 0.32 * Curves.easeInExpo.transform(normalized);
    }
    if (t < 0.7) {
      final double normalized = (t - 0.26) / 0.44;
      return 0.32 + 0.42 * Curves.linear.transform(normalized);
    }
    if (t < 0.9) {
      final double normalized = (t - 0.7) / 0.2;
      return 0.74 + 0.18 * Curves.easeOutCubic.transform(normalized);
    }
    final double normalized = (t - 0.9) / 0.1;
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

  @override
  Widget build(BuildContext context) {
    final double pointerOffset = _pointerSize * 0.35;
    return SizedBox(
      width: widget.size,
      height: widget.size + pointerOffset,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: pointerOffset,
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
                    painter: _WheelPainter(
                      sectors: widget.sectors,
                      rotation: _rotation,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              child: _WheelPointer(size: _pointerSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.sectors, required this.rotation});

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

      // Рисуем подписи секторов.
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sector.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            shadows: <Shadow>[
              Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final double angle = startAngle + segmentAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -radius * 0.93);
      final Offset textOffset = Offset(-textPainter.width / 2, -textPainter.height / 2);
      final RRect bubble = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textOffset.dx - 6,
          textOffset.dy - 4,
          textPainter.width + 12,
          textPainter.height + 8,
        ),
        const Radius.circular(6),
      );
      final Paint bubblePaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.black.withOpacity(0.65),
            Colors.indigo.withOpacity(0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bubble.outerRect);
      canvas.drawRRect(bubble, bubblePaint);
      textPainter.paint(canvas, textOffset);
      canvas.restore();
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
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.amberAccent.withOpacity(0.32),
            Colors.deepOrangeAccent.withOpacity(0.12),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.amberAccent.withOpacity(0.6),
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
      ),
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
      ..lineTo(size.width, size.height * 0.28)
      ..quadraticBezierTo(
        size.width / 2,
        0,
        0,
        size.height * 0.28,
      )
      ..close();

    canvas.drawShadow(path, Colors.amberAccent.withOpacity(0.9), 14, true);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.amberAccent.shade100,
          Colors.deepOrangeAccent.shade200,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withOpacity(0.95),
          Colors.amber.shade200,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, borderPaint);

    final Paint innerHighlight = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Path innerPath = Path()
      ..moveTo(size.width / 2, size.height * 0.92)
      ..lineTo(size.width * 0.82, size.height * 0.34)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.08,
        size.width * 0.18,
        size.height * 0.34,
      );
    canvas.drawPath(innerPath, innerHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
