import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../models.dart';

/// Виджет барабана, построенный на FortuneWheel.
class WheelWidget extends StatefulWidget {
  const WheelWidget({
    super.key,
    required this.sectors,
    this.onSpinComplete,
    this.initialIndex = 0,
    this.size = 320,
  });

  final List<WheelSector> sectors;
  final ValueChanged<WheelSector>? onSpinComplete;
  final int initialIndex;
  final double size;

  @override
  State<WheelWidget> createState() => WheelWidgetState();
}

class WheelWidgetState extends State<WheelWidget> {
  final StreamController<int> _selectedController =
      StreamController<int>.broadcast();
  final Random _random = Random();
  Completer<WheelSector>? _spinCompleter;

  int _currentIndex = 0;
  bool _isSpinning = false;
  Duration _currentDuration = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.sectors.length;
    _pushIdleIndex();
  }

  @override
  void didUpdateWidget(covariant WheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sectors.length != oldWidget.sectors.length) {
      _currentIndex = _currentIndex % widget.sectors.length;
      if (!_isSpinning) {
        _pushIdleIndex();
      }
    } else if (!_isSpinning && widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = widget.initialIndex % widget.sectors.length;
      _pushIdleIndex();
    }
  }

  @override
  void dispose() {
    _selectedController.close();
    super.dispose();
  }

  Future<WheelSector> spinWheel() {
    if (_isSpinning) {
      return _spinCompleter?.future ??
          Future<WheelSector>.value(widget.sectors[_currentIndex]);
    }

    final Completer<WheelSector> completer = Completer<WheelSector>();
    _spinCompleter = completer;
    _isSpinning = true;

    final int targetIndex = _pickWeightedSectorIndex(widget.sectors, _random);
    _currentIndex = targetIndex;
    _currentDuration = _generateDuration();
    _selectedController.add(targetIndex);
    setState(() {});

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final double haloSize = widget.size + 140;
    final double rimSize = widget.size + 90;
    final double innerGlowSize = widget.size + 32;
    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _WheelHalo(size: haloSize),
          _WheelRim(size: rimSize),
          _WheelStuds(size: rimSize - 12),
          Container(
            width: innerGlowSize,
            height: innerGlowSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Color(0xFF2E2E52),
                  Color(0xFF111427),
                ],
                radius: 0.85,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipOval(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF0B1330),
                      Color(0xFF01030C),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: FortuneWheel(
                  selected: _selectedController.stream,
                  animateFirst: false,
                  duration: _currentDuration,
                  physics: const NoPanPhysics(),
                  indicators: const <FortuneIndicator>[
                    FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: SizedBox.shrink(),
                    ),
                  ],
                  onAnimationEnd: _handleAnimationEnd,
                  items: <FortuneItem>[
                    for (int i = 0; i < widget.sectors.length; i++)
                      FortuneItem(
                        style: FortuneItemStyle(
                          color: _sectorColor(i),
                          borderColor: Colors.black.withOpacity(0.45),
                          borderWidth: 2.4,
                        ),
                        child: _WheelSectorLabel(
                          sector: widget.sectors[i],
                          isEven: i.isEven,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: const _WheelPointer(),
            ),
          ),
          _WheelHub(size: widget.size * 0.33),
        ],
      ),
    );
  }

  void _handleAnimationEnd() {
    if (_spinCompleter == null) {
      return;
    }
    _isSpinning = false;
    final WheelSector sector = widget.sectors[_currentIndex];
    widget.onSpinComplete?.call(sector);
    _spinCompleter?.complete(sector);
    _spinCompleter = null;
  }

  void _pushIdleIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_selectedController.isClosed) {
        _selectedController.add(_currentIndex);
      }
    });
  }

  Duration _generateDuration() {
    final double accel = 1.5;
    final double cruise = 0.8 + _random.nextDouble() * 2.0;
    final double decel = 0.4 + _random.nextDouble() * 1.0;
    final double total = accel + cruise + decel;
    return Duration(milliseconds: (total * 1000).round());
  }

  int _pickWeightedSectorIndex(List<WheelSector> sectors, Random rng) {
    final List<double> weights =
        sectors.map<double>(_sectorWeight).toList(growable: false);
    final double total =
        weights.fold<double>(0, (double sum, double weight) => sum + weight);
    double roll = rng.nextDouble() * total;
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
      case SectorType.mystery:
      case SectorType.prize:
        return 0.25;
      case SectorType.bankrupt:
        return 0.5;
      case SectorType.doubleScore:
        return 0.6;
      case SectorType.miss:
        return 0.8;
    }
  }

  Color _sectorColor(int index) {
    final WheelSector sector = widget.sectors[index];
    const List<Color> palette = <Color>[
      Color(0xFF6FB1FF),
      Color(0xFFF0C16B),
      Color(0xFF8C7BFF),
      Color(0xFF66D2B5),
      Color(0xFF81C4FF),
      Color(0xFFED92C7),
      Color(0xFF9DE18A),
      Color(0xFFF6A86F),
    ];
    return sector.color ?? palette[index % palette.length];
  }
}

