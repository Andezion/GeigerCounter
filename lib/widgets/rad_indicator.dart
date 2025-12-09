import 'package:flutter/material.dart';

class RadIndicator extends StatelessWidget {
  final double intensity;

  const RadIndicator({super.key, required this.intensity});

  @override
  Widget build(BuildContext context) {
    final cpm = (intensity * 300).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Radiation', style: TextStyle(color: Colors.black54)),
            Text('$cpm CPM',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: intensity,
            minHeight: 14,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation(Colors.orangeAccent),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
            opacity: intensity > 0.15 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text('Counts/min: $cpm',
                style: const TextStyle(color: Colors.black54))),
      ],
    );
  }
}
