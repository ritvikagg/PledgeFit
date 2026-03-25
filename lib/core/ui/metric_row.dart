import 'package:flutter/material.dart';

class MetricRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool emphasize;

  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          value,
          if (emphasize) const SizedBox(width: 2),
        ],
      ),
    );
  }
}

