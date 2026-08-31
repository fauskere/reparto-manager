import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Campo de texto tematizado oficial para Reparto-Manager V2.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? contentPadding;
  final Color? fillColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? borderColor;
  final Color? focusedBorderColor;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.fillColor,
    this.textColor,
    this.hintColor,
    this.prefixIconColor,
    this.suffixIconColor,
    this.borderColor,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFill = fillColor ?? (enabled ? AppColors.surfaceDark : AppColors.surfaceDarkElevated);
    final effectiveText = textColor ?? (enabled ? AppColors.textPrimary : AppColors.textMuted);
    final effectiveHint = hintColor ?? AppColors.textMuted;
    final effectiveBorder = borderColor ?? AppColors.borderSubtle;
    final effectiveFocusedBorder = focusedBorderColor ?? AppColors.primaryYellow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodySmall.copyWith(
              color: enabled ? AppColors.textSecondary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          readOnly: readOnly,
          maxLines: maxLines,
          style: AppTypography.bodyLarge.copyWith(color: effectiveText),
          cursorColor: effectiveFocusedBorder,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(color: effectiveHint),
            filled: true,
            fillColor: effectiveFill,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconColor: prefixIconColor ?? AppColors.textSecondary,
            suffixIconColor: suffixIconColor ?? AppColors.textSecondary,
            border: _buildBorder(effectiveBorder),
            enabledBorder: _buildBorder(effectiveBorder),
            focusedBorder: _buildBorder(effectiveFocusedBorder, width: 2.0),
            errorBorder: _buildBorder(AppColors.danger),
            focusedErrorBorder: _buildBorder(AppColors.danger, width: 2.0),
            disabledBorder: _buildBorder(Colors.transparent),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLg,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
