import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';
import '../../models/sale.dart';
import '../clients/client.dart';
import '../pos/pos_actions.dart';
import '../shell/app_shell.dart';
import 'reports_actions.dart';
import '../clients/v2/clients_actions_v2.dart';
import '../clients/client_groups_actions.dart';
import '../shell/app_drawer.dart';
import '../printer/printer_actions.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_header_filter_bar.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _historyMode = 0; // 0 = Tickets, 1 = Entradas de Dinero
  bool _showMetrics = true;

  @override
  void initState() {
    super.initState();
    _showMetrics = PreferencesService().getBool('reports_show_metrics') ?? true;
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        ReportsActions().loadMoreSales();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;
        final isPhone = constraints.maxWidth <= 500;

        return ListenableBuilder(
          listenable: Listenable.merge([ReportsActions(), ClientsActionsV2()]),
          builder: (context, child) {
            final actions = ReportsActions();
            final sales = actions.sales.where((s) => 
              (s.clientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) || 
              s.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.city ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
            final periods = ['Día', 'Semana', 'Mes', 'Historial'];
            
            final cities = ['Todas las ciudades'];
            cities.addAll(ClientsActionsV2().cities);

            FilterPeriodMode mappedPeriod = FilterPeriodMode.day;
            if (actions.selectedPeriod == 'Semana') mappedPeriod = FilterPeriodMode.week;
            if (actions.selectedPeriod == 'Mes') mappedPeriod = FilterPeriodMode.month;
            if (actions.selectedPeriod == 'Año') mappedPeriod = FilterPeriodMode.year;
            if (actions.selectedPeriod == 'Historial') mappedPeriod = FilterPeriodMode.all;

            final mainFilterBar = CustomHeaderFilterBar(
              showPeriodDropdown: true,
              periodMode: mappedPeriod,
              onPeriodModeChanged: (mode) {
                switch (mode) {
                  case FilterPeriodMode.day: actions.setPeriod('Día'); break;
                  case FilterPeriodMode.week: actions.setPeriod('Semana'); break;
                  case FilterPeriodMode.month: actions.setPeriod('Mes'); break;
                  case FilterPeriodMode.year: actions.setPeriod('Año'); break;
                  case FilterPeriodMode.all: actions.setPeriod('Historial'); break;
                }
              },
              enableDatePicker: true,
              anchorDate: actions.currentReferenceDate,
              onDateChanged: (d) => actions.setReferenceDate(d),
              onNavigatePrevious: () => actions.previousPeriod(),
              onNavigateNext: () => actions.nextPeriod(),
              showZoneFilter: true,
              selectedZone: actions.selectedCity,
              onZoneChanged: (zone) => actions.setCity(zone == 'TODAS' ? null : zone),
            );

            final historyFilterBar = CustomHeaderFilterBar(
              showSearchBar: true,
              searchQuery: _searchQuery,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              searchHint: 'Buscar por cliente, ID o zona...',
              showZoneFilter: false,
              anchorDate: DateTime.now(),
              customTrailingWidgets: [
                IconButton(
                  icon: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 22),
                  tooltip: 'Imprimir Cierre / Reporte',
                  onPressed: () {
                    PrinterActions.printDailySummary(
                      actions.selectedPeriod,
                      actions.totalSales,
                      actions.totalCash,
                      actions.totalTransfer,
                      [],
                    );
                  },
                ),
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _historyMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _historyMode == 0 ? AppTheme.primaryYellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryYellow, width: 1.5),
                        ),
                        child: Text(
                          "Tickets",
                          style: TextStyle(
                            color: _historyMode == 0 ? Colors.black : AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _historyMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _historyMode == 1 ? AppTheme.primaryYellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryYellow, width: 1.5),
                        ),
                        child: Text(
                          "Entradas Dinero",
                          style: TextStyle(
                            color: _historyMode == 1 ? Colors.black : AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

            return Scaffold(
              drawer: const AppDrawer(),
              appBar: AppBar(
                elevation: 0,
                title: Row(
                  children: [
                    const Text("Reportes"),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _showMetrics ? Icons.unfold_less : Icons.unfold_more, 
                        color: AppTheme.primaryYellow,
                        size: 26,
                      ),
                      tooltip: _showMetrics ? "Ocultar Totales" : "Mostrar Totales",
                      onPressed: () {
                        setState(() {
                          _showMetrics = !_showMetrics;
                        });
                        PreferencesService().setBool('reports_show_metrics', _showMetrics);
                      },
                    ),
                  ],
                ),
              ),
              body: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mainFilterBar,
                    const SizedBox(height: 12),
                    Expanded(
                      child: isMobile
                        ? Column(
                            children: [
                              if (_showMetrics) ...[
                                _buildTotalsGrid(actions, isPhone),
                                const SizedBox(height: 12),
                              ],
                              historyFilterBar,
                              const SizedBox(height: 8),
                              Expanded(child: _buildListView(sales, actions, isMobile)),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_showMetrics)
                                Expanded(
                                  flex: 4,
                                  child: _buildTotalsGrid(actions, isPhone),
                                ),
                              if (_showMetrics) const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    historyFilterBar,
                                    const SizedBox(height: 12),
                                    Expanded(child: _buildListView(sales, actions, isMobile)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
 
  Widget _buildFiltersRow(ReportsActions actions, List<String> periods, List<String> cities, bool isMobile, BuildContext context, {bool isPhone = false}) {
    if (isPhone) {
      return Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.primaryYellow,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  value: periods.contains(actions.selectedPeriod) ? actions.selectedPeriod : 'Día',
                  isExpanded: true,
                  selectedItemBuilder: (BuildContext context) {
                    return periods.map<Widget>((String item) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(item, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                      );
                    }).toList();
                  },
                  items: periods.map((p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(p, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) actions.setPeriod(val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.black, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppTheme.primaryYellow,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        value: (actions.selectedCity != null && cities.contains(actions.selectedCity)) ? actions.selectedCity : 'Todas las ciudades',
                        isExpanded: true,
                        selectedItemBuilder: (BuildContext context) {
                          return cities.map<Widget>((String item) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Text(item, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            );
                          }).toList();
                        },
                        items: cities.map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          actions.setCity(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Para PC y Tablet (Filtros en la misma línea)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppTheme.primaryYellow,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              value: periods.contains(actions.selectedPeriod) ? actions.selectedPeriod : 'Día',
              isExpanded: true,
              selectedItemBuilder: (BuildContext context) {
                return periods.map<Widget>((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(item, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  );
                }).toList();
              },
              items: periods.map((p) => DropdownMenuItem<String>(
                value: p,
                child: Text(p, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              )).toList(),
              onChanged: (val) {
                if (val != null) actions.setPeriod(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 180,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_city, color: Colors.black, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppTheme.primaryYellow,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    value: (actions.selectedCity != null && cities.contains(actions.selectedCity)) ? actions.selectedCity : 'Todas las ciudades',
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return cities.map<Widget>((String item) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: Text(item, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        );
                      }).toList();
                    },
                    items: cities.map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    )).toList(),
                    onChanged: (val) {
                      actions.setCity(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsGrid(ReportsActions actions, bool isPhone) {
    Map<String, int> productRanking = {};
    Map<String, double> clientRanking = {};

    for (var sale in actions.sales) {
      if (sale.city?.toLowerCase() == 'vendedores') continue;
      
      // Ranking de productos
      for (var item in sale.items) {
        String name = item.product.name;
        if (item.selectedVariant != null && item.selectedVariant!.name.isNotEmpty) {
          name += " ${item.selectedVariant!.name}";
        }
        productRanking[name] = (productRanking[name] ?? 0) + item.quantity;
      }

      // Ranking de clientes por total comprado
      String cName = sale.clientName?.isNotEmpty == true ? sale.clientName! : 'Público / Venta Directa';
      clientRanking[cName] = (clientRanking[cName] ?? 0.0) + sale.total;
    }
    
    var sortedProdRanking = productRanking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedProdRanking.length > 10) {
      sortedProdRanking = sortedProdRanking.sublist(0, 10);
    }

    var sortedClientRanking = clientRanking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedClientRanking.length > 10) {
      sortedClientRanking = sortedClientRanking.sublist(0, 10);
    }

    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final h = isPhone ? 280.0 : 340.0;

    return Container(
      height: h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // ── TOP 10 PRODUCTOS MÁS VENDIDOS ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.leaderboard, color: AppTheme.primaryYellow, size: 18),
                    SizedBox(width: 6),
                    Text("Top 10 Productos", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: sortedProdRanking.isEmpty
                    ? const Center(child: Text("Sin ventas", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)))
                    : ListView.builder(
                        itemCount: sortedProdRanking.length,
                        itemBuilder: (context, index) {
                          final item = sortedProdRanking[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${index + 1}. ${item.key}", 
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text("${item.value} u.", style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),

          const VerticalDivider(color: Colors.white12, width: 16),

          // ── TOP 10 MEJORES CLIENTES ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 6),
                    Text("Top 10 Clientes", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: sortedClientRanking.isEmpty
                    ? const Center(child: Text("Sin compras", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)))
                    : ListView.builder(
                        itemCount: sortedClientRanking.length,
                        itemBuilder: (context, index) {
                          final item = sortedClientRanking[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${index + 1}. ${item.key}", 
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(fmt.format(item.value), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color titleColor, Color valueColor, {bool isLarge = false, bool isHighlighted = false, bool isPhone = false}) {
    Color bgColor = isHighlighted ? AppTheme.primaryYellow : valueColor.withOpacity(0.15);
    Color tColor = isHighlighted ? Colors.black87 : titleColor;
    Color vColor = isHighlighted ? Colors.black : valueColor;

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlighted ? BorderSide.none : BorderSide(color: valueColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: (isLarge ? 4.0 : 6.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: isPhone ? 11 : (isLarge ? 16 : 14), color: tColor, fontWeight: FontWeight.bold, letterSpacing: 1.0), textAlign: TextAlign.center),
            SizedBox(height: isPhone ? 2 : 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(fontSize: isPhone ? 20 : (isLarge ? 36 : 28), fontWeight: FontWeight.w900, color: vColor), textAlign: TextAlign.center),
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget _buildListHeader(ReportsActions actions, bool isMobile, BuildContext context, {bool isPhone = false}) {
    String navText = "Historial";
    final ref = actions.currentReferenceDate;

    if (actions.selectedPeriod == 'Día') {
      navText = DateFormat('d MMM yyyy', 'es_ES').format(ref);
    } else if (actions.selectedPeriod == 'Semana') {
      int weekday = ref.weekday;
      DateTime startOfWeek = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      navText = "${DateFormat('d MMM', 'es_ES').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'es_ES').format(endOfWeek)}";
    } else if (actions.selectedPeriod == 'Mes') {
      navText = DateFormat('MMMM yyyy', 'es_ES').format(ref).toUpperCase();
    }

    final today = DateTime.now();
    final isToday = ref.year == today.year && ref.month == today.month && ref.day == today.day;

    Widget navRow = Row(
      mainAxisAlignment: isPhone ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: isPhone ? 2 : 16, vertical: isPhone ? 1 : 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.black, size: isPhone ? 16 : 28),
                padding: EdgeInsets.zero,
                constraints: isPhone ? const BoxConstraints(minWidth: 24, minHeight: 24) : const BoxConstraints(),
                onPressed: () => actions.previousPeriod(),
              ),
              SizedBox(width: isPhone ? 1 : 12),
              IconButton(
                icon: Icon(Icons.calendar_month, color: Colors.black, size: isPhone ? 12 : 24),
                padding: EdgeInsets.zero,
                constraints: isPhone ? const BoxConstraints(minWidth: 20, minHeight: 20) : const BoxConstraints(),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: ref,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDatePickerMode: actions.selectedPeriod == 'Mes' ? DatePickerMode.year : DatePickerMode.day,
                    locale: const Locale('es', 'ES'),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
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
                  if (date != null) {
                    actions.setReferenceDate(date);
                  }
                },
              ),
              SizedBox(width: isPhone ? 2 : 16),
              Text(
                navText,
                style: TextStyle(
                  fontSize: isPhone ? 10 : (isMobile ? 15 : 17),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: isPhone ? 2 : 16),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.black, size: isPhone ? 16 : 28),
                padding: EdgeInsets.zero,
                constraints: isPhone ? const BoxConstraints(minWidth: 24, minHeight: 24) : const BoxConstraints(),
                onPressed: () => actions.nextPeriod(),
              ),
            ],
          ),
        ),
        if (!isToday) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => actions.setReferenceDate(DateTime.now()),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 16, vertical: isPhone ? 4 : 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, color: Colors.black, size: isPhone ? 12 : 20),
                  const SizedBox(width: 2),
                  Text(
                    isPhone ? "Hoy" : (isMobile ? "Hoy" : "Volver a hoy"),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isPhone ? 10 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    Widget searchBar = SizedBox(
      width: isMobile ? double.infinity : 250,
      height: 36,
      child: TextField(
        style: const TextStyle(fontSize: 13),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar ticket o cliente...',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryYellow, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );

    Widget modeSelector = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("Tickets", style: TextStyle(fontSize: 13)),
            selected: _historyMode == 0,
            selectedColor: AppTheme.primaryYellow,
            labelStyle: TextStyle(color: _historyMode == 0 ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
            onSelected: (val) {
              if (val) setState(() => _historyMode = 0);
            },
          ),
          const SizedBox(width: 12),
          ChoiceChip(
            label: const Text("Entradas de Dinero", style: TextStyle(fontSize: 13)),
            selected: _historyMode == 1,
            selectedColor: AppTheme.primaryYellow,
            labelStyle: TextStyle(color: _historyMode == 1 ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
            onSelected: (val) {
              if (val) setState(() => _historyMode = 1);
            },
          ),
        ],
      ),
    );

    // Layout para tablet vertical y PC
    if (!isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Línea 1: Navegador de fechas a la izquierda, Selector de Modo a la derecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (actions.selectedPeriod != 'Historial')
                navRow
              else
                const Spacer(),
              modeSelector,
            ],
          ),
          const SizedBox(height: 12),
          // Línea 2: Título del Historial con Impresora a la izquierda, Buscador sobre la misma línea
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_historyMode == 0 ? "Historial de Tickets" : "Entradas de Dinero", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 24),
                    onPressed: () => _showVirtualTicketDialog(context, actions, navText),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: searchBar,
              ),
            ],
          ),
        ],
      );
    }

    // Para móviles y tablets verticales (isMobile == true)
    final isTabletVertical = !isPhone; // Si es mobile pero no teléfono, es tablet en vertical

    if (isTabletVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Línea 1: Navegador de fechas a la izquierda, Selector de Modo a la derecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (actions.selectedPeriod != 'Historial')
                navRow
              else
                const Spacer(),
              modeSelector,
            ],
          ),
          const SizedBox(height: 12),
          // Línea 2: Título e Impresora a la izquierda, Buscador al lado
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_historyMode == 0 ? "Historial de Tickets" : "Entradas de Dinero", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showVirtualTicketDialog(context, actions, navText),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: searchBar,
              ),
            ],
          ),
        ],
      );
    }

    // Para celulares (isPhone == true)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actions.selectedPeriod != 'Historial') navRow,
        if (actions.selectedPeriod != 'Historial') const SizedBox(height: 12),
        modeSelector,
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_historyMode == 0 ? "Historial de Tickets" : "Entradas de Dinero", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showVirtualTicketDialog(context, actions, navText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            searchBar,
          ],
        ),
      ],
    );
  }

  Widget _buildListView(List<Sale> sales, ReportsActions actions, bool isMobile, {bool isPhone = false}) {
    if (_historyMode == 1) {
      return _buildPaymentsListView(actions, isMobile, isPhone: isPhone);
    }

    if (sales.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text("No se encontró en los tickets cargados.", style: TextStyle(color: AppTheme.textSecondary)));
    }
    if (sales.isEmpty && !actions.isLoadingMore) {
      return const Center(child: Text("No hay ventas para este filtro.", style: TextStyle(color: AppTheme.textSecondary)));
    }
    
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: false,
      itemCount: sales.length + (actions.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sales.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow)),
          );
        }

        final sale = sales[index];
        final timeStr = DateFormat('dd/MM/yy HH:mm').format(sale.date);
        final titleText = sale.clientName?.isNotEmpty == true ? sale.clientName! : "Ticket";
        final isPending = (sale.total - sale.paidAmount) + (sale.previousBalance ?? 0.0) > 0;
        bool isExpanded = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppTheme.surfaceDark,
              child: ExpansionTile(
                onExpansionChanged: (val) {
                  setState(() {
                    isExpanded = val;
                  });
                },
                leading: const Icon(Icons.receipt_long, color: AppTheme.primaryYellow),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    isPhone ? titleText : "$titleText - $timeStr", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPhone)
                  Text(timeStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                Text(
                  "${sale.items.length} ítems" + (sale.exchanges.isNotEmpty ? " | ${sale.exchanges.length} cambios" : "") + (!isExpanded && isPending ? " | SALDO ACTUAL CLIENTE: \$${fmt.format(sale.clientId != null ? ClientsActionsV2().getCalculatedBalance(sale.clientId!) : ((sale.total - sale.paidAmount) + (sale.previousBalance ?? 0.0)))}" : ""),
                  style: TextStyle(color: !isExpanded && isPending ? AppTheme.danger : AppTheme.textSecondary, fontSize: 12, fontWeight: !isExpanded && isPending ? FontWeight.bold : FontWeight.normal),
                ),
                if (isPhone) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (isPending) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showCollectDialog(context, actions, sale),
                          icon: const Icon(Icons.monetization_on, color: Colors.black, size: 13),
                          label: const Text("Cobrar", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.primaryYellow, size: 18),
                        onPressed: () {
                          POSActions().loadSale(sale);
                          final shellState = AppShell.of(context);
                          if (shellState != null) {
                            shellState.switchTab(0);
                          }
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 18),
                        onPressed: () => _printTicketQuick(context, sale),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger, size: 18),
                        onPressed: () => _confirmDeleteSale(context, actions, sale),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isPending && !isPhone) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showCollectDialog(context, actions, sale),
                    icon: const Icon(Icons.monetization_on, color: Colors.black, size: 14),
                    label: const Text(
                      "COBRAR",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(fmt.format(sale.total), style: TextStyle(fontSize: isPhone ? 14 : (isMobile ? 16 : 18), fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                if (!isPhone) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryYellow),
                    onPressed: () {
                      POSActions().loadSale(sale);
                      final shellState = AppShell.of(context);
                      if (shellState != null) {
                        shellState.switchTab(0);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.primaryYellow),
                    onPressed: () => _printTicketQuick(context, sale),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.danger),
                    onPressed: () => _confirmDeleteSale(context, actions, sale),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...sale.items.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${e.quantity}x ${e.product.name}${e.selectedVariant != null ? ' (${e.selectedVariant!.name})' : ''} (${fmt.format(e.unitPrice)} c/u)",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (e.manualDiscount > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      fmt.format(e.unitPrice * e.quantity),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      fmt.format(e.total),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              else
                                Text(fmt.format(e.total)),
                            ],
                          ),
                          if (e.manualDiscount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_offer, color: Colors.greenAccent, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Desc. manual (${((e.manualDiscount / e.unitPrice) * 100).toStringAsFixed(0)}%)",
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "-${fmt.format(e.manualDiscount * e.quantity)}",
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )),
                    if (sale.exchanges.isNotEmpty) ...[
                      const Divider(color: AppTheme.primaryYellow),
                      const Text("Cambios:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      ...sale.exchanges.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("- ${e.quantity}x ${e.product.name}${e.selectedVariant != null ? ' (${e.selectedVariant!.name})' : ''}", style: const TextStyle(color: AppTheme.textSecondary)),
                      )),
                    ],
                    if (sale.discountAmount > 0) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("Descuento (${sale.appliedPromos.join(', ')})", style: const TextStyle(color: Colors.greenAccent))),
                          Text("-${fmt.format(sale.discountAmount)}", style: const TextStyle(color: Colors.greenAccent)),
                        ],
                      ),
                    ],
                    const Divider(color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal Pedido:", style: TextStyle(color: AppTheme.textSecondary)),
                        Text(fmt.format(sale.total), style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    if (sale.previousBalance != null && sale.previousBalance! > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Saldo Anterior:", style: TextStyle(color: AppTheme.textSecondary)),
                          Text(fmt.format(sale.previousBalance!), style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                    if (sale.paidAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pago (${sale.paymentMethod}):", style: const TextStyle(color: Colors.greenAccent)),
                          Text("-${fmt.format(sale.paidAmount)}", style: const TextStyle(color: Colors.greenAccent)),
                        ],
                      ),
                    ],
                    Builder(
                      builder: (context) {
                        double realPending = (sale.total - sale.paidAmount) + (sale.previousBalance ?? 0.0);
                        if (realPending > 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: AppTheme.danger),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TOTAL PENDIENTE:", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(fmt.format(realPending), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Divider(color: Colors.white24),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final List<String> lines = [];
                              lines.add("TICKET DE VENTA");
                              lines.add("Cliente: ${sale.clientName ?? 'Sin Cliente'}");
                              lines.add("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}");
                              lines.add("-----------------------------");
                              for (var e in sale.items) {
                                lines.add("${e.quantity}x ${e.product.name}${e.selectedVariant != null ? ' (${e.selectedVariant!.name})' : ''} (${fmt.format(e.unitPrice)} c/u) - ${fmt.format(e.total)}");
                              }
                              lines.add("-----------------------------");
                              lines.add("Subtotal Pedido: ${fmt.format(sale.total)}");
                              if (sale.previousBalance != null && sale.previousBalance! > 0) {
                                lines.add("Saldo Anterior: ${fmt.format(sale.previousBalance!)}");
                              }
                              if (sale.paidAmount > 0) {
                                lines.add("Pago (${sale.paymentMethod}): -${fmt.format(sale.paidAmount)}");
                              }
                              double realPending = (sale.total - sale.paidAmount) + (sale.previousBalance ?? 0.0);
                              if (realPending > 0) {
                                lines.add("TOTAL PENDIENTE: \$${fmt.format(realPending)}");
                              }
                              lines.add("-----------------------------");
                              lines.add("¡Gracias por su compra!");
                              
                              Clipboard.setData(ClipboardData(text: lines.join('\n')));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ticket copiado al portapapeles"), backgroundColor: Colors.green));
                            },
                            icon: const Icon(Icons.copy, color: AppTheme.primaryYellow, size: 18),
                            label: const Text(
                              "COPIAR TICKET",
                              style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showChangeMethodDialog(context, actions, sale),
                            icon: const Icon(Icons.swap_horiz, color: Colors.black, size: 18),
                            label: const Text(
                              "CAMBIAR MÉTODO",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildPaymentsListView(ReportsActions actions, bool isMobile, {bool isPhone = false}) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final List<Map<String, dynamic>> items = [];

    for (var sale in actions.sales) {
      if (sale.paidAmount > 0) {
        items.add({
          'type': 'sale_payment',
          'id': sale.id,
          'date': sale.date,
          'clientId': sale.clientId,
          'clientName': sale.clientName ?? 'Sin Cliente',
          'method': sale.paymentMethod,
          'amount': sale.paidAmount,
          'cashAmount': sale.cashAmount ?? (sale.paymentMethod == 'Efectivo' ? sale.paidAmount : 0.0),
          'transferAmount': sale.transferAmount ?? (sale.paymentMethod == 'Transferencia' ? sale.paidAmount : 0.0),
          'details': 'Venta POS - ${sale.items.length} ítems',
          'remainingBalance': sale.remainingBalance,
        });
      }
    }

    final allClients = ClientsActionsV2().allClients;
    final Map<String, String> clientNamesMap = {for (var c in allClients) c.id: c.name};

    final Map<String, Map<String, dynamic>> groupedInvoices = {};

    for (var doc in actions.payments) {
      final data = doc.data();
      if (data['isAdjustment'] == true || data['type'] == 'adjustment') continue;
      final amount = (data['amount'] ?? 0).toDouble();
      final type = data['type'] as String?;
      if (amount > 0 && type != 'sale_payment') {
        final isGroup = data['isGroup'] == true;
        final invoiceId = data['invoiceId'] as String?;
        final clientId = data['clientId'] ?? '';
        final clientName = isGroup ? (data['groupName'] ?? 'Grupo') : (clientNamesMap[clientId] ?? data['clientName'] ?? 'Sin Cliente');
        final detailsStr = isGroup ? 'Cobro Factura "${data['groupName'] ?? 'Grupo'}"' : 'Cobro Cuenta Corriente';

        final Timestamp? ts = data['date'] as Timestamp?;
        final date = ts?.toDate() ?? DateTime.now();

        if (isGroup && invoiceId != null) {
          if (groupedInvoices.containsKey(invoiceId)) {
            groupedInvoices[invoiceId]!['amount'] += amount;
            groupedInvoices[invoiceId]!['cashAmount'] += (data['cashAmount'] ?? (data['method'] == 'Efectivo' ? amount : 0)).toDouble();
            groupedInvoices[invoiceId]!['transferAmount'] += (data['transferAmount'] ?? (data['method'] == 'Transferencia' ? amount : 0)).toDouble();
            if (groupedInvoices[invoiceId]!['method'] != data['method']) {
               groupedInvoices[invoiceId]!['method'] = 'Mixto';
            }
          } else {
             groupedInvoices[invoiceId] = {
              'type': 'account_payment',
              'id': doc.id,
              'date': date,
              'clientName': clientName,
              'method': data['method'] ?? 'Efectivo',
              'amount': amount,
              'cashAmount': (data['cashAmount'] ?? (data['method'] == 'Efectivo' ? amount : 0)).toDouble(),
              'transferAmount': (data['transferAmount'] ?? (data['method'] == 'Transferencia' ? amount : 0)).toDouble(),
              'details': detailsStr,
              'remainingBalance': data['remainingBalance'] != null ? data['remainingBalance'].toDouble() : null,
              'invoiceId': invoiceId,
              'groupId': data['groupId'],
            };
          }
          continue;
        }

        // Evitar duplicados en el listado visual:
        // Si ya agregamos una venta del mismo cliente con el mismo monto de pago cobrado,
        // no agregamos este pago de CC para evitar duplicar el ítem en la pantalla.
        bool isDuplicate = false;
        if (!isGroup) {
          for (var sale in actions.sales) {
            if (sale.clientId == clientId && (sale.paidAmount - amount).abs() < 5.0) {
              isDuplicate = true;
              break;
            }
          }
        }
        if (!isDuplicate) {
          items.add({
            'type': data['type'] ?? 'account_payment',
            'id': doc.id,
            'date': date,
            'clientName': clientName,
            'method': data['method'] ?? 'Efectivo',
            'amount': amount,
            'cashAmount': (data['cashAmount'] ?? (data['method'] == 'Efectivo' ? amount : 0)).toDouble(),
            'transferAmount': (data['transferAmount'] ?? (data['method'] == 'Transferencia' ? amount : 0)).toDouble(),
            'details': detailsStr,
            'remainingBalance': data['remainingBalance'] != null ? data['remainingBalance'].toDouble() : null,
            'invoiceId': invoiceId,
            'groupId': data['groupId'],
          });
        }
      }
    }

    items.addAll(groupedInvoices.values);

    items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final filteredItems = items.where((item) =>
      (item['clientName'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filteredItems.isEmpty) {
      return const Center(child: Text("No hay entradas de dinero para este filtro.", style: TextStyle(color: AppTheme.textSecondary)));
    }

    double totalCash = 0;
    double totalTransfer = 0;

    for (var item in filteredItems) {
      final amt = item['amount'] as double;
      final method = item['method'] as String;
      if (method == 'Efectivo') {
        totalCash += amt;
      } else if (method == 'Transferencia') {
        totalTransfer += amt;
      } else if (method == 'Mixto') {
        totalCash += item['cashAmount'] as double;
        totalTransfer += item['transferAmount'] as double;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text("Efectivo Filtro", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(fmt.format(totalCash), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.white12),
              Column(
                children: [
                  const Text("Transf. Filtro", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(fmt.format(totalTransfer), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.white12),
              Column(
                children: [
                  const Text("Total Filtro", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(fmt.format(totalCash + totalTransfer), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final DateTime dt = item['date'];
              final timeStr = DateFormat('dd/MM/yy HH:mm').format(dt);
              final bool isSale = item['type'] == 'sale_payment';
              final String method = item['method'] as String;
              final Color methodColor = method == 'Transferencia' ? Colors.lightBlueAccent : (method == 'Efectivo' ? Colors.greenAccent : AppTheme.primaryYellow);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.surfaceDark,
                child: ListTile(
                  leading: Icon(
                    isSale ? Icons.shopping_bag : Icons.account_balance_wallet,
                    color: methodColor,
                  ),
                  title: Text("${item['clientName']} - $timeStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${item['details']} [${item['method']}]",
                    style: TextStyle(color: methodColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(item['amount']),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                          if (item['remainingBalance'] != null && item['remainingBalance'] > 0)
                            Text(
                              "Pend: ${fmt.format(item['remainingBalance'])}",
                              style: const TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold),
                            ),
                          if (item['method'] == 'Mixto')
                            Text(
                              "E: ${fmt.format(item['cashAmount'])} / T: ${fmt.format(item['transferAmount'])}",
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                          if (!isSale)
                            IconButton(
                              icon: const Icon(Icons.edit_calendar, color: AppTheme.primaryYellow, size: 20),
                              onPressed: () async {
                                final initialDate = item['date'] as DateTime;
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2101),
                                  builder: (context, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppTheme.primaryYellow,
                                        onPrimary: Colors.black,
                                        surface: AppTheme.surfaceDark,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  final newDate = DateTime(picked.year, picked.month, picked.day, initialDate.hour, initialDate.minute);
                                  if (item['invoiceId'] != null && item['groupId'] != null) {
                                    await ClientGroupsActions().updateInvoicePaidDate(item['groupId'], item['invoiceId'], newDate);
                                  } else {
                                    await actions.updatePaymentDate(item['id'], newDate);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fecha actualizada")));
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: isSale ? () {
                        // ... mostrar detalles (opcional)
                      } : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  void _showVirtualTicketDialog(BuildContext context, ReportsActions actions, String navText) async {
    final Map<String, Map<String, double>> clientSummary = {};
    
    for (var sale in actions.sales) {
      final paid = sale.paidAmount;
      if (paid > 0) {
        final name = sale.clientName ?? 'Sin Cliente';
        if (!clientSummary.containsKey(name)) {
          clientSummary[name] = {'cash': 0.0, 'transfer': 0.0};
        }
        if (sale.paymentMethod == 'Efectivo') {
          clientSummary[name]!['cash'] = (clientSummary[name]!['cash'] ?? 0) + paid;
        } else if (sale.paymentMethod == 'Transferencia') {
          clientSummary[name]!['transfer'] = (clientSummary[name]!['transfer'] ?? 0) + paid;
        } else if (sale.paymentMethod == 'Mixto') {
          clientSummary[name]!['cash'] = (clientSummary[name]!['cash'] ?? 0) + (sale.cashAmount ?? 0.0);
          clientSummary[name]!['transfer'] = (clientSummary[name]!['transfer'] ?? 0) + (sale.transferAmount ?? 0.0);
        }
      }
    }

    try {
      final payQuery = actions.buildPaymentsQuery();
      final paymentsSnap = await payQuery.get();
      final allClients = ClientsActionsV2().allClients;
      final Map<String, String> clientNamesMap = {for (var c in allClients) c.id: c.name};

      for (var doc in paymentsSnap.docs) {
        final data = doc.data();
        if (data['isAdjustment'] == true || data['type'] == 'adjustment') continue;
        final amount = (data['amount'] ?? 0).toDouble();
        if (amount > 0) {
          final clientId = data['clientId'] ?? '';
          final name = clientNamesMap[clientId] ?? 'Sin Cliente';

          // Evitar duplicar en el Resumen del Ticket de Caja Virtual:
          // Si el cobro de esta venta ya se sumó arriba a través de la venta, lo salteamos acá.
          bool isDuplicate = false;
          for (var sale in actions.sales) {
            if (sale.clientId == clientId && (sale.paidAmount - amount).abs() < 5.0) {
              isDuplicate = true;
              break;
            }
          }

          if (!isDuplicate) {
            if (!clientSummary.containsKey(name)) {
              clientSummary[name] = {'cash': 0.0, 'transfer': 0.0};
            }
            final method = data['method'] ?? 'Efectivo';
            if (method == 'Efectivo') {
              clientSummary[name]!['cash'] = (clientSummary[name]!['cash'] ?? 0) + amount;
            } else if (method == 'Transferencia') {
              clientSummary[name]!['transfer'] = (clientSummary[name]!['transfer'] ?? 0) + amount;
            } else if (method == 'Mixto') {
              clientSummary[name]!['cash'] = (clientSummary[name]!['cash'] ?? 0) + (data['cashAmount'] ?? 0.0);
              clientSummary[name]!['transfer'] = (clientSummary[name]!['transfer'] ?? 0) + (data['transferAmount'] ?? 0.0);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching payments: $e");
    }

    final List<Map<String, dynamic>> details = [];
    clientSummary.forEach((name, map) {
      details.add({
        'clientName': name,
        'cash': map['cash'] ?? 0.0,
        'transfer': map['transfer'] ?? 0.0,
      });
    });

    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ticket de Caja Virtual", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "RESUMEN DE CAJA\n$navText",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  ...details.map((d) {
                    final cash = d['cash'] as double;
                    final transfer = d['transfer'] as double;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['clientName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (cash > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("  - Efectivo (E)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                Text(fmt.format(cash), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          if (transfer > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("  - Transferencia (T)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                Text(fmt.format(transfer), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("EFECTIVO EN CAJA", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text(fmt.format(actions.totalCash), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TRANSFERENCIA EN CAJA", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                      Text(fmt.format(actions.totalTransfer), style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL CAJA", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(fmt.format(actions.totalCash + actions.totalTransfer), style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy, color: AppTheme.primaryYellow),
              label: const Text("COPIAR RESUMEN", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
              onPressed: () {
                final List<String> copyLines = [];
                for (var kv in clientSummary.entries) {
                  final client = kv.key;
                  final cash = kv.value['cash'] ?? 0;
                  final transfer = kv.value['transfer'] ?? 0;
                  if (cash > 0) copyLines.add("$client \$${cash.toStringAsFixed(0)} (E)");
                  if (transfer > 0) copyLines.add("$client \$${transfer.toStringAsFixed(0)} (T)");
                }
                final copyText = copyLines.join('\n');
                Clipboard.setData(ClipboardData(text: copyText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Resumen copiado al portapapeles para WhatsApp."), backgroundColor: Colors.green),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print, color: Colors.black),
              label: const Text("IMPRIMIR TICKET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await PrinterActions.printDailySummary(
                  navText,
                  actions.totalCash + actions.totalTransfer,
                  actions.totalCash,
                  actions.totalTransfer,
                  details,
                );
                if (context.mounted) {
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Resumen de ingresos enviado a la impresora."), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Impresora desconectada o error de impresión."), backgroundColor: AppTheme.danger),
                    );
                  }
                }
              },
            )
          ],
        );
      },
    );
  }
  
  void _showChangeMethodDialog(BuildContext context, ReportsActions actions, Sale sale) {
    if (sale.paymentMethod == 'Mixto') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No se puede cambiar el método de un pago Mixto directamente."),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        bool isProcessing = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Cambiar Método de Pago"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sale.paymentMethod == 'Pendiente')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        border: Border.all(color: AppTheme.danger),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "⚠️ IMPORTANTE:\nSi ya registraste este pago manualmente desde 'Cuenta Corriente', NO uses esta opción o descontarás la deuda dos veces. En ese caso, debes eliminar el pago manual primero.",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    )
                  else
                    const Text("Seleccioná el nuevo método. Esto actualizará el saldo del cliente automáticamente."),
                  
                  const SizedBox(height: 16),
                  if (isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.money, color: Colors.green),
                      title: const Text("Efectivo"),
                      onTap: () async {
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceDark,
                            title: const Text("Atención", style: TextStyle(color: AppTheme.primaryYellow)),
                            content: const Text("Si cambias esto a Pagado, se descontará automáticamente del saldo deudor total del cliente.\n\nIMPORTANTE: Si ya le cargaste el pago suelto desde su perfil, NO lo marques pagado acá o se le descontará dos veces. ¿Continuar?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar", style: TextStyle(color: Colors.white70))),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow), child: const Text("Sí, Descontar", style: TextStyle(color: Colors.black))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          setDialogState(() => isProcessing = true);
                          await actions.changePaymentMethod(sale, 'Efectivo');
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_balance, color: Colors.blue),
                      title: const Text("Transferencia"),
                      onTap: () async {
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceDark,
                            title: const Text("Atención", style: TextStyle(color: AppTheme.primaryYellow)),
                            content: const Text("Si cambias esto a Transferencia, se descontará automáticamente del saldo deudor total del cliente.\n\nIMPORTANTE: Si ya le cargaste el pago suelto desde su perfil, NO lo marques pagado acá o se le descontará dos veces. ¿Continuar?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar", style: TextStyle(color: Colors.white70))),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow), child: const Text("Sí, Descontar", style: TextStyle(color: Colors.black))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          setDialogState(() => isProcessing = true);
                          await actions.changePaymentMethod(sale, 'Transferencia');
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer, color: Colors.orange),
                      title: const Text("Fiado (Pendiente)"),
                      onTap: () async {
                        setDialogState(() => isProcessing = true);
                        await actions.changePaymentMethod(sale, 'Pendiente');
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _printTicketQuick(BuildContext context, Sale sale) async {
    Client? client;
    if (sale.clientId != null) {
      final doc = await TenantDB.collection('clients').doc(sale.clientId).get();
      if (doc.exists) {
        client = Client.fromMap(doc.data()!, doc.id);
      }
    }
    bool showDetails = sale.paidAmount > 0 || (sale.previousBalance ?? 0) != 0;
    
    await PrinterActions.printTicket(
      sale.items,
      sale.total + sale.discountAmount,
      sale.discountAmount,
      sale.appliedPromos,
      sale.total,
      sale.exchanges,
      sale.paidAmount,
      sale.paymentMethod,
      client,
      sale.previousBalance ?? 0.0,
      true, 
      showDetails,
      cleanTicket: false,
    );
  }

  void _showCollectDialog(BuildContext context, ReportsActions actions, Sale sale) {
    final double totalPending = (sale.total - sale.paidAmount) + (sale.previousBalance ?? 0.0);
    final amountCtrl = TextEditingController(text: totalPending.toStringAsFixed(0));
    final cashCtrl = TextEditingController(text: totalPending.toStringAsFixed(0));
    final transferCtrl = TextEditingController(text: '0');
    String method = 'Efectivo';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateMixtoTotal() {
              double cash = double.tryParse(cashCtrl.text) ?? 0;
              double trans = double.tryParse(transferCtrl.text) ?? 0;
              amountCtrl.text = (cash + trans).toStringAsFixed(0);
            }

            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Text("Cobrar Ticket - ${sale.clientName ?? 'Sin Cliente'}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Monto Pendiente: \$${totalPending.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.danger),
                    ),
                    const SizedBox(height: 16),
                    if (method != 'Mixto')
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: "Monto a Cobrar",
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    if (method == 'Mixto') ...[
                      TextField(
                        controller: cashCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: "Monto Efectivo",
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) { updateMixtoTotal(); },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: transferCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: "Monto Transferencia",
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) { updateMixtoTotal(); },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Efectivo', style: TextStyle(fontSize: 11)),
                            value: 'Efectivo',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              amountCtrl.text = totalPending.toStringAsFixed(0);
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Transf.', style: TextStyle(fontSize: 11)),
                            value: 'Transferencia',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              amountCtrl.text = totalPending.toStringAsFixed(0);
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Mixto', style: TextStyle(fontSize: 11)),
                            value: 'Mixto',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              cashCtrl.text = totalPending.toStringAsFixed(0);
                              transferCtrl.text = '0';
                              updateMixtoTotal();
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                      ]
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCELAR", style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setDialogState(() { isSaving = true; });
                    
                    double amt = double.tryParse(amountCtrl.text) ?? 0;
                    double cashAmt = 0;
                    double transferAmt = 0;

                    if (method == 'Efectivo') {
                      cashAmt = amt;
                    } else if (method == 'Transferencia') {
                      transferAmt = amt;
                    } else if (method == 'Mixto') {
                      cashAmt = double.tryParse(cashCtrl.text) ?? 0;
                      transferAmt = double.tryParse(transferCtrl.text) ?? 0;
                      amt = cashAmt + transferAmt;
                    }

                    if (amt > 0) {
                      try {
                        actions.collectSale(sale, amt, method, cashAmount: cashAmt, transferAmount: transferAmt);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cobro registrado exitosamente."), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() { isSaving = false; });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error al registrar cobro: $e"), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    } else {
                      setDialogState(() { isSaving = false; });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
                  child: const Text("COBRAR TICKET"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSale(BuildContext context, ReportsActions actions, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Venta"),
        content: const Text("¿Estás seguro de que deseas eliminar este ticket de forma permanente? Esto no se puede deshacer y los reportes se recalcularán."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              actions.deleteSale(sale.id, clientId: sale.clientId, total: sale.total, paidAmount: sale.paidAmount);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}

