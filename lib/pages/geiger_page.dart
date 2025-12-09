import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';

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

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    AudioService.instance.init();

    AudioService.instance.preload('audio/geiger_short.mp3');
    AudioService.instance.preload('audio/geiger_long.mp3');
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _decayTimer?.cancel();
    _pulseController.dispose();
    AudioService.instance.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_holding) return;
    _decayTimer?.cancel();
    _holding = true;
    _holdStart = DateTime.now();

    final elapsedMs = DateTime.now().difference(_holdStart!).inMilliseconds;
    _intensity = (elapsedMs / 10000).clamp(0.0, 1.0);
    _playTick();
    _scheduleNextTick();
    setState(() {});
  }

  void _stopHold() {
    _holding = false;
    _tickTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 140), (t) {
      setState(() {
        _intensity = max(0.0, _intensity - 0.04);
      });
      if (_intensity <= 0) t.cancel();
    });
    setState(() {});
  }

  void _scheduleNextTick() {
    if (!_holding) return;
    final elapsedMs = DateTime.now().difference(_holdStart!).inMilliseconds;
    _intensity = (elapsedMs / 10000).clamp(0.0, 1.0);

    final intervalMs =
        (800 - (780 * pow(_intensity, 0.85))).toInt().clamp(25, 1000);

    _tickTimer = Timer(Duration(milliseconds: intervalMs), () async {
      await _playTick();
      if (_holding) _scheduleNextTick();
    });
    setState(() {});
  }

  Future<void> _playTick() async {
    final vol = (0.15 + 0.85 * _intensity).clamp(0.0, 1.0);

    final asset =
        _intensity > 0.5 ? 'audio/geiger_short.mp3' : 'audio/geiger_long.mp3';
    await AudioService.instance.playTick(asset, vol);
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
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: _editTitle,
                      icon: const Icon(Icons.edit, color: Colors.black87)),
                  Expanded(
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF7CB342)])
                            .createShader(rect),
                        child: Text(_title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
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
                  Text('${(_intensity * 300).round()}',
                      style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('CPM', style: TextStyle(color: Colors.black54)),
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
                          colors: [Colors.white, Colors.orange.shade300],
                          center: Alignment(-0.2, -0.4),
                          radius: 0.9),
                      boxShadow: [
                        BoxShadow(
                            color:
                                Colors.orange.withOpacity(min(0.6, _intensity)),
                            blurRadius: 30 * _intensity,
                            spreadRadius: 4 * _intensity)
                      ],
                    ),
                    child: Center(
                        child: Text('PUSH',
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4))),
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
