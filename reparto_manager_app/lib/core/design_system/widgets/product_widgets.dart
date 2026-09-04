// lib/core/design_system/widgets/product_widgets.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';

export 'product_card.dart';

/// Fila compacta de producto para modo lista rápida en mostrador.
class ProductListItem extends StatelessWidget {
  final String name;
  final double price;
  final String? category;
  final int? stock;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const ProductListItem({
    super.key,
    required this.name,
    required this.price,
    this.category,
    this.stock,
    this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (category != null && category!.isNotEmpty) ...[
                      Text(
                        category!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (stock != null)
                      Text(
                        'Stock: $stock',
                        style: AppTypography.bodySmall.copyWith(
                          color: stock! <= 3 ? AppColors.warning : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            currency.format(price),
            style: AppTypography.currencyMedium.copyWith(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Material(
            color: AppColors.primaryYellow,
            borderRadius: AppSpacing.borderRadiusSm,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.textOnPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de variantes, sabores o tamaños con chips tildables.
class VariantSelectorChips extends StatelessWidget {
  final List<String> variants;
  final String selectedVariant;
  final ValueChanged<String> onVariantSelected;

  const VariantSelectorChips({
    super.key,
    required this.variants,
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: variants.map((variant) {
        final isSelected = selectedVariant == variant;
        return FilterChip(
          label: Text(variant),
          selected: isSelected,
          onSelected: (_) => onVariantSelected(variant),
          selectedColor: AppColors.primaryYellow,
          backgroundColor: AppColors.surfaceDarkElevated,
          labelStyle: TextStyle(
            fontSize: 13.0,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.3,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
          checkmarkColor: AppColors.textOnPrimary,
          side: BorderSide(
            color: isSelected ? AppColors.primaryYellow : AppColors.borderSubtle,
          ),
        );
      }).toList(),
    );
  }
}
