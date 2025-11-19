import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._internal();

  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  final AudioPlayer _fxPlayer = AudioPlayer();
  final AudioPlayer _loopPlayer = AudioPlayer();
  bool isEnabled = true;

  Future<void> _play(String fileName) async {
    if (!isEnabled) return;
    await _fxPlayer.stop();
    await _fxPlayer.setReleaseMode(ReleaseMode.stop);
    await _fxPlayer.play(AssetSource('sounds/$fileName'));
  }

  Future<void> stopWheelSpin() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
  }

  Future<void> playWrongLetter() => _play('wrong_letter.mp3');
  Future<void> playCorrectLetter() => _play('correct_letter.mp3');
  Future<void> playSpinVoice() => _play('yakubovich_spin.mp3');
  Future<void> playWheelSpin() async {
    if (!isEnabled) return;
    await _loopPlayer.stop();
    await _loopPlayer.setReleaseMode(ReleaseMode.loop);
    await _loopPlayer.play(AssetSource('sounds/wheel_spin_1995.mp3'));
  }
  Future<void> playWheelStop() => _play('wheel_stop.mp3');
  Future<void> playPrizeSector() => _play('prize_sector.mp3');
  Future<void> playBankrupt() => _play('bankrupt.mp3');
  Future<void> playWinnerFanfare() => _play('winner_fanfare.mp3');

  Future<void> playOpenThenCorrect() async {
    if (!isEnabled) return;
    await _fxPlayer.stop();
    await _fxPlayer.play(AssetSource('sounds/yakubovich_open.mp3'));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!isEnabled) return;
    await _fxPlayer.play(AssetSource('sounds/correct_letter.mp3'));
  }

  Future<void> dispose() async {
    await _fxPlayer.dispose();
    await _loopPlayer.dispose();
  }
}
