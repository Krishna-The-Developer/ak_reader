import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer()..setVolume(1.0);

  static Future<void> init() async {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<void> playBookOpenThud() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/thud.wav'));
    } catch (_) {}
  }

  static Future<void> playPageTurn() async {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/flip.wav'));
    } catch (_) {}
  }

  static Future<void> playToolGlide() async {
    HapticFeedback.selectionClick();
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/glide.wav'));
    } catch (_) {}
  }

  static Future<void> playEraserRub() async {
    HapticFeedback.mediumImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/erase.wav'));
    } catch (_) {}
  }
}
