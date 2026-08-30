import 'package:flutter/material.dart';

/// Tokens de colores oficiales de Reparto-Manager V2.
/// Mantiene la identidad visual de la aplicación con fondo oscuro y amarillo vibrante.
class AppColors {
  AppColors._();

  // Colores de Identidad / Marca
  static const Color primaryYellow = Color(0xFFFFEB3B);
  static const Color primaryYellowDark = Color(0xFFFBC02D);
  static const Color primaryYellowLight = Color(0xFFFFF59D);

  // Fondos y Superficies (Dark Theme)
  static const Color backgroundDark = Color(0xFF212121);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color surfaceDarkElevated = Color(0xFF383838);
  static const Color surfaceDarkHighlight = Color(0xFF424242);

  // Textos y Contraste
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFF000000); // Texto oscuro sobre amarillo

  // Bordes y Divisores
  static const Color borderSubtle = Color(0x33AAAAAA);
  static const Color borderPrimary = Color(0xFFFFEB3B);
  static const Color borderCard = Color(0x26FFEB3B); // 15% opacidad para tarjetas

  // Estados Semánticos
  static const Color success = Color(0xFF4CAF50);
  static const Color successBackground = Color(0x264CAF50);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBackground = Color(0x26EF4444);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningBackground = Color(0x26FF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color infoBackground = Color(0x262196F3);

  // Estados de Visita
  static const Color visitVisited = Color(0xFF4CAF50);
  static const Color visitNotVisited = Color(0xFF757575);
  static const Color visitPending = Color(0xFFFF9800);

  // Tipos de Clientes
  static const Color clientNormal = Color(0xFF2196F3);
  static const Color clientSpecial = Color(0xFFFFEB3B);
  static const Color clientReseller = Color(0xFF9C27B0);
}
