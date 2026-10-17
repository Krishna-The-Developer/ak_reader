import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  // Continuous Loop Streams (Dedicated Audio Players)
  static final AudioPlayer _rustlePlayer = AudioPlayer();
  static final AudioPlayer _penPlayer = AudioPlayer();
  static final AudioPlayer _pencilPlayer = AudioPlayer();
  static final AudioPlayer _highlighterPlayer = AudioPlayer();
  static final AudioPlayer _eraserPlayer = AudioPlayer();

  // One-shot Impact Players
  static final AudioPlayer _woodHitPlayer = AudioPlayer();
  static final AudioPlayer _landingThumpPlayer = AudioPlayer();

  static bool _initialized = false;
  static String? _activeFrictionTool;
  static bool _isPageTouching = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure continuous loops
    for (final p in [_rustlePlayer, _penPlayer, _pencilPlayer, _highlighterPlayer, _eraserPlayer]) {
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(0.0);
    }

    await _rustlePlayer.setSource(AssetSource('audio/flip.wav'));
    await _penPlayer.setSource(AssetSource('audio/glide.wav'));
    await _pencilPlayer.setSource(AssetSource('audio/glide.wav'));
    await _highlighterPlayer.setSource(AssetSource('audio/glide.wav'));
    await _eraserPlayer.setSource(AssetSource('audio/erase.wav'));

    // Configure one-shot impacts
    await _woodHitPlayer.setReleaseMode(ReleaseMode.stop);
    await _landingThumpPlayer.setReleaseMode(ReleaseMode.stop);
    await _woodHitPlayer.setSource(AssetSource('audio/wood_tap.wav'));
    await _landingThumpPlayer.setSource(AssetSource('audio/thud.wav'));
  }

  // ================= 1. PAGE FLIP RUSTLE (CONTINUOUS) =================
  /// Called exactly on touch down on page
  static void onPageTouchDown() {
    init();
    _isPageTouching = true;
    _rustlePlayer.setVolume(0.0);
    _rustlePlayer.resume();
  }

  /// Called every frame of touch movement
  static void onPageTouchMove(double velocityNorm) {
    if (!_isPageTouching) return;
    // If finger is stationary on screen, velocity is 0 -> Volume is 0
    final double gain = (velocityNorm.abs() * 0.9).clamp(0.0, 1.0);
    final double pitch = (0.85 + 0.35 * velocityNorm.abs()).clamp(0.75, 1.35);
    _rustlePlayer.setVolume(gain);
    _rustlePlayer.setPlaybackRate(pitch);
  }

  /// Called the EXACT millisecond hand lifts from page (0ms cut)
  static void onPageTouchUp() {
    _isPageTouching = false;
    _rustlePlayer.setVolume(0.0);
    _rustlePlayer.pause();
  }

  // ================= 2. PAGE LANDING (ONE-SHOT EVENT) =================
  /// Called only when page physically hits resting stack (Theta = pi)
  static void triggerLandingThump() {
    init();
    _landingThumpPlayer.stop();
    _landingThumpPlayer.setVolume(1.0);
    _landingThumpPlayer.play(AssetSource('audio/thud.wav'));
  }

  // ================= 3. WOOD IMPACT (ONE-SHOT EVENT) =================
  /// Called only on pointer contact with desk
  static void triggerWoodKnock() {
    init();
    _woodHitPlayer.stop();
    _woodHitPlayer.setVolume(0.95);
    _woodHitPlayer.play(AssetSource('audio/wood_tap.wav'));
  }

  // ================= 4. WRITING / ERASING (CONTINUOUS FRICTION) =================
  /// Called the exact millisecond stylus/finger touches canvas
  static void onWritingTouchDown(String tool) {
    init();
    _activeFrictionTool = tool;
    final AudioPlayer target = _getPlayerForTool(tool);
    target.setVolume(0.0);
    target.resume();
  }

  /// Called per motion frame: velocity 0 = total silence
  static void onWritingTouchMove(double velocityNorm) {
    if (_activeFrictionTool == null) return;
    final AudioPlayer target = _getPlayerForTool(_activeFrictionTool!);

    // Volume directly governed by hand movement
    final double gain = (velocityNorm * 0.95).clamp(0.0, 1.0);
    final double pitch = (0.90 + 0.30 * velocityNorm).clamp(0.80, 1.40);

    target.setVolume(gain);
    target.setPlaybackRate(pitch);
  }

  /// Called the exact millisecond pen lifts from screen (0ms silence)
  static void onWritingTouchUp() {
    if (_activeFrictionTool == null) return;
    final AudioPlayer target = _getPlayerForTool(_activeFrictionTool!);
    target.setVolume(0.0);
    target.pause();
    _activeFrictionTool = null;
  }

  static AudioPlayer _getPlayerForTool(String tool) {
    switch (tool) {
      case "pen":
        return _penPlayer;
      case "pencil":
        return _pencilPlayer;
      case "highlighter":
        return _highlighterPlayer;
      case "eraser":
        return _eraserPlayer;
      default:
        return _penPlayer;
    }
  }

  // Backward-compatible aliases
  static void playWoodTap() => triggerWoodKnock();
  static void playBookOpenThud() => triggerLandingThump();
  static void playPageTurn() => onPageTouchDown();
  static void playToolGlide() {
    onWritingTouchDown("pen");
    Future.delayed(const Duration(milliseconds: 300), () => onWritingTouchUp());
  }
  static void playEraserRub() {
    onWritingTouchDown("eraser");
    Future.delayed(const Duration(milliseconds: 300), () => onWritingTouchUp());
  }

}
