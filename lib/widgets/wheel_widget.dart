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
    final double haloSize = widget.size + 120;
    final double rimSize = widget.size + 52;
    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _WheelHalo(size: haloSize),
          _WheelRim(size: rimSize),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipOval(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0xFF1E1F2F),
                      Color(0xFF0F1736),
                    ],
                    radius: 0.95,
                  ),
                ),
                child: FortuneWheel(
                  selected: _selectedController.stream,
                  animateFirst: false,
                  duration: _currentDuration,
                  indicators: const <FortuneIndicator>[
                    const FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: const _WheelPointer(),
                    ),
                  ],
                  onAnimationEnd: _handleAnimationEnd,
                  items: <FortuneItem>[
                    for (int i = 0; i < widget.sectors.length; i++)
                      FortuneItem(
                        style: FortuneItemStyle(
                          color: _sectorColor(i),
                          borderColor: Colors.black.withOpacity(0.4),
                          borderWidth: 2.5,
                        ),
                        child: _WheelSectorLabel(sector: widget.sectors[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _WheelHub(size: widget.size * 0.28),
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
      Color(0xFF0D47A1),
      Color(0xFFD4AF37),
      Color(0xFF6A1B9A),
      Color(0xFF00897B),
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
            Color(0xFFFFC857),
            Color(0xFFE65100),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Поле
чудес',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
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
          width: 56,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0D132C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amberAccent, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.amberAccent.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const TriangleIndicator(
          color: Color(0xFFFFD54F),
          elevation: 8,
          width: 44,
          height: 44,
        ),
      ],
    );
  }
}

class _WheelSectorLabel extends StatelessWidget {
  const _WheelSectorLabel({required this.sector});

  final WheelSector sector;

  @override
  Widget build(BuildContext context) {
    final bool showPoints = sector.type == SectorType.points && sector.points != null;
    final TextStyle labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            sector.label,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        const SizedBox(height: 4),
        if (showPoints)
          Text(
            '+${sector.points} очков',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          )
        else
          Text(
            _subtitleForSector(sector),
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

  String _subtitleForSector(WheelSector sector) {
    switch (sector.type) {
      case SectorType.points:
        return '';
      case SectorType.bonus:
        return 'Бонус';
      case SectorType.prize:
        return 'Приз';
      case SectorType.bankrupt:
        return 'Банкрот';
      case SectorType.doubleScore:
        return 'x2';
      case SectorType.mystery:
        return 'Вопрос';
      case SectorType.miss:
        return 'Промах';
    }
  }
}
