import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña de estructura y encabezados comerciales.
class ShowroomStructureTab extends StatelessWidget {
  const ShowroomStructureTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Encabezados de Módulo (ModuleHeader)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ModuleHeader(
                title: 'Clientes',
                subtitle: '142 clientes activos • Zona Centro',
                actions: [
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: AppColors.primaryYellow),
                    onPressed: () => AppSnackBar.showSuccess(context, 'Filtros abiertos'),
                  ),
                  AppButton(
                    text: '+ Nuevo',
                    size: AppButtonSize.small,
                    onPressed: () => AppSnackBar.showSuccess(context, 'Crear cliente'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Títulos de Sección (SectionTitle)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              SectionTitle(
                title: 'Datos de Facturación ARCA',
                subtitle: 'Condición frente al IVA y CUIT',
                action: TextButton(
                  onPressed: () => AppSnackBar.showWarning(context, 'Editando AFIP'),
                  child: Text('Editar', style: TextStyle(color: AppColors.primaryYellow)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionTitle(
                title: 'Historial de Saldo y Comprobantes',
                subtitle: 'Eventos contables inmutables de los últimos 60 días',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
