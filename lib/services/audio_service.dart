import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final List<AudioPlayer> _players = [];
  int _next = 0;

  Future<void> init({int pool = 3}) async {
    if (_players.isNotEmpty) return;
    for (var i = 0; i < pool; i++) {
      final p = AudioPlayer();
      _players.add(p);
    }
  }

  Future<void> preload(String assetPath) async {
    for (final p in _players) {
      try {
        await p.setSource(AssetSource(assetPath));
        await p.setVolume(0.0);
        await p.seek(Duration.zero);
      } catch (_) {}
    }
  }

  Future<void> playTick(String assetPath, double volume) async {
    if (_players.isEmpty) await init();
    final player = _players[_next % _players.length];
    _next++;
    try {
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath), volume: volume);
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
