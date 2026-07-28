import 'package:flutter/material.dart';

/// Анимированная карточка с эффектом "волны" при нажатии
/// и градиентным фоном
class WaveCard extends StatefulWidget {
  final Widget child;
  final Color gradientStart;
  final Color gradientEnd;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showWaveEffect;

  const WaveCard({
    super.key,
    required this.child,
    this.gradientStart = const Color(0xFF1C212E),
    this.gradientEnd = const Color(0xFF161A24),
    this.borderRadius = 20,
    this.onTap,
    this.showWaveEffect = true,
  });

  @override
  State<WaveCard> createState() => _WaveCardState();
}

class _WaveCardState extends State<WaveCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.showWaveEffect) {
          setState(() => _isPressed = true);
          _controller.forward(from: 0);
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        if (widget.showWaveEffect) {
          setState(() => _isPressed = false);
          _controller.reverse();
        }
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          children: [
            // Основная карточка с градиентом
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.gradientStart, widget.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
            ),
            // Эффект волны при нажатии
            if (widget.showWaveEffect && _isPressed)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Center(
                      child: Transform.scale(
                        scale: _rippleAnimation.value * 3,
                        child: Opacity(
                          opacity: 1 - _rippleAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
