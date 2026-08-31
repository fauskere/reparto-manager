import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/core/design_system/design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeManager - Pruebas Unitarias de Temas Dinámicos', () {
    test('1. Tema por defecto debe ser Reparto Gold', () {
      final tm = ThemeManager.instance;
      tm.setTheme(AppThemeType.repartoGold);

      expect(tm.currentType, equals(AppThemeType.repartoGold));
      expect(tm.currentPalette.name, equals('Reparto Gold'));
      expect(tm.currentPalette.primary, equals(const Color(0xFFF2C94C)));
      expect(tm.currentPalette.background, equals(const Color(0xFF121212)));
      expect(tm.currentPalette.surface, equals(const Color(0xFF1E1E1E)));
      expect(tm.currentPalette.searchBarBackground, equals(const Color(0xFFF2C94C)));
      expect(tm.currentPalette.searchBarIcon, equals(const Color(0xFF000000)));
      expect(AppColors.primaryYellow, equals(const Color(0xFFF2C94C)));
    });

    test('2. Cambio a Midnight Blue notifica y actualiza tokens', () {
      final tm = ThemeManager.instance;
      bool notified = false;
      tm.addListener(() => notified = true);

      tm.setTheme(AppThemeType.midnightBlue);

      expect(notified, isTrue);
      expect(tm.currentType, equals(AppThemeType.midnightBlue));
      expect(tm.currentPalette.name, equals('Midnight Blue'));
      expect(tm.currentPalette.primary, equals(const Color(0xFF2563EB)));
      expect(tm.currentPalette.background, equals(const Color(0xFF1E222B)));
      expect(tm.currentPalette.surface, equals(const Color(0xFF2A2F3D)));
      expect(tm.currentPalette.searchBarBackground, equals(const Color(0xFF2A2F3D)));
      expect(tm.currentPalette.searchBarIcon, equals(const Color(0xFF2563EB)));
      expect(AppColors.primaryYellow, equals(const Color(0xFF2563EB)));
    });

    test('3. Cambio a Sweet Cream actualiza a tema claro/pastel', () {
      final tm = ThemeManager.instance;
      tm.setTheme(AppThemeType.sweetCream);

      expect(tm.currentType, equals(AppThemeType.sweetCream));
      expect(tm.currentPalette.name, equals('Sweet Cream'));
      expect(tm.currentPalette.isDark, isFalse);
      expect(tm.currentPalette.primary, equals(const Color(0xFFEC4899)));
      expect(tm.currentPalette.background, equals(const Color(0xFFECE5D8)));
      expect(tm.currentPalette.surface, equals(const Color(0xFFFFFFFF)));
      expect(tm.currentPalette.textPrimary, equals(const Color(0xFF1F1916)));
      expect(AppColors.textPrimary, equals(const Color(0xFF1F1916)));
    });

    test('4. Cambio a Emerald Mint actualiza a verde esmeralda y grafito', () {
      final tm = ThemeManager.instance;
      tm.setTheme(AppThemeType.emeraldMint);

      expect(tm.currentType, equals(AppThemeType.emeraldMint));
      expect(tm.currentPalette.name, equals('Emerald Mint'));
      expect(tm.currentPalette.isDark, isTrue);
      expect(tm.currentPalette.primary, equals(const Color(0xFF10B981)));
      expect(tm.currentPalette.background, equals(const Color(0xFF18181B)));
      expect(tm.currentPalette.surface, equals(const Color(0xFF27272A)));
      expect(AppColors.primaryYellow, equals(const Color(0xFF10B981)));
    });
  });
}
