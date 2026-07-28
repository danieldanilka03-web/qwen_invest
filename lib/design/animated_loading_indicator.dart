import 'package:flutter/material.dart';

/// Анимированный индикатор загрузки в виде пульсирующего кольца
/// с градиентным свечением
class AnimatedLoadingIndicator extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final String? message;

  const AnimatedLoadingIndicator({
    super.key,
    this.size = 60,
    this.primaryColor = const Color(0xFF6C5CE7),
    this.secondaryColor = const Color(0xFF00B894),
    this.message,
  });

  @override
  State<AnimatedLoadingIndicator> createState() => _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
          ..repeat(reverse: true),
        curve: Curves.easeInOut,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
          ..repeat(reverse: true),
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Внешнее кольцо
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _GradientRingPainter(
                        primaryColor: widget.primaryColor,
                        secondaryColor: widget.secondaryColor,
                        strokeWidth: 4,
                      ),
                    ),
                    // Пульсирующий центр
                    Center(
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Container(
                            width: widget.size * 0.3,
                            height: widget.size * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [widget.primaryColor, widget.secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + _opacityAnimation.value * 0.5,
                child: Text(
                  widget.message!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  _GradientRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Рисуем фоновое кольцо
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Рисуем градиентную дугу
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * 3.14159,
      colors: [
        primaryColor.withOpacity(0.2),
        primaryColor,
        secondaryColor,
        primaryColor.withOpacity(0.2),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, -3.14159 / 2, 3.14159 * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) => false;
}
