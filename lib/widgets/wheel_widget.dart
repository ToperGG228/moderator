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
  int _currentIndex = 0;
  int _targetIndex = 0;
  bool _spinning = false;

  double get _segmentAngle => 2 * pi / widget.sectors.length;

  double get _pointerSize => widget.size * 0.22;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.sectors.length;
    _targetIndex = _currentIndex;
    _rotation = -_currentIndex * _segmentAngle;
    _startRotation = _rotation;
    _targetRotation = _rotation;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))
      ..addListener(() {
        // Преобразуем прогресс контроллера через плавную кривую.
        final double curvedValue = Curves.easeOutCubic.transform(_controller.value);
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
      _rotation = -_currentIndex * _segmentAngle;
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
    final int fullTurns = 4 + _random.nextInt(3); // 4–6 полных оборотов.
    final double totalAngle = fullTurns * 2 * pi + extra * _segmentAngle;

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
    _rotation = -_currentIndex * _segmentAngle;
    _startRotation = _rotation;
    _targetRotation = _rotation;

    _spinning = false;
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
        return 0.6;
      case SectorType.mystery:
        return 0.6;
      case SectorType.prize:
        return 0.6;
      case SectorType.bankrupt:
        return 1.45;
      case SectorType.doubleScore:
        return 0.7;
      case SectorType.miss:
        return 0.6;
    }
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
            top: 0,
            child: _WheelPointer(size: _pointerSize),
          ),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
      )..layout();
      final double angle = startAngle + segmentAngle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -radius * 0.78);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
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
        color: Colors.transparent,
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
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.amberAccent.shade200,
          Colors.orangeAccent.shade200,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, size.height * 0.25)
      ..quadraticBezierTo(
        size.width / 2,
        0,
        0,
        size.height * 0.25,
      )
      ..close();

    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
