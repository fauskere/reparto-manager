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

enum PaymentMethod { efectivo, transferencia, mixto, pendiente }

/// Selector visual con botones grandes táctiles de medios de pago.
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildMethodButton(
          method: PaymentMethod.efectivo,
          label: 'Efectivo',
          icon: Icons.payments_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMethodButton(
          method: PaymentMethod.transferencia,
          label: 'Transfer.',
          icon: Icons.account_balance_rounded,
          color: AppColors.info,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMethodButton(
          method: PaymentMethod.mixto,
          label: 'Mixto',
          icon: Icons.pie_chart_rounded,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMethodButton(
          method: PaymentMethod.pendiente,
          label: 'Fiado (Deuda)',
          icon: Icons.pending_actions_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildMethodButton({
    required PaymentMethod method,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMethod == method;

    return Expanded(
      child: Material(
        color: isSelected ? color : AppColors.surfaceDarkElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          onTap: () => onMethodChanged(method),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isSelected ? color : AppColors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.textOnPrimary : color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Caja de desglose contable en vivo (Matemática estricta de saldos).
class PaymentSummaryBox extends StatelessWidget {
  final double previousBalance;
  final double saleTotal;
  final double paidAmount;

  const PaymentSummaryBox({
    super.key,
    required this.previousBalance,
    required this.saleTotal,
    required this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);
    final remainingDebtGenerated = saleTotal - paidAmount;
    final finalBalance = previousBalance + remainingDebtGenerated;

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Column(
        children: [
          _buildRow('Saldo Anterior:', currency.format(previousBalance),
              color: previousBalance > 0 ? AppColors.danger : AppColors.textSecondary),
          Divider(height: 12, color: AppColors.borderSubtle),
          _buildRow('Total Venta Actual:', currency.format(saleTotal),
              color: AppColors.primaryYellow, isBold: true),
          const SizedBox(height: 4),
          _buildRow('Monto Abonado:', currency.format(paidAmount),
              color: AppColors.success, isBold: true),
          Divider(height: 12, color: AppColors.borderSubtle),
          _buildRow(
            'Saldo Final Resultante:',
            currency.format(finalBalance),
            color: finalBalance > 0 ? AppColors.danger : AppColors.success,
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {Color? color, bool isBold = false, double fontSize = 13.5}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.3,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Calculadora táctil de billetes rápidos para cálculo instantáneo de vuelto.
class QuickCashCalculator extends StatelessWidget {
  final double totalToPay;
  final ValueChanged<double> onAmountSelected;

  const QuickCashCalculator({
    super.key,
    required this.totalToPay,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bills = [1000.0, 2000.0, 5000.0, 10000.0, 20000.0];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _buildBillButton(
          label: 'Exacto',
          amount: totalToPay,
          isExact: true,
        ),
        ...bills.map((b) => _buildBillButton(label: '\$${b.toInt()}', amount: b)),
      ],
    );
  }

  Widget _buildBillButton({
    required String label,
    required double amount,
    bool isExact = false,
  }) {
    return Material(
      color: isExact ? AppColors.primaryYellow : AppColors.surfaceDarkElevated,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: () => onAmountSelected(amount),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: isExact ? AppColors.textOnPrimary : AppColors.primaryYellow,
            ),
          ),
        ),
      ),
    );
  }
}
