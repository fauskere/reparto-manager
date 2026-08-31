import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import 'app_text_field.dart';

enum FilterPeriod { dia, semana, mes, ano, todo }

/// Barra de filtros universal reutilizable para POS, Reportes, Clientes e Inventario.
class AppHeaderFilterBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateChanged;
  final FilterPeriod selectedPeriod;
  final ValueChanged<FilterPeriod>? onPeriodChanged;
  final String? selectedZone;
  final List<String> zones;
  final ValueChanged<String?>? onZoneChanged;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String?>? onCategoryChanged;
  final bool showSearch;
  final bool showPeriod;
  final bool showDateNav;
  final bool showZones;
  final bool showCategories;

  const AppHeaderFilterBar({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
    this.selectedPeriod = FilterPeriod.dia,
    this.onPeriodChanged,
    this.selectedZone,
    this.zones = const [],
    this.onZoneChanged,
    this.searchController,
    this.onSearchChanged,
    this.onClearSearch,
    this.selectedCategory,
    this.categories = const [],
    this.onCategoryChanged,
    this.showSearch = true,
    this.showPeriod = true,
    this.showDateNav = true,
    this.showZones = true,
    this.showCategories = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showPeriod) _buildPeriodSelector(),
              if (showDateNav) _buildDateNavigator(context),
              if (showZones) _buildZoneSelector(),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSearchBar(),
          ],
          if (showCategories && categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildCategoryChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      FilterPeriod.dia,
      FilterPeriod.semana,
      FilterPeriod.mes,
      FilterPeriod.ano,
      FilterPeriod.todo,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          final isSelected = selectedPeriod == p;
          return Material(
            color: isSelected ? AppColors.primaryYellow : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            child: InkWell(
              onTap: () => onPeriodChanged?.call(p),
              borderRadius: AppSpacing.borderRadiusSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  _periodLabel(p),
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateNavigator(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM', 'es_ES');
    final formattedDate = dateFormat.format(selectedDate);
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavButton(
          icon: Icons.chevron_left_rounded,
          onPressed: () => onDateChanged?.call(selectedDate.subtract(const Duration(days: 1))),
        ),
        const SizedBox(width: 2),
        Material(
          color: isToday ? AppColors.primaryYellow : AppColors.surfaceDarkElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) onDateChanged?.call(picked);
            },
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isToday ? AppColors.textOnPrimary : AppColors.primaryYellow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isToday ? 'HOY ($formattedDate)' : formattedDate.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: isToday ? AppColors.textOnPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        _buildNavButton(
          icon: Icons.chevron_right_rounded,
          onPressed: () => onDateChanged?.call(selectedDate.add(const Duration(days: 1))),
        ),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: AppColors.backgroundDark,
      borderRadius: AppSpacing.borderRadiusSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: AppColors.primaryYellow, size: 20),
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    final allOptions = ['TODAS', ...zones];
    final current = selectedZone ?? 'TODAS';

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: allOptions.contains(current) ? current : 'TODAS',
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryYellow),
          dropdownColor: AppColors.surfaceDarkElevated,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (val) => onZoneChanged?.call(val == 'TODAS' ? null : val),
          items: allOptions.map((zone) {
            return DropdownMenuItem<String>(
              value: zone,
              child: Text(
                zone,
                style: TextStyle(
                  color: zone == 'TODAS' ? AppColors.primaryYellow : AppColors.textPrimary,
                  fontWeight: zone == 'TODAS' ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                  fontSize: 13.5,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppTextField(
      hintText: 'Buscar por nombre, zona o comprobante...',
      controller: searchController,
      onChanged: onSearchChanged,
      fillColor: AppColors.searchBarBackground,
      textColor: AppColors.searchBarText,
      hintColor: AppColors.searchBarPlaceholder,
      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.searchBarIcon),
      suffixIcon: (searchController?.text.isNotEmpty ?? false)
          ? IconButton(
              icon: Icon(Icons.clear, size: 18, color: AppColors.searchBarIcon),
              onPressed: onClearSearch,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    );
  }

  Widget _buildCategoryChips() {
    final allCats = ['Todas', ...categories];
    final active = selectedCategory ?? 'Todas';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allCats.map((cat) {
          final isSelected = active == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged?.call(cat == 'Todas' ? null : cat),
              selectedColor: AppColors.primaryYellow,
              backgroundColor: AppColors.backgroundDark,
              labelStyle: TextStyle(
                fontSize: 13.0,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
              checkmarkColor: AppColors.textOnPrimary,
              side: BorderSide(
                color: isSelected ? AppColors.primaryYellow : AppColors.borderSubtle,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _periodLabel(FilterPeriod p) {
    switch (p) {
      case FilterPeriod.dia:
        return 'Día';
      case FilterPeriod.semana:
        return 'Semana';
      case FilterPeriod.mes:
        return 'Mes';
      case FilterPeriod.ano:
        return 'Año';
      case FilterPeriod.todo:
        return 'Todo';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
