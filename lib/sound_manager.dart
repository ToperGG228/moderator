import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  bool enabled = true;

  final AudioPlayer _loopPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  Future<void> playWrongLetter() async {
    await _playOneShot('sounds/wrong_letter.mp3');
  }

  Future<void> playSpinVoice() async {
    await _playWithPlayer(_voicePlayer, 'sounds/yakubovich_spin.mp3');
  }

  Future<void> playWheelSpin() async {
    if (!enabled) return;
    try {
      await _loopPlayer.stop();
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer.setSourceAsset('sounds/wheel_spin_1995.mp3');
      await _loopPlayer.resume();
    } catch (_) {}
  }

  Future<void> stopWheelSpin() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
  }

  Future<void> playOpenThenCorrect() async {
    if (!enabled) return;
    try {
      await _playWithPlayer(_voicePlayer, 'sounds/yakubovich_open.mp3');
      await Future.delayed(const Duration(milliseconds: 1500));
      await _playWithPlayer(_effectPlayer, 'sounds/correct_letter.mp3');
    } catch (_) {}
  }

  Future<void> playPrizeSector() async {
    await _playOneShot('sounds/prize_sector.mp3');
  }

  Future<void> playBankrupt() async {
    await _playOneShot('sounds/bankrupt.mp3');
  }

  Future<void> playWinnerFanfare() async {
    await _playOneShot('sounds/winner_fanfare.mp3');
  }

  Future<void> _playOneShot(String asset) async {
    await _playWithPlayer(_effectPlayer, asset);
  }

  Future<void> _playWithPlayer(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSourceAsset(asset);
      await player.resume();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _loopPlayer.dispose();
    await _voicePlayer.dispose();
    await _effectPlayer.dispose();
  }
}
