import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../app_button.dart';

/// Barra inferior fija para la pantalla de clientes.
/// Muestra el botón de acción principal para crear clientes y el balance total adeudado.
class ClientsBottomBar extends StatelessWidget {
  final double totalDebt;
  final VoidCallback? onAddClient;

  const ClientsBottomBar({
    super.key,
    required this.totalDebt,
    this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    final String formattedDebt = currencyFormat.format(totalDebt.abs());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAddButton(),
            const SizedBox(width: AppSpacing.md),
            _buildTotalDebtCard(formattedDebt),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return AppButton(
      text: '+ AGREGAR CLIENTE',
      icon: Icons.person_add_alt_1_rounded,
      size: AppButtonSize.medium,
      onPressed: onAddClient,
    );
  }

  Widget _buildTotalDebtCard(String formattedDebt) {
    final bool hasDebt = totalDebt > 0;
    final Color debtColor = hasDebt ? AppColors.danger : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: debtColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDebt ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: debtColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Adeudado:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formattedDebt,
                style: AppTypography.currencyMedium.copyWith(
                  color: debtColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
