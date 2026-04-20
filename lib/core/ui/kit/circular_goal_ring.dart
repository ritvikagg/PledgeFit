import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/pledge_colors.dart';

class CircularGoalRing extends StatelessWidget {
  const CircularGoalRing({
    super.key,
    required this.progress,
    required this.centerTitle,
    required this.centerSubtitle,
    this.size = 200,
    this.strokeWidth = 14,
  });

  /// 0..1
  final double progress;
  final String centerTitle;
  final String centerSubtitle;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: p,
              strokeWidth: strokeWidth,
              activeColor: PledgeColors.primaryGreen,
              trackColor: PledgeColors.progressTrack,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL STEPS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PledgeColors.inkMuted,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                centerTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PledgeColors.ink,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                centerSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PledgeColors.inkMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final active = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
