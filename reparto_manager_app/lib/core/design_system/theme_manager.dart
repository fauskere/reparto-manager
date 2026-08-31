import 'package:flutter/material.dart';

enum AppThemeType {
  repartoGold,
  midnightBlue,
  sweetCream,
  emeraldMint,
  roastedCoffee,
}

/// Paleta completa de colores semánticos para un tema.
class AppThemePalette {
  final String name;
  final AppThemeType type;
  final bool isDark;
  final Color primary;
  final Color textOnPrimary;
  final Color textOnDanger;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;
  final Color borderCard;
  final Color searchBarBackground;
  final Color searchBarIcon;
  final Color searchBarPlaceholder;
  final Color searchBarText;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;

  const AppThemePalette({
    required this.name,
    required this.type,
    required this.isDark,
    required this.primary,
    required this.textOnPrimary,
    required this.textOnDanger,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.borderCard,
    required this.searchBarBackground,
    required this.searchBarIcon,
    required this.searchBarPlaceholder,
    required this.searchBarText,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
  });

  static const repartoGold = AppThemePalette(
    name: 'Reparto Gold',
    type: AppThemeType.repartoGold,
    isDark: true,
    primary: Color(0xFFFFEB3B),
    textOnPrimary: Color(0xFF000000),
    textOnDanger: Color(0xFFFFFFFF),
    background: Color(0xFF212121),
    surface: Color(0xFF2C2C2C),
    surfaceElevated: Color(0xFF383838),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAAAAAA),
    textMuted: Color(0xFF757575),
    borderSubtle: Color(0x33AAAAAA),
    borderCard: Color(0x33FFEB3B),
    searchBarBackground: Color(0xFFFFEB3B),
    searchBarIcon: Color(0xFF000000),
    searchBarPlaceholder: Color(0xFF424242),
    searchBarText: Color(0xFF000000),
    success: Color(0xFF4CAF50),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFFF9800),
    info: Color(0xFF2196F3),
  );

  static const midnightBlue = AppThemePalette(
    name: 'Midnight Blue',
    type: AppThemeType.midnightBlue,
    isDark: true,
    primary: Color(0xFF2563EB),
    textOnPrimary: Color(0xFFFFFFFF),
    textOnDanger: Color(0xFFFFFFFF),
    background: Color(0xFF1E222B),
    surface: Color(0xFF2A2F3D),
    surfaceElevated: Color(0xFF353B4D),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E9093),
    textMuted: Color(0xFF636773),
    borderSubtle: Color(0x338E9093),
    borderCard: Color(0x332563EB),
    searchBarBackground: Color(0xFF2A2F3D),
    searchBarIcon: Color(0xFF2563EB),
    searchBarPlaceholder: Color(0xFF8E9093),
    searchBarText: Color(0xFFFFFFFF),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
  );

  static const sweetCream = AppThemePalette(
    name: 'Sweet Cream',
    type: AppThemeType.sweetCream,
    isDark: false,
    primary: Color(0xFFEC4899),
    textOnPrimary: Color(0xFFFAF7F2),
    textOnDanger: Color(0xFFFAF7F2),
    background: Color(0xFFECE5D8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF7F2EA),
    textPrimary: Color(0xFF1F1916),
    textSecondary: Color(0xFF5C4E46),
    textMuted: Color(0xFF8C7E76),
    borderSubtle: Color(0x335C4E46),
    borderCard: Color(0x2BDB2777),
    searchBarBackground: Color(0xFFFFFFFF),
    searchBarIcon: Color(0xFFEC4899),
    searchBarPlaceholder: Color(0xFF8C7E76),
    searchBarText: Color(0xFF1F1916),
    success: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
  );

  static const emeraldMint = AppThemePalette(
    name: 'Emerald Mint',
    type: AppThemeType.emeraldMint,
    isDark: true,
    primary: Color(0xFF10B981),
    textOnPrimary: Color(0xFFFFFFFF),
    textOnDanger: Color(0xFFFFFFFF),
    background: Color(0xFF18181B),
    surface: Color(0xFF27272A),
    surfaceElevated: Color(0xFF3F3F46),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    borderSubtle: Color(0x33A1A1AA),
    borderCard: Color(0x3310B981),
    searchBarBackground: Color(0xFF27272A),
    searchBarIcon: Color(0xFF10B981),
    searchBarPlaceholder: Color(0xFFA1A1AA),
    searchBarText: Color(0xFFFAFAFA),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF06B6D4),
  );

  static const roastedCoffee = AppThemePalette(
    name: 'Roasted Coffee',
    type: AppThemeType.roastedCoffee,
    isDark: true,
    primary: Color(0xFFC48B58),
    textOnPrimary: Color(0xFFFDF8F2),
    textOnDanger: Color(0xFFFDF8F2),
    background: Color(0xFF1F1916),
    surface: Color(0xFF2D2420),
    surfaceElevated: Color(0xFF3B2F2A),
    textPrimary: Color(0xFFFDF8F2),
    textSecondary: Color(0xFFCBB8A9),
    textMuted: Color(0xFF9E897A),
    borderSubtle: Color(0x334A3B32),
    borderCard: Color(0xFF4A3B32),
    searchBarBackground: Color(0xFF2D2420),
    searchBarIcon: Color(0xFFC48B58),
    searchBarPlaceholder: Color(0xFFCBB8A9),
    searchBarText: Color(0xFFFDF8F2),
    success: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
  );
}

/// Gestor Singleton y ChangeNotifier para la gestión de temas dinámicos.
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  static ThemeManager get instance => _instance;

  ThemeManager._internal();

  AppThemeType _currentType = AppThemeType.repartoGold;
  AppThemeType get currentType => _currentType;

  static const Map<AppThemeType, AppThemePalette> _palettes = {
    AppThemeType.repartoGold: AppThemePalette.repartoGold,
    AppThemeType.midnightBlue: AppThemePalette.midnightBlue,
    AppThemeType.sweetCream: AppThemePalette.sweetCream,
    AppThemeType.emeraldMint: AppThemePalette.emeraldMint,
    AppThemeType.roastedCoffee: AppThemePalette.roastedCoffee,
  };

  AppThemePalette get currentPalette => _palettes[_currentType]!;

  ThemeData get currentThemeData {
    final p = currentPalette;
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      cardColor: p.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.textOnPrimary,
        secondary: p.primary,
        onSecondary: p.textOnPrimary,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.primary,
        elevation: 0,
      ),
    );
  }

  void setTheme(AppThemeType type) {
    if (_currentType == type) return;
    _currentType = type;
    notifyListeners();
  }
}
