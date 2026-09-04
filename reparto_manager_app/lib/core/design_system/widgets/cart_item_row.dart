// lib/core/design_system/widgets/cart_item_row.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';

/// Renglón de producto agregado al carrito de compras con control táctil de cantidad.
class CartItemRow extends StatelessWidget {
  final String productName;
  final double unitPrice;
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;

  const CartItemRow({
    super.key,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final subtotal = unitPrice * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currency.format(unitPrice)} c/u',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _buildQuantitySelector(),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 80,
              child: Text(
                currency.format(subtotal),
                textAlign: TextAlign.right,
                style: AppTypography.currencyMedium.copyWith(
                  color: AppColors.primaryYellow,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyButton(
            icon: Icons.remove_rounded,
            onPressed: () {
              if (quantity > 1) {
                onQuantityChanged?.call(quantity - 1);
              } else {
                onRemove?.call();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildQtyButton(
            icon: Icons.add_rounded,
            onPressed: () => onQuantityChanged?.call(quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.primaryYellow),
        ),
      ),
    );
  }
}
