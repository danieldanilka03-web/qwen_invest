import 'package:flutter/material.dart';

/// Анимированное текстовое поле с плавающим лейблом, 
/// градиентной рамкой и эффектом свечения при фокусе
class AnimatedTextField extends StatefulWidget {
  final String label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final int? maxLines;
  final Color gradientStart;
  final Color gradientEnd;

  const AnimatedTextField({
    super.key,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.onTap,
    this.validator,
    this.maxLines = 1,
    this.gradientStart = const Color(0xFF6C5CE7),
    this.gradientEnd = const Color(0xFF00B894),
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasText = false;
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: widget.gradientStart,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    widget.controller?.addListener(_onTextChanged);
    _hasText = widget.controller?.text.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _hasText = widget.controller?.text.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _colorAnimation.value!,
                  width: _borderAnimation.value,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: widget.gradientStart.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Градиентный фон при фокусе
                    Positioned.fill(
                      child: Opacity(
                        opacity: _isFocused ? 0.05 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.gradientStart, widget.gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Основное поле ввода
                    TextField(
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      obscureText: widget.obscureText,
                      maxLines: widget.maxLines,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: _hasText || _isFocused ? null : widget.label,
                        labelStyle: TextStyle(
                          color: _isFocused ? widget.gradientStart : Colors.grey.shade500,
                          fontSize: _hasText || _isFocused ? 12 : 16,
                          fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
                        ),
                        prefixIcon: widget.prefixIcon != null
                            ? Icon(widget.prefixIcon, color: _isFocused ? widget.gradientStart : Colors.grey.shade500)
                            : null,
                        suffixIcon: widget.suffixIcon != null
                            ? IconButton(
                                icon: Icon(widget.suffixIcon, color: _isFocused ? widget.gradientStart : Colors.grey.shade500),
                                onPressed: widget.onSuffixTap,
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: widget.maxLines == 1 ? 16 : 12,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: widget.onChanged,
                      onTap: () {
                        setState(() => _isFocused = true);
                        widget.onTap?.call();
                      },
                      onTapOutside: (_) {
                        setState(() => _isFocused = false);
                        _controller.reverse();
                      },
                      focusNode: FocusNode(
                        onFocusChange: (focused) {
                          setState(() => _isFocused = focused);
                          if (focused) {
                            _controller.forward();
                          } else {
                            _controller.reverse();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
