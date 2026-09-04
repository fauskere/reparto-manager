import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../app_card.dart';
import '../balance_badge.dart';

/// Tarjeta estructurada de cliente para grillas (modo 2 columnas).
/// Presenta los datos y acciones en un formato de tarjeta visual.
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
              const SizedBox(height: AppSpacing.md),
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
        BalanceBadge(balance: balance, size: BalanceBadgeSize.small),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
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
    );
  }

  Widget _buildScheduleBadge() {
    final bool isContinuous = isContinuousSchedule;
    final color = isContinuous ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: isContinuous ? color : AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(
        isContinuous ? Icons.wb_sunny_rounded : Icons.access_time_rounded,
        size: 8.0,
        color: isContinuous ? Colors.black : color,
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
            address ?? 'Sin dirección especificada',
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Cierra mediodía',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
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
              icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
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
        icon: Icon(Icons.undo_rounded, size: 14, color: AppColors.info),
        label: Text('Deshacer', style: TextStyle(color: AppColors.info, fontSize: 12)),
        onPressed: onUndoPassed,
      );
    }

    return TextButton.icon(
      icon: Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
      label: Text('Pasar', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      onPressed: onTogglePassed,
    );
  }
}
