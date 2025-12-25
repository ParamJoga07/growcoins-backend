import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/investment_plan_model.dart';
import '../theme/app_theme.dart';

class PortfolioDonutChart extends StatelessWidget {
  final List<MutualFundAllocation> allocations;
  final double size;

  const PortfolioDonutChart({
    super.key,
    required this.allocations,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: Text('No allocations')),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutChartPainter(allocations: allocations),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Portfolio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Allocation',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MutualFundAllocation> allocations;
  final double strokeWidth = 40;

  _DonutChartPainter({required this.allocations});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    double startAngle = -math.pi / 2; // Start from top

    for (var allocation in allocations) {
      final sweepAngle = (allocation.percentage / 100) * 2 * math.pi;
      final color = allocation.getCategoryColor();

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.allocations != allocations;
  }
}

