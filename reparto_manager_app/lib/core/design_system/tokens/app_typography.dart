import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tokens de tipografía oficial de Reparto-Manager V2.
/// Diseñado para máxima legibilidad tanto en pantallas interiores como en la calle (luz solar).
class AppTypography {
  AppTypography._();

  // Títulos Principales (Outfit)
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryYellow,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h4 => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Cuerpos de Texto
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Botones y Acciones
  static TextStyle get button => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );

  // Etiquetas, Badges y Moneda
  static TextStyle get badge => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      );

  static TextStyle get currencyLarge => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get currencyMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );

  static TextStyle caption([Color? color]) => TextStyle(
        fontSize: 10,
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.8),
        fontFamily: 'monospace',
      );
}
