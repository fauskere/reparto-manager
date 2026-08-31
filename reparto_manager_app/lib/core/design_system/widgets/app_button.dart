import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
  ghost,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// Botón estandarizado del Design System de Reparto-Manager V2.
/// Soporta variantes visuales, tamaños adaptados a uso táctil, estado de carga y deshabilitado.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActionDisabled = isDisabled || isLoading || onPressed == null;

    final double height = _resolveHeight();
    final EdgeInsets padding = _resolvePadding();
    final TextStyle textStyle = _resolveTextStyle();
    final Color backgroundColor = _resolveBackgroundColor(isActionDisabled);
    final Color foregroundColor = _resolveForegroundColor(isActionDisabled);
    final BorderSide borderSide = _resolveBorderSide(isActionDisabled);

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLoading) ...[
          _buildLoadingIndicator(foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: _resolveIconSize(), color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            style: textStyle.copyWith(color: foregroundColor),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: _resolveIconSize(), color: foregroundColor),
        ],
      ],
    );

    final Widget buttonWidget = SizedBox(
      height: height,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isActionDisabled ? null : onPressed,
          splashColor: foregroundColor.withValues(alpha: 0.15),
          highlightColor: foregroundColor.withValues(alpha: 0.08),
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }

  Widget _buildLoadingIndicator(Color color) {
    final double size = _resolveIconSize();
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  double _resolveHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case AppButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  EdgeInsets _resolvePadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 0);
    }
  }

  double _resolveIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 22.0;
    }
  }

  TextStyle _resolveTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
      case AppButtonSize.large:
        return AppTypography.button;
    }
  }

  Color _resolveBackgroundColor(bool disabled) {
    if (disabled) {
      return AppColors.surfaceDarkElevated;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryYellow;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color _resolveForegroundColor(bool disabled) {
    if (disabled) {
      return AppColors.textMuted;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.textOnPrimary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return AppColors.primaryYellow;
      case AppButtonVariant.danger:
        return AppColors.textOnDanger;
    }
  }

  BorderSide _resolveBorderSide(bool disabled) {
    if (variant == AppButtonVariant.secondary) {
      final Color borderColor = disabled ? AppColors.borderSubtle : AppColors.primaryYellow;
      return BorderSide(color: borderColor, width: 1.5);
    }
    return BorderSide.none;
  }
}
