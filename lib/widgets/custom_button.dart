import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isOutlined;
  final IconData? icon;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.isOutlined = false,
    this.icon,
    this.useGradient = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: !widget.isOutlined && widget.useGradient
              ? BoxDecoration(
                  gradient: widget.backgroundColor == null
                      ? AppColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            widget.backgroundColor!,
                            widget.backgroundColor!,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: widget.backgroundColor ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.isOutlined
                      ? Border.all(
                          color: widget.backgroundColor ?? AppColors.primary,
                          width: 2,
                        )
                      : null,
                ),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: widget.textColor ?? AppColors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: AppTextStyles.button.copyWith(
              color:
                  widget.textColor ??
                  (widget.isOutlined ? AppColors.textDark : AppColors.white),
            ),
          ),
        ],
      );
    }
    return Text(
      widget.text,
      style: AppTextStyles.button.copyWith(
        color:
            widget.textColor ??
            (widget.isOutlined ? AppColors.textDark : AppColors.white),
      ),
    );
  }
}
