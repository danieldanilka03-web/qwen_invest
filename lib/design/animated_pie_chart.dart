import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Анимированная круговая диаграмма с плавным появлением секторов
/// и эффектом "дыхания" при выделении
class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final double size;
  final double holeSize;
  final bool showLabels;
  final Function(String)? onSectorTap;

  const AnimatedPieChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 200,
    this.holeSize = 40,
    this.showLabels = true,
    this.onSectorTap,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> with SingleTickerProviderStateMixin {
  final int _hoveredIndex = -1;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total = widget.data.values.fold(0.0, (sum, v) => sum + v);
    
    if (entries.isEmpty || total == 0) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text(
            'Нет данных',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnimatedPieChartPainter(
            data: entries,
            colors: widget.colors,
            total: total,
            animationValue: _animation.value,
            hoveredIndex: _hoveredIndex,
            holeSize: widget.holeSize,
            showLabels: widget.showLabels,
          ),
        );
      },
    );
  }
}

class _AnimatedPieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double total;
  final double animationValue;
  final int hoveredIndex;
  final double holeSize;
  final bool showLabels;

  _AnimatedPieChartPainter({
    required this.data,
    required this.colors,
    required this.total,
    required this.animationValue,
    required this.hoveredIndex,
    required this.holeSize,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) * animationValue;
    
    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi * animationValue;
      
      // Эффект выделения сектора
      double radius = baseRadius;
      double expandAmount = 0;
      if (i == hoveredIndex) {
        radius = baseRadius + 10;
        expandAmount = 10;
      }
      
      // Вычисляем смещение центра для выделенного сектора
      final midAngle = startAngle + sweepAngle / 2;
      final expandOffset = Offset(
        expandAmount * math.cos(midAngle),
        expandAmount * math.sin(midAngle),
      );
      
      final sectorCenter = center + expandOffset;
      
      // Рисуем сектор
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      
      if (holeSize > 0) {
        // Рисуем кольцо (donut chart)
        final path = Path();
        path.arcTo(
          Rect.fromCircle(center: sectorCenter, radius: radius),
          startAngle,
          sweepAngle,
          false,
        );
        path.arcTo(
          Rect.fromCircle(center: sectorCenter, radius: holeSize),
          startAngle + sweepAngle,
          -sweepAngle,
          true,
        );
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: sectorCenter, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );
      }
      
      // Рисуем разделительную линию
      if (data.length > 1) {
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        
        final linePath = Path();
        linePath.moveTo(
          sectorCenter.dx + (holeSize > 0 ? holeSize : 0) * math.cos(startAngle),
          sectorCenter.dy + (holeSize > 0 ? holeSize : 0) * math.sin(startAngle),
        );
        linePath.lineTo(
          sectorCenter.dx + radius * math.cos(startAngle),
          sectorCenter.dy + radius * math.sin(startAngle),
        );
        canvas.drawPath(linePath, linePaint);
      }
      
      // Рисуем метку с процентом
      if (showLabels && sweepAngle > 0.2) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = holeSize > 0 
            ? (radius + holeSize) / 2 
            : radius * 0.7;
        
        final labelX = center.dx + labelRadius * math.cos(labelAngle);
        final labelY = center.dy + labelRadius * math.sin(labelAngle);
        
        final percent = (entry.value / total * 100);
        if (percent >= 5) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${percent.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              labelX - textPainter.width / 2,
              labelY - textPainter.height / 2,
            ),
          );
        }
      }
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedPieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.data != data;
  }
}
