import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._internal();

  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool isEnabled = true;

  Future<void> _play(String fileName) async {
    if (!isEnabled) return;
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(AssetSource('sounds/$fileName'));
  }

  Future<void> stopWheelSpin() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> playWrongLetter() => _play('wrong_letter.mp3');
  Future<void> playCorrectLetter() => _play('correct_letter.mp3');
  Future<void> playSpinVoice() => _play('yakubovich_spin.mp3');
  Future<void> playWheelSpin() => _play('wheel_spin_1995.mp3');
  Future<void> playWheelStop() => _play('wheel_stop.mp3');
  Future<void> playPrizeSector() => _play('prize_sector.mp3');
  Future<void> playBankrupt() => _play('bankrupt.mp3');
  Future<void> playWinnerFanfare() => _play('winner_fanfare.mp3');

  Future<void> playOpenThenCorrect() async {
    if (!isEnabled) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/yakubovich_open.mp3'));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!isEnabled) return;
    await _player.play(AssetSource('sounds/correct_letter.mp3'));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
