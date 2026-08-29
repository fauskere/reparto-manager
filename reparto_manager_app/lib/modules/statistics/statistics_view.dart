import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../shell/app_drawer.dart';
import '../reports/reports_actions.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  bool _includeResellers = false;

  @override
  void initState() {
    super.initState();
    // Load initial data if needed (handled by ReportsActions usually)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Data is loaded by ReportsActions implicitly or we trigger a reload by setting period
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;
        final isPhone = constraints.maxWidth <= 500;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          drawer: isMobile ? const AppDrawer() : null,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Estadísticas / Pre-Carga', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: AppTheme.primaryYellow),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ReportsActions().setPeriod(ReportsActions().selectedPeriod),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) const SizedBox(width: 250, child: AppDrawer()),
              Expanded(
                child: ListenableBuilder(
                  listenable: ReportsActions(),
                  builder: (context, _) {
                    final actions = ReportsActions();

                    return Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderRow(actions, isPhone),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildStatisticsGrid(actions, isPhone),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(ReportsActions actions, bool isPhone) {
    final periods = ['Día', 'Semana', 'Mes', 'Historial'];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date Selector
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppTheme.primaryYellow,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              value: periods.contains(actions.selectedPeriod) ? actions.selectedPeriod : 'Día',
              items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) {
                if (val != null) {
                  actions.setPeriod(val);
                }
              },
            ),
          ),
        ),
        // Date Navigation
        if (actions.selectedPeriod != 'Historial')
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.primaryYellow),
                onPressed: () => actions.previousPeriod(),
              ),
              InkWell(
                onTap: () => _selectDate(context, actions),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryYellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPeriodText(actions.selectedPeriod, actions.currentReferenceDate),
                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow),
                onPressed: () => actions.nextPeriod(),
              ),
            ],
          ),
        // Resellers Toggle
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Incluir Revendedores', style: TextStyle(color: Colors.white, fontSize: 14)),
            Switch(
              value: _includeResellers,
              activeColor: AppTheme.primaryYellow,
              onChanged: (val) {
                setState(() => _includeResellers = val);
              },
            ),
          ],
        )
      ],
    );
  }

  String _getPeriodText(String period, DateTime date) {
    if (period == 'Día') return DateFormat('dd MMM yyyy', 'es_ES').format(date);
    if (period == 'Semana') {
      DateTime start = date.subtract(Duration(days: date.weekday - 1));
      DateTime end = start.add(const Duration(days: 6));
      return "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}";
    }
    if (period == 'Mes') return DateFormat('MMMM yyyy', 'es_ES').format(date).toUpperCase();
    return "Todos";
  }

  Future<void> _selectDate(BuildContext context, ReportsActions actions) async {
    if (actions.selectedPeriod == 'Historial') return;
    final picked = await showDatePicker(
      context: context,
      initialDate: actions.currentReferenceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryYellow,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      actions.setReferenceDate(picked);
    }
  }

  Widget _buildStatisticsGrid(ReportsActions actions, bool isPhone) {
    // Calcular estadísticas
    Map<String, int> productRanking = {};
    int totalItems = 0;

    for (var sale in actions.sales) {
      if (!_includeResellers && sale.city?.toLowerCase() == 'vendedores') {
        continue; // Ignorar revendedores si el switch está apagado
      }
      for (var item in sale.items) {
        String name = item.product.name;
        if (item.selectedVariant != null && item.selectedVariant!.name.isNotEmpty && item.selectedVariant!.name != 'Única') {
          name += " ${item.selectedVariant!.name}";
        }
        productRanking[name] = (productRanking[name] ?? 0) + item.quantity;
        totalItems += item.quantity;
      }
    }

    var sortedRanking = productRanking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedRanking.isEmpty) {
      return const Center(
        child: Text("No hay datos para el período seleccionado", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total de productos vendidos: $totalItems",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPhone ? 2 : 4,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sortedRanking.length,
            itemBuilder: (context, index) {
              final item = sortedRanking[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item.value}",
                        style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
