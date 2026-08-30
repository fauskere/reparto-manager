import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Campo de texto tematizado oficial para Reparto-Manager V2.
/// Ofrece alto contraste, soporte táctil cómodo e indicación visual clara de foco.
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
  });

  @override
  Widget build(BuildContext context) {
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
          style: AppTypography.bodyLarge.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
          cursorColor: AppColors.primaryYellow,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: enabled ? AppColors.surfaceDark : AppColors.surfaceDarkElevated,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconColor: AppColors.textSecondary,
            suffixIconColor: AppColors.textSecondary,
            border: _buildBorder(AppColors.borderSubtle),
            enabledBorder: _buildBorder(AppColors.borderSubtle),
            focusedBorder: _buildBorder(AppColors.primaryYellow, width: 2.0),
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
