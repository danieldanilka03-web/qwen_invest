import 'package:flutter/material.dart';

/// Анимированная плавающая кнопка действия (FAB) с эффектом расширения
/// при нажатии и несколькими дочерними действиями
class AnimatedFab extends StatefulWidget {
  final IconData icon;
  final List<FabAction> actions;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isExtended;

  const AnimatedFab({
    super.key,
    required this.icon,
    this.actions = const [],
    this.backgroundColor = const Color(0xFF6C5CE7),
    this.onPressed,
    this.isExtended = false,
  });

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _AnimatedFabState extends State<AnimatedFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
      HapticFeedback.mediumImpact();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Дочерние действия
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              final progress = _fabAnimation.value;
              final delay = index * 0.1;
              final offset = (progress - delay) / (1 - delay);
              
              if (offset <= 0) return const SizedBox.shrink();
              
              final translateY = (widget.actions.length - index) * 60 * (1 - offset.clamp(0, 1));
              final opacity = offset.clamp(0, 1);
              
              return Transform.translate(
                offset: Offset(0, -translateY),
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: _buildActionButton(action),
          );
        }).toList().reversed.toList(),

        // Основная кнопка FAB
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (widget.actions.isEmpty) {
              widget.onPressed?.call();
            } else {
              _toggle();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.backgroundColor,
                  widget.backgroundColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.actions.isEmpty ? widget.onPressed : null,
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      widget.actions.isEmpty ? widget.icon : 
                          (_isOpen ? Icons.close : widget.icon),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(FabAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Метка
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Кнопка
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: action.color ?? Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (action.color ?? Colors.white).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                customBorder: const CircleBorder(),
                child: Icon(
                  action.icon,
                  color: action.color != null ? Colors.white : widget.backgroundColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
