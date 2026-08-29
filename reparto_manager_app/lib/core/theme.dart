import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores inspirada en el logo "María Belén"
  static const Color primaryYellow = Color(0xFFFFEB3B); // Amarillo vibrante del círculo
  static const Color backgroundDark = Color(0xFF212121); // Gris oscuro original
  static const Color surfaceDark = Color(0xFF2C2C2C); // Gris más claro para las tarjetas
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryYellow,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0, // Esto asegura el mismo margen exacto en todas partes
        foregroundColor: primaryYellow,
        iconTheme: const IconThemeData(color: primaryYellow),
        actionsIconTheme: const IconThemeData(color: primaryYellow),
        titleTextStyle: GoogleFonts.outfit(
          color: primaryYellow,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: primaryYellow,
        surface: surfaceDark,
        error: danger,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black, // Texto oscuro sobre el botón amarillo para contraste
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryYellow.withOpacity(0.1), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textSecondary.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
