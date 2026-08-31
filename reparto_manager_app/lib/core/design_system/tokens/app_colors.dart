import 'package:flutter/material.dart';
import '../theme_manager.dart';

/// Tokens de colores dinámicos oficiales de Reparto-Manager V2.
/// Se delegan en tiempo real a ThemeManager.instance para permitir el cambio de temas.
class AppColors {
  AppColors._();

  static AppThemePalette get _p => ThemeManager.instance.currentPalette;

  // Colores de Identidad / Marca Dinámicos
  static Color get primaryYellow => _p.primary;
  static Color get primaryYellowDark => _p.primary;
  static Color get primaryYellowLight => _p.primary.withValues(alpha: 0.7);

  // Fondos y Superficies Dinámicas
  static Color get backgroundDark => _p.background;
  static Color get surfaceDark => _p.surface;
  static Color get surfaceDarkElevated => _p.surfaceElevated;
  static Color get surfaceDarkHighlight => _p.surfaceElevated;

  // Textos y Contraste Dinámicos
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;
  static Color get textOnPrimary => _p.textOnPrimary;

  // Bordes Dinámicos
  static Color get borderSubtle => _p.borderSubtle;
  static Color get borderPrimary => _p.primary;
  static Color get borderCard => _p.borderCard;

  // Barra de Búsqueda Adaptativa
  static Color get searchBarBackground => _p.searchBarBackground;
  static Color get searchBarIcon => _p.searchBarIcon;
  static Color get searchBarPlaceholder => _p.searchBarPlaceholder;
  static Color get searchBarText => _p.searchBarText;

  // Estados Semánticos
  static Color get success => _p.success;
  static Color get danger => _p.danger;
  static Color get warning => _p.warning;
  static Color get info => _p.info;

  // Estados de Visita
  static Color get visitVisited => _p.success;
  static Color get visitNotVisited => _p.textMuted;
  static Color get visitPending => _p.warning;

  // Tipos de Clientes
  static Color get clientNormal => _p.info;
  static Color get clientSpecial => _p.primary;
  static Color get clientReseller => const Color(0xFF9C27B0);
}
