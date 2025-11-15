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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FortuneWheel(
        selected: _selectedController.stream,
        animateFirst: false,
        indicators: const <FortuneIndicator>[
          FortuneIndicator(
            alignment: Alignment.topCenter,
            child: TriangleIndicator(
              color: Color(0xFFFFD54F),
              elevation: 6,
              width: 38,
              height: 38,
            ),
          ),
        ],
        duration: _currentDuration,
        onAnimationEnd: _handleAnimationEnd,
        items: <FortuneItem>[
          for (int i = 0; i < widget.sectors.length; i++)
            FortuneItem(
              style: FortuneItemStyle(
                color: _sectorColor(i),
                borderColor: Colors.black.withOpacity(0.35),
                borderWidth: 3,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(widget.sectors[i].label, textAlign: TextAlign.center),
              ),
            ),
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
