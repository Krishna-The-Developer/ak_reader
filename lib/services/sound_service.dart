import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static AudioPlayer? _thudPlayer;
  static AudioPlayer? _flipPlayer;
  static AudioPlayer? _glidePlayer;
  static AudioPlayer? _erasePlayer;
  static AudioPlayer? _woodTapPlayer;

  static void _ensureInitialized() {
    if (_thudPlayer != null) return;
    try {
      _thudPlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setVolume(0.65);
      _flipPlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setVolume(0.58);
      _glidePlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setVolume(0.50);
      _erasePlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setVolume(0.55);
      _woodTapPlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setVolume(0.70);
    } catch (e) {
      debugPrint("[SoundService] Player creation error: $e");
    }
  }

  static Future<void> init() async {
    _ensureInitialized();
  }

  static Future<void> playWoodTap() async {
    HapticFeedback.lightImpact();
    _ensureInitialized();
    try {
      await _woodTapPlayer?.stop();
      await _woodTapPlayer?.play(AssetSource('audio/wood_tap.wav'));
    } catch (e) {
      debugPrint("[SoundService] Wood tap error: $e");
    }
  }

  static Future<void> playBookOpenThud() async {
    HapticFeedback.heavyImpact();
    _ensureInitialized();
    try {
      await _thudPlayer?.stop();
      await _thudPlayer?.play(AssetSource('audio/thud.wav'));
    } catch (e) {
      debugPrint("[SoundService] Thud error: $e");
    }
  }

  static Future<void> playPageTurn() async {
    _ensureInitialized();
    try {
      await _flipPlayer?.stop();
      await _flipPlayer?.play(AssetSource('audio/flip.wav'));
    } catch (e) {
      debugPrint("[SoundService] Flip error: $e");
    }
  }

  static Future<void> playToolGlide() async {
    HapticFeedback.selectionClick();
    _ensureInitialized();
    try {
      await _glidePlayer?.stop();
      await _glidePlayer?.play(AssetSource('audio/glide.wav'));
    } catch (e) {
      debugPrint("[SoundService] Glide error: $e");
    }
  }

  static Future<void> playEraserRub() async {
    HapticFeedback.mediumImpact();
    _ensureInitialized();
    try {
      await _erasePlayer?.stop();
      await _erasePlayer?.play(AssetSource('audio/erase.wav'));
    } catch (e) {
      debugPrint("[SoundService] Erase error: $e");
    }
  }
}
