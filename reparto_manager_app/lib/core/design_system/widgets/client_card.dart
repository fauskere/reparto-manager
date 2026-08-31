import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';
import 'balance_badge.dart';
import 'status_chip.dart';

/// Tarjeta de cliente oficial de Reparto-Manager V2.
/// Diseñada para visualización rápida y táctil en calle y mostrador.
class ClientCard extends StatelessWidget {
  final String name;
  final String? address;
  final String? zone;
  final String? phone;
  final String? imageUrl;
  final String clientType; // 'normal', 'especial', 'revendedor'
  final String visitStatus; // 'visited', 'not_visited', 'pending'
  final double balance;
  final VoidCallback? onTap;
  final VoidCallback? onPosAction;
  final VoidCallback? onPhoneTap;
  final bool isHighlighted;

  const ClientCard({
    super.key,
    required this.name,
    this.address,
    this.zone,
    this.phone,
    this.imageUrl,
    this.clientType = 'normal',
    this.visitStatus = 'not_visited',
    required this.balance,
    this.onTap,
    this.onPosAction,
    this.onPhoneTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      isHighlighted: isHighlighted,
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    _buildSubtitle(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              BalanceBadge(
                balance: balance,
                size: BalanceBadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusChip.clientType(clientType, isCompact: true),
              const SizedBox(width: AppSpacing.xs),
              StatusChip.visit(visitStatus, isCompact: true),
              const Spacer(),
              if (phone != null && phone!.isNotEmpty) ...[
                _buildIconButton(
                  icon: Icons.phone_rounded,
                  color: AppColors.success,
                  onPressed: onPhoneTap,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (onPosAction != null)
                _buildPosActionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: _resolveAvatarBorderColor(),
          width: 1.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildInitials(),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: AppTypography.h4.copyWith(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    final List<String> parts = [];
    if (zone != null && zone!.isNotEmpty) parts.add(zone!);
    if (address != null && address!.isNotEmpty) parts.add(address!);

    final String subtitleText = parts.isNotEmpty ? parts.join(' • ') : 'Sin dirección';

    return Text(
      subtitleText,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18.0, color: color),
        ),
      ),
    );
  }

  Widget _buildPosActionButton() {
    return Material(
      color: AppColors.primaryYellow,
      borderRadius: AppSpacing.borderRadiusSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPosAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.point_of_sale_rounded, size: 14.0, color: AppColors.textOnPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'POS',
                style: AppTypography.badge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _resolveAvatarBorderColor() {
    switch (visitStatus.toLowerCase()) {
      case 'visited':
      case 'visitado':
        return AppColors.visitVisited;
      case 'pending':
      case 'pendiente':
        return AppColors.visitPending;
      default:
        return AppColors.primaryYellow.withValues(alpha: 0.5);
    }
  }
}
