import 'dart:math' as math;

import 'package:flutter/material.dart';

class WheelSmokeEffect extends StatefulWidget {
  const WheelSmokeEffect({
    super.key,
    required this.active,
    required this.size,
  });

  final bool active;
  final double size;

  @override
  State<WheelSmokeEffect> createState() => _WheelSmokeEffectState();
}

class _WheelSmokeEffectState extends State<WheelSmokeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  late final List<_SmokePuff> _puffs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        setState(() {});
      });
    _puffs = List.generate(12, (index) => _SmokePuff.random(_random));
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WheelSmokeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SmokePainter(
          puffs: _puffs,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _SmokePuff {
  _SmokePuff(this.angle, this.offsetStart, this.scaleStart);

  factory _SmokePuff.random(math.Random random) {
    final angle = random.nextDouble() * 2 * math.pi;
    final offsetStart = 0.3 + random.nextDouble() * 0.2;
    final scaleStart = 0.08 + random.nextDouble() * 0.06;
    return _SmokePuff(angle, offsetStart, scaleStart);
  }

  final double angle;
  final double offsetStart;
  final double scaleStart;
}

class _SmokePainter extends CustomPainter {
  _SmokePainter({required this.puffs, required this.progress});

  final List<_SmokePuff> puffs;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    for (final puff in puffs) {
      final double localProg = (progress + puff.offsetStart) % 1.0;
      final double fade = (1 - localProg).clamp(0.0, 1.0);
      final double distance = radius * (puff.offsetStart + localProg * 0.7);
      final double baseSize = radius * puff.scaleStart;
      final Offset pos = center + Offset(
        math.cos(puff.angle) * distance,
        math.sin(puff.angle) * distance,
      );

      final Paint paint = Paint()
        ..color = Colors.white.withOpacity(0.25 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawCircle(pos, baseSize * (1.2 + localProg), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmokePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.puffs != puffs;
  }
}
