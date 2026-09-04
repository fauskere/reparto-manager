// lib/core/design_system/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';

/// Tarjeta visual de producto para el POS en cuadrícula.
class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String? category;
  final String? imageUrl;
  final int? stock;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.category,
    this.imageUrl,
    this.stock,
    this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                if (stock != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: _buildStockBadge(stock!),
                  ),
                if (category != null && category!.isNotEmpty)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _buildCategoryBadge(category!),
                  ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTypography.h4.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        currency.format(price),
                        style: AppTypography.currencyMedium.copyWith(
                          color: AppColors.primaryYellow,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildAddButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceDarkElevated,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStockBadge(int count) {
    final Color badgeColor = count <= 0
        ? AppColors.danger
        : (count <= 5 ? AppColors.warning : AppColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.85),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        count <= 0 ? 'Sin stock' : '$count u.',
        style: TextStyle(
          color: badgeColor,
          fontSize: 13.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.85),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Text(
        cat.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: AppColors.primaryYellow,
      borderRadius: AppSpacing.borderRadiusMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.add_rounded,
            color: AppColors.textOnPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
