import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Анимированный переключатель вкладок с эффектом скольжения
/// и градиентным индикатором активной вкладки
class AnimatedTabBar extends StatefulWidget {
  final List<String> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color gradientStart;
  final Color gradientEnd;

  const AnimatedTabBar({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabSelected,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF8B95A5),
    this.gradientStart = const Color(0xFF6C5CE7),
    this.gradientEnd = const Color(0xFF00B894),
  });

  @override
  State<AnimatedTabBar> createState() => _AnimatedTabBarState();
}

class _AnimatedTabBarState extends State<AnimatedTabBar> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      _controller.forward(from: 0);
      widget.onTabSelected?.call(index);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: widget.tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _currentIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [widget.gradientStart, widget.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: widget.gradientStart.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? widget.activeColor : widget.inactiveColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(tab),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
