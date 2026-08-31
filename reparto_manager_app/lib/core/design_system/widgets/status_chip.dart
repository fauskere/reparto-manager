import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum StatusChipType {
  // Estados de Visita
  visitVisited,
  visitNotVisited,
  visitPending,

  // Tipos de Cliente
  clientNormal,
  clientSpecial,
  clientReseller,

  // Estados de Pago / Venta
  paymentCash,
  paymentTransfer,
  paymentMixed,
  paymentPending,

  // Personalizado
  custom,
}

/// Chip de estado parametrizado para visitas, clientes y pagos.
class StatusChip extends StatelessWidget {
  final StatusChipType type;
  final String? customLabel;
  final IconData? customIcon;
  final Color? customColor;
  final bool isCompact;

  const StatusChip({
    super.key,
    required this.type,
    this.customLabel,
    this.customIcon,
    this.customColor,
    this.isCompact = false,
  });

  // Constructores fábrica para facilitar su uso directo
  factory StatusChip.visit(String status, {bool isCompact = false}) {
    switch (status.toLowerCase()) {
      case 'visited':
      case 'visitado':
        return StatusChip(type: StatusChipType.visitVisited, isCompact: isCompact);
      case 'pending':
      case 'pendiente':
        return StatusChip(type: StatusChipType.visitPending, isCompact: isCompact);
      case 'not_visited':
      case 'no_visitado':
      default:
        return StatusChip(type: StatusChipType.visitNotVisited, isCompact: isCompact);
    }
  }

  factory StatusChip.clientType(String clientType, {bool isCompact = false}) {
    switch (clientType.toLowerCase()) {
      case 'especial':
      case 'special':
        return StatusChip(type: StatusChipType.clientSpecial, isCompact: isCompact);
      case 'revendedor':
      case 'reseller':
        return StatusChip(type: StatusChipType.clientReseller, isCompact: isCompact);
      case 'normal':
      default:
        return StatusChip(type: StatusChipType.clientNormal, isCompact: isCompact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String label = _resolveLabel();
    final IconData icon = _resolveIcon();
    final Color color = _resolveColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
        vertical: isCompact ? 2.0 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 13.0 : 15.0, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: (isCompact ? AppTypography.bodySmall : AppTypography.badge).copyWith(
              color: color,
              fontSize: isCompact ? 13.0 : 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveLabel() {
    if (customLabel != null) return customLabel!;
    switch (type) {
      case StatusChipType.visitVisited:
        return 'Visitado';
      case StatusChipType.visitNotVisited:
        return 'No visitado';
      case StatusChipType.visitPending:
        return 'Pendiente';
      case StatusChipType.clientNormal:
        return 'Normal';
      case StatusChipType.clientSpecial:
        return 'Especial';
      case StatusChipType.clientReseller:
        return 'Revendedor';
      case StatusChipType.paymentCash:
        return 'Efectivo';
      case StatusChipType.paymentTransfer:
        return 'Transferencia';
      case StatusChipType.paymentMixed:
        return 'Mixto';
      case StatusChipType.paymentPending:
        return 'Cta. Cte.';
      case StatusChipType.custom:
        return '';
    }
  }

  IconData _resolveIcon() {
    if (customIcon != null) return customIcon!;
    switch (type) {
      case StatusChipType.visitVisited:
        return Icons.check_circle_rounded;
      case StatusChipType.visitNotVisited:
        return Icons.radio_button_unchecked_rounded;
      case StatusChipType.visitPending:
        return Icons.hourglass_top_rounded;
      case StatusChipType.clientNormal:
        return Icons.person_rounded;
      case StatusChipType.clientSpecial:
        return Icons.star_rounded;
      case StatusChipType.clientReseller:
        return Icons.storefront_rounded;
      case StatusChipType.paymentCash:
        return Icons.payments_rounded;
      case StatusChipType.paymentTransfer:
        return Icons.account_balance_rounded;
      case StatusChipType.paymentMixed:
        return Icons.pie_chart_rounded;
      case StatusChipType.paymentPending:
        return Icons.pending_actions_rounded;
      case StatusChipType.custom:
        return Icons.info_outline_rounded;
    }
  }

  Color _resolveColor() {
    if (customColor != null) return customColor!;
    switch (type) {
      case StatusChipType.visitVisited:
        return AppColors.visitVisited;
      case StatusChipType.visitNotVisited:
        return AppColors.visitNotVisited;
      case StatusChipType.visitPending:
        return AppColors.visitPending;
      case StatusChipType.clientNormal:
        return AppColors.clientNormal;
      case StatusChipType.clientSpecial:
        return AppColors.clientSpecial;
      case StatusChipType.clientReseller:
        return AppColors.clientReseller;
      case StatusChipType.paymentCash:
        return AppColors.success;
      case StatusChipType.paymentTransfer:
        return AppColors.info;
      case StatusChipType.paymentMixed:
        return AppColors.warning;
      case StatusChipType.paymentPending:
        return AppColors.danger;
      case StatusChipType.custom:
        return AppColors.primaryYellow;
    }
  }
}
