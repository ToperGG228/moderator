import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

class WheelWidget extends StatefulWidget {
  const WheelWidget({
    super.key,
    required this.sectors,
    required this.stream,
    required this.size,
    required this.isSpinning,
    required this.onAnimationEnd,
  });

  final List<WheelSector> sectors;
  final Stream<int> stream;
  final double size;
  final bool isSpinning;
  final VoidCallback onAnimationEnd;

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  StreamSubscription<int>? _subscription;
  double _rotation = 0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.addStatusListener(_handleAnimationStatus);
    _subscribeToStream(widget.stream);
  }

  @override
  void didUpdateWidget(covariant WheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _subscribeToStream(widget.stream);
    }
  }

  void _subscribeToStream(Stream<int> stream) {
    _subscription?.cancel();
    _subscription = stream.listen(_handleSpin);
  }

  void _handleSpin(int index) {
    if (widget.sectors.isEmpty) return;
    if (_controller.isAnimating) {
      _controller.stop();
      _rotation = _animation.value;
    }
    final double sectorAngle = (2 * math.pi) / widget.sectors.length;
    final double twoPi = 2 * math.pi;
    final double currentRotation = _rotation;
    double currentMod = currentRotation % twoPi;
    if (currentMod < 0) currentMod += twoPi;

    double targetMod = (-index * sectorAngle) - (sectorAngle / 2);
    final double jitter = (_random.nextDouble() - 0.5) * (sectorAngle * 0.3);
    targetMod = (targetMod + jitter) % twoPi;
    if (targetMod < 0) targetMod += twoPi;

    double delta = targetMod - currentMod;
    if (delta <= 0) {
      delta += twoPi;
    }

    const double extraSpins = 2 * math.pi * 4;
    final double targetRotation = currentRotation + extraSpins + delta;

    _animation = Tween<double>(begin: currentRotation, end: targetRotation)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _controller.forward(from: 0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _rotation = _animation.value;
      });
      widget.onAnimationEnd();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rotation =
            _controller.isAnimating ? _animation.value : _rotation;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _WheelPainter(
                  sectors: widget.sectors,
                  rotation: rotation,
                ),
              ),
              if (widget.isSpinning)
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Вращаем...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.sectors, required this.rotation});

  final List<WheelSector> sectors;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;

    _drawGlow(canvas, center, radius);
    final double rimOuter = radius * 0.96;
    final double rimInner = radius * 0.82;
    _drawRim(canvas, center, rimOuter, rimInner);
    _drawBolts(canvas, center, rimOuter);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    _drawSectors(canvas, center, rimInner);
    canvas.restore();

    _drawHub(canvas, center, radius);
    _drawArrow(canvas, center, radius);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final Paint glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0B0F2B), Color(0xFF1B2348)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);
  }

  void _drawRim(Canvas canvas, Offset center, double rimOuter, double rimInner) {
    final Paint rimPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFB07932),
          Color(0xFFE5B15A),
          Color(0xFFB07932),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rimOuter));
    canvas.drawCircle(center, rimOuter, rimPaint);

    final Paint rimHolePaint = Paint()..color = const Color(0xFF1B223C);
    canvas.drawCircle(center, rimInner, rimHolePaint);
  }

  void _drawBolts(Canvas canvas, Offset center, double rimOuter) {
    const int boltCount = 16;
    const double boltRadius = 6;
    final Paint boltShadow = Paint()
      ..color = Colors.black.withOpacity(0.4);
    final Paint boltPaint = Paint()
      ..color = Colors.white.withOpacity(0.85);

    for (int i = 0; i < boltCount; i++) {
      final double angle = (2 * math.pi / boltCount) * i - math.pi / 2;
      final Offset boltCenter = center + Offset(
        math.cos(angle) * (rimOuter - 10),
        math.sin(angle) * (rimOuter - 10),
      );
      canvas.drawCircle(boltCenter.translate(1.5, 1.5), boltRadius, boltShadow);
      canvas.drawCircle(boltCenter, boltRadius, boltPaint);
    }
  }

  void _drawSectors(Canvas canvas, Offset center, double rimInner) {
    if (sectors.isEmpty) {
      return;
    }
    final double sweep = (2 * math.pi) / sectors.length;
    final double startAngle = -math.pi / 2;
    final double sectorRadius = rimInner * 0.98;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.6);

    for (int i = 0; i < sectors.length; i++) {
      final double start = startAngle + i * sweep;
      final Path path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: sectorRadius),
          start,
          sweep,
          false,
        )
        ..close();

      final Paint fill = Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: [
            sectors[i].color.withOpacity(0.95),
            sectors[i].color.withOpacity(0.75),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: sectorRadius),
        );

      canvas.drawPath(path, fill);
      canvas.drawPath(path, borderPaint);
      _drawSectorText(canvas, center, sectorRadius, start, sweep, sectors[i]);
    }
  }

  void _drawSectorText(
    Canvas canvas,
    Offset center,
    double radius,
    double start,
    double sweep,
    WheelSector sector,
  ) {
    final double midAngle = start + sweep / 2;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: sector.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 0.5);

    final double textRadius = radius * 0.88;
    final Offset pivot = center + Offset(
      math.cos(midAngle) * textRadius,
      math.sin(midAngle) * textRadius,
    );

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(midAngle + math.pi / 2);
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
    canvas.restore();
  }

  void _drawHub(Canvas canvas, Offset center, double radius) {
    final double hubRadius = radius * 0.3;
    final Paint hubPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF141A2F), Color(0xFF050814)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    final Paint hubBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withOpacity(0.25);
    canvas.drawCircle(center, hubRadius, hubBorder);

    final TextPainter titlePainter = TextPainter(
      text: const TextSpan(
        text: 'ПОЛЕ\nЧУДЕС',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 2,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: hubRadius * 1.6);

    titlePainter.paint(
      canvas,
      center - Offset(titlePainter.width / 2, titlePainter.height / 2),
    );
  }

  void _drawArrow(Canvas canvas, Offset center, double radius) {
    final double tipY = center.dy - radius * 0.85;
    final double baseY = center.dy - radius * 1.05;
    final Path arrowPath = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 18, baseY)
      ..lineTo(center.dx + 18, baseY)
      ..close();

    final Rect arrowRect = Rect.fromLTRB(
      center.dx - 20,
      baseY,
      center.dx + 20,
      tipY,
    );

    final Paint arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF3A0), Color(0xFFF6A623)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(arrowRect);

    canvas.drawShadow(arrowPath, Colors.black.withOpacity(0.6), 6, false);
    canvas.drawPath(arrowPath, arrowPaint);

    final Paint arrowBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.9);
    canvas.drawPath(arrowPath, arrowBorder);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.sectors != sectors ||
        oldDelegate.rotation != rotation;
  }
}
