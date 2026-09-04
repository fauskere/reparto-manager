// lib/core/design_system/widgets/ranking_item_row.dart
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Fila para ranking Top 10 con medalla/puesto, datos y barra de progreso.
class RankingItemRow extends StatelessWidget {
  final int rank;
  final String name;
  final double value;
  final double maxValue;
  final String? secondaryInfo;
  final bool isCurrency;

  const RankingItemRow({
    super.key,
    required this.rank,
    required this.name,
    required this.value,
    required this.maxValue,
    this.secondaryInfo,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final formattedValue = isCurrency ? '\$${value.toStringAsFixed(0)}' : '${value.toInt()} u.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRankBadge(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryInfo != null)
                      Text(
                        secondaryInfo!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                formattedValue,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceDarkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                rank <= 3 ? AppColors.primaryYellow : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor = AppColors.surfaceDarkElevated;
    Color textColor = AppColors.textSecondary;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700);
      textColor = Colors.black;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0);
      textColor = Colors.black;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32);
      textColor = Colors.black;
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 13.0,
          ),
        ),
      ),
    );
  }
}
