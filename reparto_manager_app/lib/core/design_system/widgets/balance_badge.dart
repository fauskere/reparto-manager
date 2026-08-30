import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum BalanceBadgeSize {
  small,
  medium,
  large,
}

/// Badge financiero de saldo para clientes y comprobantes.
/// Visualiza con exactitud matemática el estado del saldo:
/// - Saldo == 0: "AL DÍA" / Neutro o Verde sutil.
/// - Saldo > 0: Deuda pendiente (Rojo).
/// - Saldo < 0: Saldo a favor (Verde).
class BalanceBadge extends StatelessWidget {
  final double balance;
  final BalanceBadgeSize size;
  final bool showLabel;
  final String? customLabel;

  const BalanceBadge({
    super.key,
    required this.balance,
    this.size = BalanceBadgeSize.medium,
    this.showLabel = true,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    final String formattedAmount = currencyFormat.format(balance.abs());
    final Color badgeColor = _resolveColor();
    final Color backgroundColor = badgeColor.withValues(alpha: 0.15);
    final String labelText = _resolveLabel();

    final EdgeInsets padding = _resolvePadding();
    final TextStyle amountStyle = _resolveAmountStyle(badgeColor);
    final TextStyle labelStyle = _resolveLabelStyle(badgeColor);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLabel && labelText.isNotEmpty) ...[
            Text(labelText, style: labelStyle),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            balance < 0 ? '-$formattedAmount' : formattedAmount,
            style: amountStyle,
          ),
        ],
      ),
    );
  }

  Color _resolveColor() {
    if (balance > 0.01) {
      return AppColors.danger; // Deuda pendiente
    } else if (balance < -0.01) {
      return AppColors.success; // Saldo a favor
    } else {
      return AppColors.success; // Al día ($0)
    }
  }

  String _resolveLabel() {
    if (customLabel != null) return customLabel!;
    if (balance > 0.01) {
      return 'DEUDA:';
    } else if (balance < -0.01) {
      return 'A FAVOR:';
    } else {
      return 'AL DÍA:';
    }
  }

  EdgeInsets _resolvePadding() {
    switch (size) {
      case BalanceBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs);
      case BalanceBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6.0);
      case BalanceBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
    }
  }

  TextStyle _resolveAmountStyle(Color color) {
    switch (size) {
      case BalanceBadgeSize.small:
        return AppTypography.badge.copyWith(color: color, fontWeight: FontWeight.w800);
      case BalanceBadgeSize.medium:
        return AppTypography.currencyMedium.copyWith(color: color);
      case BalanceBadgeSize.large:
        return AppTypography.currencyLarge.copyWith(color: color);
    }
  }

  TextStyle _resolveLabelStyle(Color color) {
    switch (size) {
      case BalanceBadgeSize.small:
        return AppTypography.bodySmall.copyWith(
          color: color.withValues(alpha: 0.8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );
      case BalanceBadgeSize.medium:
      case BalanceBadgeSize.large:
        return AppTypography.bodySmall.copyWith(
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
        );
    }
  }
}
