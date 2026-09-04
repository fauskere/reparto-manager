import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../app_card.dart';

/// Tarjeta estructurada de cliente para grillas (modo 2 columnas).
/// Presenta los datos y acciones en un formato de tarjeta visual con los colores del tema.
class ClientCardItem extends StatelessWidget {
  final String name;
  final String? nickname;
  final String? address;
  final String? zone;
  final double balance;
  final bool isContinuousSchedule;
  final bool isVisited;
  final bool isPassed;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePassed;
  final VoidCallback? onUndoPassed;
  final VoidCallback? onToggleSchedule;

  const ClientCardItem({
    super.key,
    required this.name,
    this.nickname,
    this.address,
    this.zone,
    required this.balance,
    this.isContinuousSchedule = true,
    this.isVisited = false,
    this.isPassed = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onTogglePassed,
    this.onUndoPassed,
    this.onToggleSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDimmed = isVisited || isPassed;
    final double opacity = isDimmed ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: isVisited
            ? AppColors.success.withValues(alpha: 0.4)
            : isPassed
                ? AppColors.textMuted.withValues(alpha: 0.3)
                : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.sm),
              _buildAddressInfo(),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              _buildFooterActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasNickname = nickname != null && nickname!.trim().isNotEmpty;
    final String displayName = hasNickname ? '$name ($nickname)' : name;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: isPassed ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (zone != null && zone!.isNotEmpty)
                Text(
                  zone!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        _buildSimpleBalanceBadge(balance),
      ],
    );
  }

  Widget _buildAvatar() {
    return InkWell(
      onTap: onToggleSchedule,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isVisited
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.primaryYellow.withValues(alpha: 0.15),
            child: Icon(
              isVisited ? Icons.check_circle_rounded : Icons.person_rounded,
              color: isVisited ? AppColors.success : AppColors.primaryYellow,
              size: 20,
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: _buildScheduleBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBadge() {
    final bool isContinuous = isContinuousSchedule;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryYellow, width: 1.5),
      ),
      child: Icon(
        isContinuous ? Icons.storefront_rounded : Icons.access_time_rounded,
        size: 9.0,
        color: AppColors.primaryYellow,
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            address ?? 'Sin dirección',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isContinuousSchedule) ...[
          const SizedBox(width: AppSpacing.xs),
          _buildNoonClosingChip(),
        ],
      ],
    );
  }

  Widget _buildNoonClosingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Cierra mediodía',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryYellow,
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPassButton(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryYellow),
              tooltip: 'Editar datos',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              tooltip: 'Eliminar cliente',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primaryYellow),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPassButton() {
    if (isPassed) {
      return TextButton.icon(
        icon: Icon(Icons.undo_rounded, size: 15, color: AppColors.primaryYellow),
        label: Text('Deshacer', style: TextStyle(color: AppColors.primaryYellow, fontSize: 12)),
        onPressed: onUndoPassed,
      );
    }

    return TextButton.icon(
      icon: Icon(Icons.close_rounded, size: 15, color: AppColors.primaryYellow),
      label: Text('Pasar', style: TextStyle(color: AppColors.primaryYellow, fontSize: 12)),
      onPressed: onTogglePassed,
    );
  }

  Widget _buildSimpleBalanceBadge(double amount) {
    final currencyFormat = NumberFormat('#,##0', 'es_AR');
    final bool hasDebt = amount > 0;
    final bool hasCredit = amount < 0;

    final Color color = hasDebt
        ? AppColors.danger
        : hasCredit
            ? AppColors.success
            : AppColors.textSecondary;

    final String formattedNumber = currencyFormat.format(amount.abs());
    final String text = hasCredit ? '-$formattedNumber\$' : '$formattedNumber\$';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
