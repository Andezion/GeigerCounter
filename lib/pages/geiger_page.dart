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
  final List<String> _modes = ['Chernobyl mode', 'Slay mode'];
  String _selectedMode = 'Chernobyl mode';

  bool _holding = false;
  bool _decaying = false;
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

    AudioService.instance.preload('assets/audio/geiger_short.mp3');
    AudioService.instance.preload('assets/audio/geiger_long.mp3');
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _decayTimer?.cancel();
    _pulseController.dispose();
    AudioService.instance.dispose();
    super.dispose();
  }

  double _baseForMode(String mode) {
    switch (mode) {
      case 'Slay mode':
        return 120.0;
      case 'Chernobyl mode':
      default:
        return 6.0;
    }
  }

  void _startHold() {
    if (_holding) return;
    _decayTimer?.cancel();
    _holding = true;

    final base = _baseForMode(_selectedMode);
    setState(() {
      // modest immediate bump on start
      _value += base * 0.5;
    });

    _playTick();
    _scheduleNextTick();
  }

  void _stopHold() {
    if (!_holding) return;
    _holding = false;
    _tickTimer?.cancel();

    _decaying = true;
    _scheduleDecayTick();
  }

  void _scheduleDecayTick() {
    if (!_decaying) return;

    // make decay noticeably faster than growth: shorter intervals and stronger multiplier
    final intervalMs = (300 / (1 + (_value / 30))).toInt().clamp(12, 700);
    final decayMultiplier = 0.70;

    _tickTimer = Timer(Duration(milliseconds: intervalMs), () async {
      setState(() {
        _value = _value * decayMultiplier;
        if (_value < 0.01) _value = 0.0;
      });

      if (_value > 0) await _playTick();

      if (_value <= 0.0) {
        _decaying = false;
        _tickTimer?.cancel();
      } else {
        _scheduleDecayTick();
      }
    });
  }

  void _scheduleNextTick() {
    if (!_holding) return;

    final intervalMs = (520 / (1 + (_value / 60))).toInt().clamp(18, 900);

    _tickTimer = Timer(Duration(milliseconds: intervalMs), () async {
      setState(() {
        _value += 0.9 + pow(_value + 1, 0.32) * 0.45;
      });
      await _playTick();
      if (_holding) _scheduleNextTick();
    });
  }

  Future<void> _playTick() async {
    final percept = (1 - exp(-_value / 140)).clamp(0.0, 1.0);
    final vol = (0.12 + 0.88 * percept).clamp(0.0, 1.0);

    await AudioService.instance.playTick('assets/audio/geiger_short.mp3', vol);
    _pulseController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isSlay = _selectedMode == 'Slay mode';

    final bgColor = isSlay ? const Color(0xFFFFEEF4) : const Color(0xFF2F2A1F);
    final titleGradient = isSlay
        ? const LinearGradient(colors: [Color(0xFFEF9ABF), Color(0xFFFFC6DD)])
        : const LinearGradient(colors: [Color(0xFF6B8B3A), Color(0xFFD4A017)]);
    final buttonInner = isSlay
        ? [Colors.pink.shade200, Colors.pink.shade400]
        : [const Color(0xFF3E2F1B), const Color(0xFF7A9B3A)];

    final percept = (1 - exp(-_value / 140)).clamp(0.0, 1.0);

    final leftEmoji = isSlay ? '🎀' : '☢️';
    final rightEmoji = leftEmoji;

    final unit = isSlay ? 'Slay/m²' : 'µSv/h';
    final subtitle = isSlay ? 'Slayyyy aura' : 'Chernobyl detector';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSlay ? Colors.pink.shade50 : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSlay ? Colors.pink.shade200 : Colors.white30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMode,
                      items: _modes
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: TextStyle(
                                    color: isSlay
                                        ? Colors.pink.shade800
                                        : Colors.white),
                              )))
                          .toList(),
                      onChanged: (s) {
                        if (s == null) return;
                        setState(() {
                          _selectedMode = s;
                          _value = _baseForMode(s);
                        });
                      },
                      dropdownColor: bgColor,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSlay ? Colors.pink.shade800 : Colors.white),
                      iconEnabledColor:
                          isSlay ? Colors.pink.shade600 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (rect) => titleGradient.createShader(rect),
                  child: Text(
                    '$leftEmoji  ${_selectedMode.toUpperCase()}  $rightEmoji',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isSlay ? Colors.white : Colors.black,
                      shadows: isSlay
                          ? [
                              const Shadow(
                                  color: Colors.pinkAccent, blurRadius: 8)
                            ]
                          : [
                              const Shadow(color: Colors.black45, blurRadius: 6)
                            ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    '${_value.round()}',
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      color: isSlay
                          ? Colors.pink.shade700
                          : Colors.yellow.shade100,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(unit,
                      style: TextStyle(
                          color: isSlay
                              ? Colors.pink.shade300
                              : Colors.yellow.shade200,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: isSlay
                              ? Colors.pinkAccent
                              : Colors.green.shade200)),
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
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          colors: buttonInner,
                          center: const Alignment(-0.2, -0.4),
                          radius: 0.9),
                      boxShadow: [
                        BoxShadow(
                            color: (isSlay ? Colors.pinkAccent : Colors.orange)
                                .withOpacity(
                                    (percept * 0.85).clamp(0.05, 0.95)),
                            blurRadius: 30 * (percept * 1.2).clamp(0.05, 1.8),
                            spreadRadius: 6 * (percept).clamp(0.02, 1.5))
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PUSH',
                              style: TextStyle(
                                  color: isSlay ? Colors.white : Colors.black87,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4)),
                          const SizedBox(height: 6),
                          Text('(hold)',
                              style: TextStyle(
                                  color: isSlay
                                      ? Colors.white70
                                      : Colors.black54)),
                        ],
                      ),
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
