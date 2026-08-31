import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña de Catálogo, Productos y Variantes.
class ShowroomCatalogTab extends StatefulWidget {
  const ShowroomCatalogTab({super.key});

  @override
  State<ShowroomCatalogTab> createState() => _ShowroomCatalogTabState();
}

class _ShowroomCatalogTabState extends State<ShowroomCatalogTab> {
  String _selectedVariant = '20 Litros';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Selector de Variantes (VariantSelectorChips)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        VariantSelectorChips(
          variants: const ['12 Litros', '20 Litros', 'Retornable', 'Descartable'],
          selectedVariant: _selectedVariant,
          onVariantSelected: (v) => setState(() => _selectedVariant = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Tarjeta de POS (ProductCard)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82,
          children: [
            ProductCard(
              name: 'Soda Sifón 1.5L (Cajón x6)',
              price: 4500.0,
              category: 'Sifones',
              stock: 24,
              onAdd: () => AppSnackBar.showSuccess(context, 'Soda Sifón agregada'),
            ),
            ProductCard(
              name: 'Bidón 20 Litros Retornable',
              price: 3200.0,
              category: 'Bidones',
              stock: 3,
              onAdd: () => AppSnackBar.showSuccess(context, 'Bidón 20L agregado'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Modo Lista Rápida (ProductListItem)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        ProductListItem(
          name: 'Agua Mineral 500ml Pack x12',
          price: 6800.0,
          category: 'Botellas',
          stock: 40,
          onAdd: () => AppSnackBar.showSuccess(context, 'Pack Agua sumado'),
        ),
      ],
    );
  }
}
