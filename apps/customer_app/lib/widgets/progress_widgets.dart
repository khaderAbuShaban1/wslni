import 'package:flutter/material.dart';

import '../utils/constants.dart';

class RideProgressIndicator extends StatelessWidget {
  const RideProgressIndicator({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: lightGray,
            valueColor: const AlwaysStoppedAnimation(emerald),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProgressStep(label: 'طلب'),
            _ProgressStep(label: 'وصول'),
            _ProgressStep(label: 'انطلاق'),
            _ProgressStep(label: 'نهاية'),
          ],
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(color: mutedText, fontSize: 12));
  }
}
