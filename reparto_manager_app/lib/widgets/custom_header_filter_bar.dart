import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../modules/clients/v2/clients_actions_v2.dart';

enum FilterPeriodMode { day, week, month, year, all }

class CustomHeaderFilterBar extends StatelessWidget {
  // Configuración de elementos visibles
  final bool showPeriodDropdown;
  final bool enableDatePicker;
  final bool showSearchBar;
  final bool showZoneFilter;
  final bool showSortDropdown;
  final bool showCategoryFilter;

  // Estado y callbacks para Categorías (POS / Inventario / Catálogo)
  final String? selectedCategory;
  final List<String> categoriesList;
  final ValueChanged<String?>? onCategoryChanged;

  // Widgets Adicionales a la derecha (Botones "+ Agregar Cliente", etc.)
  final List<Widget> customTrailingWidgets;

  // Estado y callbacks para Periodo y Fecha
  final FilterPeriodMode periodMode;
  final DateTime anchorDate;
  final ValueChanged<FilterPeriodMode>? onPeriodModeChanged;
  final ValueChanged<DateTime>? onDateChanged;
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;

  // Estado y callbacks para Búsqueda
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  // Estado y callbacks para Zona
  final String? selectedZone;
  final ValueChanged<String?>? onZoneChanged;

  // Estado y callbacks para Ordenamiento (A-Z, Z-A, Saldo, etc.)
  final String? sortOption;
  final List<String> sortOptions;
  final ValueChanged<String?>? onSortChanged;

  const CustomHeaderFilterBar({
    super.key,
    this.showPeriodDropdown = false,
    this.enableDatePicker = false,
    this.showSearchBar = false,
    this.showZoneFilter = true,
    this.showSortDropdown = false,
    this.showCategoryFilter = false,
    this.selectedCategory,
    this.categoriesList = const ['Todas'],
    this.onCategoryChanged,
    this.customTrailingWidgets = const [],
    this.periodMode = FilterPeriodMode.day,
    required this.anchorDate,
    this.onPeriodModeChanged,
    this.onDateChanged,
    this.onNavigatePrevious,
    this.onNavigateNext,
    this.searchQuery = '',
    this.onSearchChanged,
    this.searchHint = 'Buscar...',
    this.selectedZone,
    this.onZoneChanged,
    this.sortOption,
    this.sortOptions = const ['A-Z', 'Z-A', 'Saldo'],
    this.onSortChanged,
  });

  bool get _isToday {
    final now = DateTime.now();
    return anchorDate.year == now.year &&
        anchorDate.month == now.month &&
        anchorDate.day == now.day;
  }

  String _periodLabel() {
    switch (periodMode) {
      case FilterPeriodMode.day:
        if (_isToday) return 'Hoy — ${DateFormat('d MMM yyyy', 'es_ES').format(anchorDate)}';
        return DateFormat('EEEE d MMM yyyy', 'es_ES').format(anchorDate);
      case FilterPeriodMode.week:
        final monday = anchorDate.subtract(Duration(days: anchorDate.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'es_ES').format(monday)} – ${DateFormat('d MMM yyyy', 'es_ES').format(sunday)}';
      case FilterPeriodMode.month:
        return DateFormat('MMMM yyyy', 'es_ES').format(anchorDate);
      case FilterPeriodMode.year:
        return anchorDate.year.toString();
      case FilterPeriodMode.all:
        return 'Historial completo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canNavigate = periodMode != FilterPeriodMode.all;
    final allZones = ['TODAS', ...ClientsActionsV2().cities];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Selector de Categorías (POS / Inventario / Catálogo)
          if (showCategoryFilter) ...[
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.primaryYellow,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  value: (selectedCategory != null && categoriesList.contains(selectedCategory)) ? selectedCategory : categoriesList.first,
                  items: categoriesList.map((cat) => DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(cat, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )).toList(),
                  onChanged: onCategoryChanged,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // 2. Selector de Período (Día/Semana/Mes/Año/Todo)
          if (showPeriodDropdown) ...[
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FilterPeriodMode>(
                  dropdownColor: AppTheme.primaryYellow,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  value: periodMode,
                  items: const [
                    DropdownMenuItem(value: FilterPeriodMode.day, child: Text("Día")),
                    DropdownMenuItem(value: FilterPeriodMode.week, child: Text("Semana")),
                    DropdownMenuItem(value: FilterPeriodMode.month, child: Text("Mes")),
                    DropdownMenuItem(value: FilterPeriodMode.year, child: Text("Año")),
                    DropdownMenuItem(value: FilterPeriodMode.all, child: Text("Todo")),
                  ],
                  onChanged: (val) {
                    if (val != null && onPeriodModeChanged != null) onPeriodModeChanged!(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // 3. Buscador
          if (showSearchBar) ...[
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.primaryYellow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // 4. Navegador de Fecha + Botón "HOY"
          if (enableDatePicker) ...[
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (canNavigate && onNavigatePrevious != null)
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: onNavigatePrevious,
                      ),

                    if (!_isToday && periodMode == FilterPeriodMode.day && onDateChanged != null) ...[
                      InkWell(
                        onTap: () => onDateChanged!(DateTime.now()),
                        child: Container(
                          margin: const EdgeInsets.only(left: 2, right: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "HOY",
                            style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                        ),
                      ),
                    ],

                    Expanded(
                      child: InkWell(
                        onTap: (periodMode == FilterPeriodMode.day && onDateChanged != null) ? () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: anchorDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('es', 'ES'),
                          );
                          if (picked != null) onDateChanged!(picked);
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.black, size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _periodLabel(),
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (canNavigate && onNavigateNext != null)
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: onNavigateNext,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // 5. Selector de Zona
          if (showZoneFilter) ...[
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.primaryYellow,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  hint: const Text("TODAS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  selectedItemBuilder: (context) {
                    return allZones.map((z) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          z,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      );
                    }).toList();
                  },
                  value: (selectedZone != null && allZones.contains(selectedZone)) ? selectedZone : 'TODAS',
                  items: allZones.map((z) => DropdownMenuItem<String>(
                    value: z,
                    child: Text(z, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  )).toList(),
                  onChanged: (val) {
                    if (onZoneChanged != null) {
                      onZoneChanged!(val == 'TODAS' ? null : val);
                    }
                  },
                ),
              ),
            ),
            if (showSortDropdown || customTrailingWidgets.isNotEmpty) const SizedBox(width: 6),
          ],

          // 6. Selector de Ordenamiento (A-Z / Z-A / Saldo)
          if (showSortDropdown) ...[
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.primaryYellow,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  value: sortOption,
                  items: sortOptions.map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  )).toList(),
                  onChanged: onSortChanged,
                ),
              ),
            ),
            if (customTrailingWidgets.isNotEmpty) const SizedBox(width: 6),
          ],

          // 7. Custom Trailing Widgets (Botones integrados)
          if (customTrailingWidgets.isNotEmpty) ...[
            ...customTrailingWidgets.map((w) => Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: w,
            )),
          ],
        ],
      ),
    );
  }
}
