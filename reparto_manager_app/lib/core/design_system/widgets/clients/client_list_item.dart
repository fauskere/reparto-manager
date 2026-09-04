import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../app_card.dart';
import '../balance_badge.dart';

/// Ítem compacto de cliente para visualización en lista vertical.
/// Recibe datos puros y callbacks de acción.
class ClientListItem extends StatelessWidget {
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

  const ClientListItem({
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        borderColor: isVisited
            ? AppColors.success.withValues(alpha: 0.4)
            : isPassed
                ? AppColors.textMuted.withValues(alpha: 0.3)
                : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildClientInfo()),
              const SizedBox(width: AppSpacing.sm),
              _buildActionToolbar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isVisited
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.primaryYellow.withValues(alpha: 0.15),
          child: Icon(
            isVisited ? Icons.check_circle_rounded : Icons.person_rounded,
            color: isVisited ? AppColors.success : AppColors.primaryYellow,
            size: 22,
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
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isContinuous ? color : AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(
        isContinuous ? Icons.wb_sunny_rounded : Icons.access_time_rounded,
        size: 9.0,
        color: isContinuous ? Colors.black : color,
      ),
    );
  }

  Widget _buildClientInfo() {
    final bool hasNickname = nickname != null && nickname!.trim().isNotEmpty;
    final String displayName = hasNickname ? '$name ($nickname)' : name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: isPassed ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVisited) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '✓ ATENDIDO',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.3,
                ),
              ),
            ],
            if (isPassed) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '• PASADO',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (zone != null && zone!.isNotEmpty) ...[
              Text(
                zone!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primaryYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
            if (address != null && address!.isNotEmpty) ...[
              Expanded(
                child: Text(
                  address!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (!isContinuousSchedule) ...[
              const SizedBox(width: AppSpacing.xs),
              _buildNoonClosingBadge(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNoonClosingBadge() {
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
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildActionToolbar(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPassButton(),
        const SizedBox(width: AppSpacing.xs),
        BalanceBadge(
          balance: balance,
          size: BalanceBadgeSize.small,
        ),
        const SizedBox(width: AppSpacing.xs),
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
        if (onTap != null)
          Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
      ],
    );
  }

  Widget _buildPassButton() {
    if (isPassed) {
      return IconButton(
        icon: Icon(Icons.undo_rounded, size: 18, color: AppColors.info),
        tooltip: 'Deshacer pase',
        visualDensity: VisualDensity.compact,
        onPressed: onUndoPassed,
      );
    }

    return IconButton(
      icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
      tooltip: 'Pasar cliente',
      visualDensity: VisualDensity.compact,
      onPressed: onTogglePassed,
    );
  }
}
