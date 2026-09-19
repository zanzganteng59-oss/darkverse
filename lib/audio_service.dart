import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isEnabled = true;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('sound_enabled') ?? true;

    await _player.setLoopMode(LoopMode.one);

    if (_isEnabled) {
      await start();
    }

    _initialized = true;
  }

  Future<void> start() async {
    if (!_isEnabled || _isPlaying) return;

    await _player.setAsset('assets/sound/background.mp3');
    await _player.play();
    _isPlaying = true;
    _isPaused = false;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _isPaused = false;
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPaused = true;
  }

  Future<void> resume() async {
    if (!_isEnabled) return;

    if (_isPaused) {
      await _player.play();
      _isPaused = false;
    } else if (!_isPlaying) {
      await start();
    }
  }

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);

    if (value) {
      _isPlaying = false;
      _isPaused = false;
      await start();
    } else {
      await stop();
    }
  }

  bool get isEnabled => _isEnabled;
  bool get isPlaying => _isPlaying;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      pause();
    } else if (state == AppLifecycleState.resumed) {
      resume();
    }
  }
}
