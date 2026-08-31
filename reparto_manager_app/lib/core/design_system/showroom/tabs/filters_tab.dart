import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña de Barra Universal de Filtros y Búsqueda Adaptativa.
class ShowroomFiltersTab extends StatefulWidget {
  const ShowroomFiltersTab({super.key});

  @override
  State<ShowroomFiltersTab> createState() => _ShowroomFiltersTabState();
}

class _ShowroomFiltersTabState extends State<ShowroomFiltersTab> {
  DateTime _filterDate = DateTime.now();
  FilterPeriod _filterPeriod = FilterPeriod.dia;
  String? _filterZone;
  String? _filterCategory;
  final TextEditingController _filterSearchController = TextEditingController();

  @override
  void dispose() {
    _filterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Barra Universal de Filtros (AppHeaderFilterBar)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppHeaderFilterBar(
          selectedDate: _filterDate,
          onDateChanged: (d) => setState(() => _filterDate = d),
          selectedPeriod: _filterPeriod,
          onPeriodChanged: (p) => setState(() => _filterPeriod = p),
          selectedZone: _filterZone,
          zones: const ['Centro', 'Norte', 'Sur', 'Ruta 188', 'Lincoln'],
          onZoneChanged: (z) => setState(() => _filterZone = z),
          searchController: _filterSearchController,
          onSearchChanged: (q) => setState(() {}),
          onClearSearch: () => setState(() => _filterSearchController.clear()),
          showCategories: true,
          categories: const ['Sifones', 'Bidones', 'Máquinas', 'Repuestos'],
          selectedCategory: _filterCategory,
          onCategoryChanged: (c) => setState(() => _filterCategory = c),
        ),
      ],
    );
  }
}
