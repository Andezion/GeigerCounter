import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geiger Joke',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const GeigerPage(),
    );
  }
}

class GeigerPage extends StatefulWidget {
  const GeigerPage({super.key});

  @override
  State<GeigerPage> createState() => _GeigerPageState();
}

class _GeigerPageState extends State<GeigerPage>
    with SingleTickerProviderStateMixin {
  String _title = 'Radiation Detector';
  bool _holding = false;
  DateTime? _holdStart;
  Timer? _tickTimer;
  Timer? _decayTimer;
  double _intensity = 0.0;
  late final AudioPlayer _player;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _decayTimer?.cancel();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_holding) return;
    _decayTimer?.cancel();
    _holding = true;
    _holdStart = DateTime.now();
    _scheduleNextTick();
    setState(() {});
  }

  void _stopHold() {
    _holding = false;
    _tickTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      setState(() {
        _intensity = max(0.0, _intensity - 0.04);
      });
      if (_intensity <= 0) {
        t.cancel();
      }
    });
    setState(() {});
  }

  void _scheduleNextTick() {
    if (!_holding) return;
    final elapsedMs = DateTime.now().difference(_holdStart!).inMilliseconds;
    _intensity = (elapsedMs / 10000).clamp(0.0, 1.0);

    final intervalMs = (800 - (740 * _intensity)).toInt().clamp(40, 1000);

    _tickTimer = Timer(Duration(milliseconds: intervalMs), () async {
      _playTick();
      if (_holding) _scheduleNextTick();
    });
    setState(() {});
  }

  Future<void> _playTick() async {
    final vol = (0.25 + 0.75 * _intensity).clamp(0.0, 1.0);

    final assetPath =
        _intensity > 0.6 ? 'audio/geiger_short.mp3' : 'audio/geiger_short.mp3';
    try {
      await _player.play(AssetSource(assetPath), volume: vol);
    } catch (e) {}

    _pulseController.forward(from: 0);
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _title);
    final res = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Edit title'),
            content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Enter new title')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(controller.text.trim()),
                  child: const Text('Save')),
            ],
          );
        });

    if (res != null && res.isNotEmpty) {
      setState(() {
        _title = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: _editTitle,
                      icon: const Icon(Icons.edit, color: Colors.white)),
                  Expanded(
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(colors: [
                          Colors.greenAccent,
                          Colors.yellow,
                          Colors.red
                        ]).createShader(rect),
                        child: Text(_title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radiation',
                          style: TextStyle(color: Colors.white70)),
                      Text('${(_intensity * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: _intensity,
                        minHeight: 14,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(Colors.limeAccent)),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                      opacity: _intensity > 0.2 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Text('CPM ~ ${(_intensity * 300).round()}',
                          style: const TextStyle(color: Colors.white60))),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: ScaleTransition(
                scale: _pulseAnim,
                child: GestureDetector(
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _stopHold(),
                  onTapCancel: () => _stopHold(),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          colors: [Colors.black, Colors.red.withOpacity(0.7)],
                          center: Alignment(-0.2, -0.4),
                          radius: 0.9),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(min(0.6, _intensity)),
                            blurRadius: 30 * _intensity,
                            spreadRadius: 4 * _intensity)
                      ],
                    ),
                    child: Center(
                      child: Text('PUSH',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
