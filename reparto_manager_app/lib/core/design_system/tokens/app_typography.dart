import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tokens de tipografía optimizados para alta nitidez en monitores de PC (Windows ClearType)
/// y pantallas móviles al sol.
/// Regla estricta: piso mínimo de 13px y FontWeight >= w500 en textos chicos con letterSpacing: 0.3.
class AppTypography {
  AppTypography._();

  static const List<String> _fallbackFonts = ['Segoe UI', 'Inter', 'Roboto', 'sans-serif'];

  // Títulos Principales (Outfit / Segoe UI)
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

  // Cuerpos de Texto (Segoe UI / Inter con trazo reforzado)
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
        letterSpacing: 0.2,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
        letterSpacing: 0.3,
      );

  // Botones y Acciones
  static TextStyle get button => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
      );

  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
      );

  // Etiquetas, Badges y Moneda (Mínimo 13px con letterSpacing óptico)
  static TextStyle get badge => const TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
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
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.9),
        fontFamily: 'Segoe UI',
        fontFamilyFallback: _fallbackFonts,
      );
}
