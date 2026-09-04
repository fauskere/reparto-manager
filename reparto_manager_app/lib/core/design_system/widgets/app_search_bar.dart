// lib/core/design_system/widgets/app_search_bar.dart
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import 'app_text_field.dart';

/// Barra de búsqueda estándar para Reparto-Manager V2.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Buscar por nombre, zona o comprobante...',
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
      fillColor: AppColors.searchBarBackground,
      textColor: AppColors.searchBarText,
      hintColor: AppColors.searchBarPlaceholder,
      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.searchBarIcon),
      suffixIcon: (controller?.text.isNotEmpty ?? false)
          ? IconButton(
              icon: Icon(Icons.clear, size: 18, color: AppColors.searchBarIcon),
              onPressed: onClear,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    );
  }
}
