import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/app_text_styles.dart';

/// Premium button system for HomePlates
/// Provides Primary, Secondary, Destructive, and Text button variants
/// with built-in loading states, haptic feedback, and tap animations
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
  }) : variant = AppButtonVariant.text;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animationFast,
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
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final buttonStyle = _getButtonStyle(isDark, isDisabled);

    final content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingColor(isDark),
              ),
            ),
          )
        : Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: widget.textStyle ?? AppTextStyles.button(),
              ),
            ],
          );

    final button = Container(
      height: widget.height ?? 52,
      width: widget.isExpanded ? double.infinity : null,
      decoration: buttonStyle.decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return ScaleTransition(scale: _scaleAnimation, child: button);
  }

  _ButtonStyle _getButtonStyle(bool isDark, bool isDisabled) {
    if (isDisabled) {
      return _ButtonStyle(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        textColor: isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3),
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            gradient: widget.backgroundColor == null
                ? const LinearGradient(
                    colors: [AppTheme.primaryGold, AppTheme.accentSaffron],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: AppTheme.shadowMd(isDark),
          ),
          textColor: widget.textStyle?.color ?? AppTheme.warmCharcoal,
        );

      case AppButtonVariant.secondary:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(
              color: widget.borderColor ?? AppTheme.primaryGold,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          ),
          textColor: widget.textStyle?.color ?? AppTheme.primaryGold,
        );

      case AppButtonVariant.destructive:
        return _ButtonStyle(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: AppTheme.shadowMd(isDark),
          ),
          textColor: Colors.white,
        );

      case AppButtonVariant.text:
        return _ButtonStyle(
          decoration: const BoxDecoration(),
          textColor: AppTheme.primaryGold,
        );
    }
  }

  Color _getLoadingColor(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppTheme.warmCharcoal;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return AppTheme.primaryGold;
      case AppButtonVariant.destructive:
        return Colors.white;
    }
  }
}

enum AppButtonVariant { primary, secondary, destructive, text }

class _ButtonStyle {
  final BoxDecoration decoration;
  final Color textColor;

  _ButtonStyle({required this.decoration, required this.textColor});
}
