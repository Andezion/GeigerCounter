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
  final List<String> _modes = ['Chernobyl mode', 'Slay mode', 'Freak mode'];
  String _selectedMode = 'Chernobyl mode';

  bool _holding = false;
  Timer? _tickTimer;
  Timer? _decayTimer;
  double _value = 0.0;
  bool _tickScheduled = false;

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
        return 0.0;
      case 'Freak mode':
        return 0.0;
      case 'Chernobyl mode':
      default:
        return 0.0;
    }
  }

  void _startHold() {
    if (_holding) return;
    _decayTimer?.cancel();
    _holding = true;

    _tickTimer?.cancel();
    _tickScheduled = false;
    _scheduleHoldTick();
  }

  void _stopHold() {
    if (!_holding) return;
    _holding = false;
    _tickTimer?.cancel();
    _decayTimer?.cancel();
    _scheduleDecayTick();
  }

  Future<void> _playTick() async {
    final percept = (1 - exp(-_value / 140)).clamp(0.0, 1.0);
    final vol = (0.12 + 0.88 * percept).clamp(0.0, 1.0);
    final rate = (1.0 + percept * 1.6).clamp(0.6, 3.0);

    AudioService.instance
        .playTickWithRate('assets/audio/geiger_short.mp3', vol, rate: rate);

    _pulseController.forward(from: 0);
  }

  int _intervalForValue() {
    const base = 160.0;
    const minI = 20.0;
    final capped = _value.clamp(0.0, 140.0);
    final factor = (capped / 140.0);

    final interval = (minI + (base - minI) * (1.0 - factor * factor));
    return interval.round();
  }

  void _scheduleHoldTick() {
    if (!_holding) return;
    if (_tickScheduled) return;
    _tickScheduled = true;
    final delayMs = _intervalForValue();
    _tickTimer = Timer(Duration(milliseconds: delayMs), () async {
      _tickScheduled = false;
      if (!_holding) return;
      final delay = delayMs;
      const growthSpeed = 5.0;
      final perTick = growthSpeed * (delay / 1000.0);
      setState(() {
        _value += perTick;
      });
      _playTick();
      _scheduleHoldTick();
    });
  }

  void _scheduleDecayTick() {
    if (_holding) return;
    _decayTimer?.cancel();
    final delayMs = _intervalForValue();
    _decayTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_holding) return;
      final delay = delayMs;
      const growthSpeed = 5.0;
      final decaySpeed = growthSpeed * 2.0;
      final perTick = decaySpeed * (delay / 1000.0);
      setState(() {
        _value -= perTick;
        if (_value <= 0) _value = 0.0;
      });
      if (_value > 0) {
        _playTick();
        _scheduleDecayTick();
      } else {
        _decayTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSlay = _selectedMode == 'Slay mode';
    final isFreak = _selectedMode == 'Freak mode';

    final bgColor = isSlay
        ? const Color(0xFFFFEEF4)
        : isFreak
            ? const Color(0xFF0F1020)
            : const Color(0xFF2F2A1F);

    final titleGradient = isSlay
        ? const LinearGradient(colors: [Color(0xFFEF9ABF), Color(0xFFFFC6DD)])
        : isFreak
            ? const LinearGradient(colors: [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple
              ])
            : const LinearGradient(
                colors: [Color(0xFF6B8B3A), Color(0xFFD4A017)]);

    final buttonInner = isSlay
        ? [Colors.pink.shade200, Colors.pink.shade400]
        : isFreak
            ? [Colors.purple.shade400, Colors.teal.shade400]
            : [const Color(0xFF3E2F1B), const Color(0xFF7A9B3A)];

    final ddTextColor = isSlay
        ? Colors.pink.shade800
        : isFreak
            ? Colors.white
            : Colors.white;
    final ddIconColor = isSlay ? Colors.pink.shade600 : Colors.white;

    final percept = (1 - exp(-_value / 140)).clamp(0.0, 1.0);

    final leftEmoji = isSlay
        ? '🎀'
        : isFreak
            ? '🌈'
            : '☢️';
    final rightEmoji = leftEmoji;

    final unit = isSlay
        ? 'Slay/m²'
        : isFreak
            ? 'freakness/m²'
            : 'µSv/h';
    final subtitle = isSlay
        ? 'Slayyyy aura'
        : isFreak
            ? 'Freak detector'
            : 'Chernobyl detector';

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
                    color: isSlay
                        ? Colors.pink.shade50
                        : isFreak
                            ? Colors.white10
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSlay
                            ? Colors.pink.shade200
                            : isFreak
                                ? Colors.white24
                                : Colors.white30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMode,
                      items: _modes
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: TextStyle(color: ddTextColor),
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
                          color: ddTextColor),
                      iconEnabledColor: ddIconColor,
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
                      color: (isSlay || isFreak) ? Colors.white : Colors.black,
                      shadows: (isSlay || isFreak)
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
                          : isFreak
                              ? Colors.cyan.shade200
                              : Colors.yellow.shade100,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(unit,
                      style: TextStyle(
                          color: isSlay
                              ? Colors.pink.shade300
                              : isFreak
                                  ? Colors.cyan.shade200
                                  : Colors.yellow.shade200,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: isSlay
                              ? Colors.pinkAccent
                              : isFreak
                                  ? Colors.cyanAccent
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
                                .withAlpha(
                                    ((percept * 0.85).clamp(0.05, 0.95) * 255)
                                        .round()),
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
