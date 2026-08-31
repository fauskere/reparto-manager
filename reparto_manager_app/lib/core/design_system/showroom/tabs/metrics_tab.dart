import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña de Métricas, Totales, Rankings y Avisos Semánticos.
class ShowroomMetricsTab extends StatelessWidget {
  const ShowroomMetricsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Tarjetas de Resumen (MetricSummaryCard)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: MetricSummaryCard(
                title: 'Total Ventas',
                amount: 485000.0,
                icon: Icons.trending_up_rounded,
                accentColor: AppColors.primaryYellow,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricSummaryCard(
                title: 'Efectivo',
                amount: 320000.0,
                icon: Icons.payments_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Top 5 Productos Más Vendidos (RankingItemRow)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        const AppCard(
          child: Column(
            children: [
              RankingItemRow(
                rank: 1,
                name: 'Soda Sifón 1.5L (Cajón x6)',
                value: 120,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Sifones',
              ),
              RankingItemRow(
                rank: 2,
                name: 'Bidón 20 Litros Retornable',
                value: 85,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Bidones',
              ),
              RankingItemRow(
                rank: 3,
                name: 'Agua Mineral 500ml Pack x12',
                value: 45,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Botellas',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Alertas Flotantes (AppSnackBar)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              text: 'Éxito',
              icon: Icons.check,
              onPressed: () => AppSnackBar.showSuccess(context, 'Cobro registrado correctamente'),
            ),
            AppButton(
              text: 'Error',
              variant: AppButtonVariant.danger,
              icon: Icons.error_outline,
              onPressed: () => AppSnackBar.showError(context, 'Error al conectar con la impresora'),
            ),
            AppButton(
              text: 'Aviso',
              variant: AppButtonVariant.secondary,
              icon: Icons.warning_amber,
              onPressed: () => AppSnackBar.showWarning(context, 'Cliente con deuda previa acumulada'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Estado Vacío (EmptyStateWidget)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        EmptyStateWidget(
          title: 'Sin clientes en esta zona',
          description: 'No se encontraron clientes registrados en la Zona Norte.',
          actionText: '+ Agregar Cliente',
          onAction: () => AppSnackBar.showSuccess(context, 'Nuevo cliente'),
        ),
      ],
    );
  }
}
