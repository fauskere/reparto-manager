import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../modules/clients/v2/clients_actions_v2.dart';

enum FilterPeriodMode { day, week, month, year, all }

class DateZoneFilterBar extends StatelessWidget {
  final FilterPeriodMode mode;
  final DateTime anchorDate;
  final String? selectedZone;
  final ValueChanged<FilterPeriodMode>? onModeChanged;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<String?>? onZoneChanged;
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;
  final bool showZoneFilter;

  const DateZoneFilterBar({
    super.key,
    required this.mode,
    required this.anchorDate,
    this.selectedZone,
    this.onModeChanged,
    this.onDateChanged,
    this.onZoneChanged,
    this.onNavigatePrevious,
    this.onNavigateNext,
    this.showZoneFilter = true,
  });

  bool get _isToday {
    final now = DateTime.now();
    return anchorDate.year == now.year &&
        anchorDate.month == now.month &&
        anchorDate.day == now.day;
  }

  String _periodLabel() {
    switch (mode) {
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
    final canNavigate = mode != FilterPeriodMode.all;
    final allZones = ['TODAS', ...ClientsActionsV2().zones];

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
          // Selector de Período
          Container(
            height: 36,
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
                value: mode,
                items: const [
                  DropdownMenuItem(value: FilterPeriodMode.day, child: Text("Día")),
                  DropdownMenuItem(value: FilterPeriodMode.week, child: Text("Semana")),
                  DropdownMenuItem(value: FilterPeriodMode.month, child: Text("Mes")),
                  DropdownMenuItem(value: FilterPeriodMode.year, child: Text("Año")),
                  DropdownMenuItem(value: FilterPeriodMode.all, child: Text("Todo")),
                ],
                onChanged: (val) {
                  if (val != null && onModeChanged != null) onModeChanged!(val);
                },
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Navegador de Fecha + Botón "HOY"
          Expanded(
            child: Container(
              height: 36,
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
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onNavigatePrevious,
                    ),

                  // Botón "HOY" cuando no estamos en hoy
                  if (!_isToday && mode == FilterPeriodMode.day && onDateChanged != null) ...[
                    InkWell(
                      onTap: () => onDateChanged!(DateTime.now()),
                      child: Container(
                        margin: const EdgeInsets.only(left: 4, right: 4),
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
                      onTap: (mode == FilterPeriodMode.day && onDateChanged != null) ? () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: anchorDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('es', 'ES'),
                        );
                        if (picked != null) onDateChanged!(picked);
                      } : null,
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

                  if (canNavigate && onNavigateNext != null)
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onNavigateNext,
                    ),
                ],
              ),
            ),
          ),

          // Selector de Zona opcional
          if (showZoneFilter) ...[
            const SizedBox(width: 6),
            Container(
              height: 36,
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
          ],
        ],
      ),
    );
  }
}
