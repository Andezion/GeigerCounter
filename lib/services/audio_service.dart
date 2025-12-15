import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final List<AudioPlayer> _players = [];
  int _next = 0;

  Future<void> init({int pool = 6}) async {
    if (_players.isNotEmpty) return;
    for (var i = 0; i < pool; i++) {
      final p = AudioPlayer();
      _players.add(p);
    }
  }

  Future<void> preload(String assetPath) async {
    var path = assetPath;
    if (path.startsWith('assets/')) path = path.substring('assets/'.length);
    for (final p in _players) {
      try {
        await p.setSource(AssetSource(path));
        await p.setVolume(0.0);
        await p.seek(Duration.zero);
      } catch (e) {
        if (kDebugMode) {
          print('AudioService.preload failed for $path: $e');
        }
      }
    }
  }

  Future<void> playTick(String assetPath, double volume) async {
    if (_players.isEmpty) await init();
    final player = _players[_next % _players.length];
    _next++;
    try {
      var path = assetPath;
      if (path.startsWith('assets/')) path = path.substring('assets/'.length);
      await player.setVolume(volume);
      await player.play(AssetSource(path), volume: volume);
    } catch (_) {}
  }

  Future<void> playTickWithRate(String assetPath, double volume,
      {double? rate}) async {
    if (_players.isEmpty) await init();
    final player = _players[_next % _players.length];
    _next++;
    try {
      var path = assetPath;
      if (path.startsWith('assets/')) path = path.substring('assets/'.length);
      if (rate != null) {
        try {
          await player.setPlaybackRate(rate);
        } catch (_) {}
      }
      await player.setVolume(volume);
      await player.play(AssetSource(path), volume: volume);
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