class _WheelHalo extends StatelessWidget {
  const _WheelHalo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            Color(0x331D7CFF),
            Color(0x11060A2B),
          ],
          radius: 0.8,
        ),
      ),
    );
  }
}

class _WheelRim extends StatelessWidget {
  const _WheelRim({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF424B8E),
            Color(0xFF10152C),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _WheelHub extends StatelessWidget {
  const _WheelHub({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF272B40),
            Color(0xFF0E111D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 28,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFF4A556C),
              Color(0xFF1E2533),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.black.withOpacity(0.4), width: 2),
        ),
        child: const Center(
          child: Text(
            'ПОЛЕ\nЧУДЕС',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelPointer extends StatelessWidget {
  const _WheelPointer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 84,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFFFFF4CE),
                Color(0xFFFFC94A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFE082), width: 2),
          ),
        ),
        ClipPath(
          clipper: _PointerClipper(),
          child: Container(
            width: 38,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFFFFF4CE),
                  Color(0xFFFFA726),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Container(
          width: 12,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFFFA000),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _PointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WheelSectorLabel extends StatelessWidget {
  const _WheelSectorLabel({required this.sector, required this.isEven});

  final WheelSector sector;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final bool isPoints = sector.type == SectorType.points && sector.points != null;
    final TextStyle labelStyle = TextStyle(
      color: Colors.white,
      fontSize: isPoints ? 20 : 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      shadows: const <Shadow>[
        Shadow(offset: Offset(0, 2), blurRadius: 3, color: Colors.black54),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEven
                  ? const <Color>[Color(0xFF1E243D), Color(0xFF0D101E)]
                  : const <Color>[Color(0xFF353C5B), Color(0xFF131629)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            sector.label,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitleForSector(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _subtitleForSector() {
    if (sector.type == SectorType.points && sector.points != null) {
      return '${sector.points} очков';
    }
    switch (sector.type) {
      case SectorType.points:
        return '';
      case SectorType.bonus:
        return 'бонус';
      case SectorType.prize:
        return 'приз';
      case SectorType.bankrupt:
        return 'банкрот';
      case SectorType.doubleScore:
        return 'x2';
      case SectorType.mystery:
        return 'секрет';
      case SectorType.miss:
        return 'промах';
    }
  }
}

class _WheelStuds extends StatelessWidget {
  const _WheelStuds({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    const int dotCount = 28;
    final double radius = size / 2;
    final double dotRadius = 6;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < dotCount; i++)
            Positioned(
              left: radius + (radius - 16) * cos(2 * pi * i / dotCount) - dotRadius,
              top: radius + (radius - 16) * sin(2 * pi * i / dotCount) - dotRadius,
              child: Container(
                width: dotRadius * 2,
                height: dotRadius * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFFFFECB3),
                      Color(0xFFC57F1D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
