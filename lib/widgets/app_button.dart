

import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool fullWidth;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.fullWidth = false,
    this.borderRadius,
    this.textStyle,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final buttonSize = _getButtonSize();

    return SizedBox(
      width: fullWidth ? double.infinity : width ?? buttonSize.width,
      height: height ?? buttonSize.height,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: buttonStyle,
        child: _buildChild(theme),
      ),
    );
  }

  Widget _buildChild(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingColor(theme),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(),
            color: _getTextColor(theme),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: _getTextStyle(theme),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme) {
    final baseStyle = ElevatedButton.styleFrom(
      padding: padding ?? _getPadding(),
      backgroundColor: _getBackgroundColor(theme),
      foregroundColor: _getTextColor(theme),
      disabledBackgroundColor: theme.disabledColor,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        side: _getBorderSide(theme),
      ),
      elevation: _getElevation(),
      shadowColor: _getShadowColor(theme),
      textStyle: _getTextStyle(theme),
    );

    return baseStyle;
  }

  // Helper methods
  Color _getBackgroundColor(ThemeData theme) {
    if (disabled) return theme.disabledColor;
    if (backgroundColor != null) return backgroundColor!;

    switch (type) {
      case ButtonType.primary:
        return theme.primaryColor;
      case ButtonType.secondary:
        return Colors.transparent;
      case ButtonType.success:
        return Colors.green;
      case ButtonType.danger:
        return Colors.red;
      case ButtonType.warning:
        return Colors.orange;
      case ButtonType.info:
        return Colors.blue;
      case ButtonType.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ThemeData theme) {
    if (disabled) return Colors.white;
    if (textColor != null) return textColor!;

    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return theme.primaryColor;
      case ButtonType.success:
        return Colors.white;
      case ButtonType.danger:
        return Colors.white;
      case ButtonType.warning:
        return Colors.white;
      case ButtonType.info:
        return Colors.white;
      case ButtonType.outline:
        return theme.primaryColor;
    }
  }

  BorderSide _getBorderSide(ThemeData theme) {
    if (borderColor != null) {
      return BorderSide(color: borderColor!, width: 1);
    }

    switch (type) {
      case ButtonType.outline:
        return BorderSide(color: theme.primaryColor, width: 1);
      case ButtonType.secondary:
        return BorderSide(color: theme.primaryColor, width: 1);
      default:
        return BorderSide.none;
    }
  }

  Color _getLoadingColor(ThemeData theme) {
    return _getTextColor(theme);
  }

  Color? _getShadowColor(ThemeData theme) {
    return type == ButtonType.primary ? theme.shadowColor : null;
  }

  double _getElevation() {
    return (type == ButtonType.primary && !disabled) ? 2 : 0;
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = textStyle ?? theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return baseStyle?.copyWith(color: _getTextColor(theme)) ??
        TextStyle(color: _getTextColor(theme), fontWeight: FontWeight.w600);
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  ButtonSizeData _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return const ButtonSizeData(height: 36, width: null);
      case ButtonSize.medium:
        return const ButtonSizeData(height: 48, width: null);
      case ButtonSize.large:
        return const ButtonSizeData(height: 56, width: null);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

// Supporting Enums and Classes
enum ButtonType {
  primary,
  secondary,
  success,
  danger,
  warning,
  info,
  outline,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class ButtonSizeData {
  final double height;
  final double? width;

  const ButtonSizeData({required this.height, this.width});
}