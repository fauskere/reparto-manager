import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Contenedor de tarjeta estándar para Reparto-Manager V2.
/// Diseñado con superficie oscura, bordes redondeados y soporte para estados interactivos.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isHighlighted;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.isHighlighted = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? AppColors.surfaceDark;
    final Color borderClr = isHighlighted
        ? AppColors.primaryYellow
        : (borderColor ?? AppColors.borderCard);

    final Widget content = Padding(
      padding: padding ?? AppSpacing.paddingLg,
      child: child,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(
            color: borderClr,
            width: isHighlighted ? 2.0 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap != null || onLongPress != null
            ? InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                splashColor: AppColors.primaryYellow.withValues(alpha: 0.1),
                highlightColor: AppColors.primaryYellow.withValues(alpha: 0.05),
                child: content,
              )
            : content,
      ),
    );
  }
}
