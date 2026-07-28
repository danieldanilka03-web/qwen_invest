import 'package:flutter/material.dart';

/// Анимированный линейный график с плавным появлением линии
/// и интерактивными точками при касании
class AnimatedLineChart extends StatefulWidget {
  final List<double> data;
  final List<String>? labels;
  final Color lineColor;
  final Color? fillColor;
  final double height;
  final bool showDots;
  final bool curved;
  final Function(int)? onPointTap;

  const AnimatedLineChart({
    super.key,
    required this.data,
    this.labels,
    this.lineColor = const Color(0xFF6C5CE7),
    this.fillColor,
    this.height = 200,
    this.showDots = true,
    this.curved = true,
    this.onPointTap,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Нет данных',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final pointWidth = renderBox.size.width / (widget.data.length - 1).clamp(1, widget.data.length - 1);
        final index = (localPosition.dx / pointWidth).round().clamp(0, widget.data.length - 1);
        
        if (_hoveredIndex != index) {
          setState(() => _hoveredIndex = index);
          HapticFeedback.selectionClick();
          widget.onPointTap?.call(index);
        }
      },
      onPanEnd: (_) {
        setState(() => _hoveredIndex = null);
      },
      onPanCancel: () {
        setState(() => _hoveredIndex = null);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _AnimatedLineChartPainter(
              data: widget.data,
              labels: widget.labels,
              lineColor: widget.lineColor,
              fillColor: widget.fillColor ?? widget.lineColor.withOpacity(0.2),
              animationValue: _animation.value,
              hoveredIndex: _hoveredIndex,
              showDots: widget.showDots,
              curved: widget.curved,
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedLineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String>? labels;
  final Color lineColor;
  final Color fillColor;
  final double animationValue;
  final int? hoveredIndex;
  final bool showDots;
  final bool curved;

  _AnimatedLineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.fillColor,
    required this.animationValue,
    required this.hoveredIndex,
    required this.showDots,
    required this.curved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;
    
    // Вычисляем точки графика
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final normalizedValue = (data[i] - minValue + padding) / (range + 2 * padding);
      final y = size.height * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    // Рисуем заполнение под графиком
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy * animationValue);
    
    if (curved && points.length > 2) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(
          p1.dx + (p2.dx - p1.dx) / 3,
          p1.dy,
        );
        final controlPoint2 = Offset(
          p2.dx - (p2.dx - p1.dx) / 3,
          p2.dy,
        );
        final targetY = p2.dy * animationValue;
        final adjustedP2 = Offset(p2.dx, targetY);
        final adjustedControlPoint2 = Offset(
          controlPoint2.dx,
          controlPoint2.dy * animationValue,
        );
        fillPath.quadraticBezierTo(
          controlPoint1.dx,
          controlPoint1.dy * animationValue,
          adjustedControlPoint2.dx,
          adjustedControlPoint2.dy,
        );
      }
    } else {
      for (int i = 1; i < points.length; i++) {
        final targetY = points[i].dy * animationValue;
        fillPath.lineTo(points[i].dx, targetY);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Рисуем линию графика
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (curved && points.length > 2) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy * animationValue);
      
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(
          p1.dx + (p2.dx - p1.dx) / 3,
          p1.dy,
        );
        final controlPoint2 = Offset(
          p2.dx - (p2.dx - p1.dx) / 3,
          p2.dy,
        );
        final targetY = p2.dy * animationValue;
        final adjustedControlPoint2 = Offset(
          controlPoint2.dx,
          controlPoint2.dy * animationValue,
        );
        path.quadraticBezierTo(
          controlPoint1.dx,
          controlPoint1.dy * animationValue,
          adjustedControlPoint2.dx,
          adjustedControlPoint2.dy,
        );
      }
      
      canvas.drawPath(path, linePaint);
    } else {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy * animationValue);
      for (int i = 1; i < points.length; i++) {
        final targetY = points[i].dy * animationValue;
        path.lineTo(points[i].dx, targetY);
      }
      canvas.drawPath(path, linePaint);
    }

    // Рисуем точки
    if (showDots) {
      for (int i = 0; i < points.length; i++) {
        final isHovered = i == hoveredIndex;
        final dotRadius = isHovered ? 6.0 : 4.0;
        
        final dotPaint = Paint()
          ..color = isHovered ? Colors.white : lineColor
          ..style = PaintingStyle.fill;
        
        final borderPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(points[i], dotRadius, dotPaint);
        canvas.drawCircle(points[i], dotRadius, borderPaint);

        // Рисуем метку значения при наведении
        if (isHovered) {
          final valueText = TextSpan(
            text: data[i].toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
          final textPainter = TextPainter(
            text: valueText,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          // Фон для метки
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              points[i].dx - textPainter.width / 2 - 6,
              points[i].dy - textPainter.height - 16,
              textPainter.width + 12,
              textPainter.height + 8,
            ),
            const Radius.circular(6),
          );
          
          final bgPaint = Paint()
            ..color = Colors.black.withOpacity(0.8)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);
          
          textPainter.paint(
            canvas,
            Offset(
              points[i].dx - textPainter.width / 2,
              points[i].dy - textPainter.height - 12,
            ),
          );
        }
      }
    }

    // Рисуем подписи осей X
    if (labels != null && labels!.isNotEmpty) {
      final step = (labels!.length / 5).ceil();
      for (int i = 0; i < labels!.length; i += step) {
        if (i >= points.length) break;
        final textPainter = TextPainter(
          text: TextSpan(
            text: labels![i],
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            points[i].dx - textPainter.width / 2,
            size.height - 16,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedLineChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.data != data;
  }
}
