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
    this.size = 280,
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
  int _pendingExtra = 0;
  bool _spinning = false;

  double get _segmentAngle => 2 * pi / widget.sectors.length;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.sectors.length;
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
    final int extra = _random.nextInt(widget.sectors.length);
    final int fullTurns = 4 + _random.nextInt(3); // 4–6 полных оборотов.
    final double totalAngle = fullTurns * 2 * pi + extra * _segmentAngle;

    _pendingExtra = extra;
    _startRotation = _rotation;
    _targetRotation = _rotation + totalAngle;

    final Completer<WheelSector> completer = Completer<WheelSector>();

    _controller.forward(from: 0).whenComplete(() {
      final WheelSector sector = widget.sectors[_currentIndex];
      completer.complete(sector);
    });

    return completer.future;
  }

  void _finishSpin() {
    // Нормализуем угол, чтобы он не рос бесконечно.
    _rotation = _targetRotation % (2 * pi);
    _startRotation = _rotation;
    _targetRotation = _rotation;

    // Пересчитываем индекс сектора под стрелкой.
    _currentIndex = (_currentIndex - _pendingExtra) % widget.sectors.length;
    if (_currentIndex < 0) {
      _currentIndex += widget.sectors.length;
    }

    _spinning = false;
    final WheelSector sector = widget.sectors[_currentIndex];
    widget.onSpinComplete?.call(sector);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _WheelPainter(
          sectors: widget.sectors,
          rotation: _rotation,
        ),
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
      final Paint paint = Paint()
        ..color = sector.color ?? Colors.blueGrey
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final double angle = startAngle + segmentAngle / 2;
      final double textRadius = radius * 0.65;
      final Offset position = Offset(
        center.dx + cos(angle) * textRadius - textPainter.width / 2,
        center.dy + sin(angle) * textRadius - textPainter.height / 2,
      );
      textPainter.paint(canvas, position);
    }

    // Центральный круг.
    final Paint centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
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
