import 'package:flutter/material.dart';
import '../design_system.dart';
import 'tabs/catalog_tab.dart';
import 'tabs/checkout_tab.dart';
import 'tabs/filters_tab.dart';
import 'tabs/metrics_tab.dart';
import 'tabs/structure_tab.dart';

/// Galería Visual y Showroom interactivo de Reparto-Manager V2.
/// Incluye selector de temas dinámicos en vivo y vista de todos los módulos atómicos.
class DesignSystemShowroomView extends StatefulWidget {
  const DesignSystemShowroomView({super.key});

  @override
  State<DesignSystemShowroomView> createState() => _DesignSystemShowroomViewState();
}

class _DesignSystemShowroomViewState extends State<DesignSystemShowroomView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            title: Text('Design System Showroom V2', style: AppTypography.h3),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Column(
                children: [
                  _buildThemeSelectorBar(),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.primaryYellow,
                    labelColor: AppColors.primaryYellow,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(icon: Icon(Icons.view_quilt_outlined), text: 'Estructura'),
                      Tab(icon: Icon(Icons.storefront_outlined), text: 'Catálogo & Productos'),
                      Tab(icon: Icon(Icons.filter_alt_outlined), text: 'Filtros'),
                      Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Caja & Cobro'),
                      Tab(icon: Icon(Icons.insights_outlined), text: 'Métricas & Avisos'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              ShowroomStructureTab(),
              ShowroomCatalogTab(),
              ShowroomFiltersTab(),
              ShowroomCheckoutTab(),
              ShowroomMetricsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectorBar() {
    final current = ThemeManager.instance.currentType;

    return Container(
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: Row(
        children: [
          Text(
            'Temas:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _themeChip('🟡 Reparto Gold', AppThemeType.repartoGold, current),
                  const SizedBox(width: 6),
                  _themeChip('🔵 Midnight Blue', AppThemeType.midnightBlue, current),
                  const SizedBox(width: 6),
                  _themeChip('🌸 Sweet Cream', AppThemeType.sweetCream, current),
                  const SizedBox(width: 6),
                  _themeChip('🟢 Emerald Mint', AppThemeType.emeraldMint, current),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeChip(String label, AppThemeType type, AppThemeType current) {
    final isSelected = current == type;

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
      ),
      backgroundColor: isSelected ? AppColors.primaryYellow : AppColors.surfaceDarkElevated,
      side: BorderSide(
        color: isSelected ? AppColors.primaryYellow : AppColors.borderSubtle,
        width: 1.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () {
        ThemeManager.instance.setTheme(type);
        AppSnackBar.showSuccess(
          context,
          'Tema activado: ${ThemeManager.instance.currentPalette.name}',
        );
      },
    );
  }
}
