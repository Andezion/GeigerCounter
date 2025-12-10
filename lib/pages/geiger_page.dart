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
  final List<String> _presets = [
    'Radiation Normal',
    'Radiation Elevated',
    'Radiation Hot',
    'Slayyyy Aura'
  ];
  String _selectedPreset = 'Radiation Normal';

  bool _isBarbie = false;

  bool _holding = false;
  Timer? _tickTimer;
  Timer? _decayTimer;
  double _value = 0.0;

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

    final baseBump = _baseForMode(_selectedMode);
    setState(() {
      _value += baseBump * 0.5;
    });
    _playTick();
    _scheduleNextTick();
    setState(() {});
  }

  void _stopHold() {
    _holding = false;
    _tickTimer?.cancel();

    _decayTimer = Timer.periodic(const Duration(milliseconds: 220), (t) {
      setState(() {
        _value = _value * 0.995;
        if (_value < 0.001) _value = 0.0;
      });
      if (_value <= 0) t.cancel();
    });
    setState(() {});
  }

  void _scheduleNextTick() {
    if (!_holding) return;

    final intervalMs = (800 / (1 + (_value / 50))).toInt().clamp(20, 1000);

    _tickTimer = Timer(Duration(milliseconds: intervalMs), () async {
      setState(() {
        _value += 1.0 + pow(_value + 1, 0.35) * 0.6;
      });
      await _playTick();
      if (_holding) _scheduleNextTick();
    });
    setState(() {});
  }

  Future<void> _playTick() async {
    final percept = (1 - exp(-_value / 120)).clamp(0.0, 1.0);
    final vol = (0.1 + 0.9 * percept).clamp(0.0, 1.0);

    final asset =
        _value > 150 ? 'audio/geiger_short.mp3' : 'audio/geiger_long.mp3';
    await AudioService.instance.playTick(asset, vol);
    _pulseController.forward(from: 0);
  }

  final List<String> _modes = ['Chernobyl mode', 'Slay mode'];
  String _selectedMode = 'Chernobyl mode';
      case 'Slayyyy Aura':
        return 200.0;
      case 'Radiation Normal':
      default:
        return 4.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percept = (1 - exp(-_value / 120)).clamp(0.0, 1.0);
    final bgColor =
        _isBarbie ? const Color(0xFFFFEAF0) : const Color(0xFF0A0C09);
    final buttonInner = _isBarbie
        ? [Colors.pink.shade200, Colors.pink.shade400]
        : [Colors.black, Colors.orange.shade700];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedPreset,
                    items: _presets
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (s) {
                      if (s == null) return;
                      setState(() {
                    value: _selectedMode,
                        _value = _presetBase(s);
                      });
                    },
                  ),
                  const Spacer(),
                  Row(
                        _selectedMode = s;
                        _value = _baseForMode(s);
                      Switch(
                        value: _isBarbie,
                        onChanged: (v) => setState(() => _isBarbie = v),
                        activeColor: Colors.pinkAccent,
                      ),
                      const Text('Barbie', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Text('${_value.round()}',
                      style: TextStyle(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: _isBarbie
                              ? Colors.pink.shade700
                              : Colors.black87)),
                  const SizedBox(height: 8),
                  Text(_isBarbie ? 'Slay/m²' : 'Slay/m2',
                      style: TextStyle(
                          color: _isBarbie
                              ? Colors.pink.shade300
                              : Colors.black54)),
                  const SizedBox(height: 6),
                  Text('Slayyyy aura',
                      style: TextStyle(
                          color: _isBarbie
                              ? Colors.pinkAccent
                              : Colors.green.shade700)),
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
                          colors: buttonInner,
                          center: Alignment(-0.2, -0.4),
                          radius: 0.9),
                      boxShadow: [
                        BoxShadow(
                            color: (_isBarbie
                                    ? Colors.pinkAccent
                                    : Colors.orange)
                                .withOpacity((percept * 0.8).clamp(0.05, 0.9)),
                            blurRadius: 30 * (percept * 1.2).clamp(0.05, 1.5),
                            spreadRadius: 4 * (percept).clamp(0.02, 1.2))
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
