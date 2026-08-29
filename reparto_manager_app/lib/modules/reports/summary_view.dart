import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/tenant_db.dart';
import '../clients/v2/clients_actions_v2.dart';
import '../shell/app_drawer.dart';
import '../printer/printer_actions.dart';

// Modos de período disponibles
enum PeriodMode { day, week, month, year, all }

class SummaryView extends StatefulWidget {
  const SummaryView({super.key});

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  PeriodMode _mode = PeriodMode.day;
  DateTime _anchor = DateTime.now(); // día/semana/mes/año de referencia
  String? _selectedCity;
  bool _isLoading = false;

  double _salesTotal = 0.0;
  double _salesCash = 0.0;
  double _salesTransfer = 0.0;
  double _salesPending = 0.0;

  double _paymentsCash = 0.0;
  double _paymentsTransfer = 0.0;
  double _paymentsTotal = 0.0;

  double _totalCash = 0.0;
  double _totalTransfer = 0.0;
  double _totalRealCaja = 0.0;

  // Lista para almacenar desglose detallado de ingresos (pago de clientes o ventas)
  List<Map<String, dynamic>> _printDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  // ─── Rango de fechas según el modo ──────────────────────────────────────────
  (DateTime start, DateTime end) _getRange() {
    switch (_mode) {
      case PeriodMode.day:
        final s = DateTime(_anchor.year, _anchor.month, _anchor.day);
        return (s, s.add(const Duration(days: 1)));
      case PeriodMode.week:
        // Lunes de la semana del anchor
        final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final s = DateTime(monday.year, monday.month, monday.day);
        return (s, s.add(const Duration(days: 7)));
      case PeriodMode.month:
        final s = DateTime(_anchor.year, _anchor.month, 1);
        final e = DateTime(_anchor.year, _anchor.month + 1, 1);
        return (s, e);
      case PeriodMode.year:
        final s = DateTime(_anchor.year, 1, 1);
        final e = DateTime(_anchor.year + 1, 1, 1);
        return (s, e);
      case PeriodMode.all:
        return (DateTime(2000), DateTime(2100));
    }
  }

  void _navigate(int delta) {
    setState(() {
      switch (_mode) {
        case PeriodMode.day:
          _anchor = _anchor.add(Duration(days: delta));
          break;
        case PeriodMode.week:
          _anchor = _anchor.add(Duration(days: delta * 7));
          break;
        case PeriodMode.month:
          _anchor = DateTime(_anchor.year, _anchor.month + delta, 1);
          break;
        case PeriodMode.year:
          _anchor = DateTime(_anchor.year + delta, 1, 1);
          break;
        case PeriodMode.all:
          break;
      }
    });
    _fetchSummaryData();
  }

  String _periodLabel() {
    final fmt = NumberFormat.decimalPattern('es_ES');
    switch (_mode) {
      case PeriodMode.day:
        final today = DateTime.now();
        final isToday = _anchor.year == today.year &&
            _anchor.month == today.month &&
            _anchor.day == today.day;
        if (isToday) return 'Hoy — ${DateFormat('d MMM yyyy', 'es_ES').format(_anchor)}';
        return DateFormat('EEEE d MMM yyyy', 'es_ES').format(_anchor);
      case PeriodMode.week:
        final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'es_ES').format(monday)} – ${DateFormat('d MMM yyyy', 'es_ES').format(sunday)}';
      case PeriodMode.month:
        return DateFormat('MMMM yyyy', 'es_ES').format(_anchor);
      case PeriodMode.year:
        return _anchor.year.toString();
      case PeriodMode.all:
        return 'Historial completo';
    }
  }

  Future<void> _fetchSummaryData() async {
    // Reset inmediato — evita que datos viejos queden si cambia el filtro
    setState(() {
      _isLoading = true;
      _salesTotal = 0; _salesCash = 0; _salesTransfer = 0; _salesPending = 0;
      _paymentsCash = 0; _paymentsTransfer = 0; _paymentsTotal = 0;
      _totalCash = 0; _totalTransfer = 0; _totalRealCaja = 0;
      _printDetails.clear();
    });

    try {
      final (start, end) = _getRange();
      final isAll = _mode == PeriodMode.all;

      // Mapa para consolidar ingresos por cliente
      final Map<String, Map<String, double>> clientSummary = {};

      // 1. Ventas — solo filtro de fecha en Firestore (evita necesidad de índice compuesto)
      Query salesQuery = TenantDB.collection('sales');
      if (!isAll) {
        salesQuery = salesQuery
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
      }
      final salesSnap = await salesQuery.get();

      double sTotal = 0, sCash = 0, sTrans = 0, sPend = 0;
      for (var doc in salesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Filtro de ciudad en Dart (sin composite index)
        if (_selectedCity != null && data['city'] != _selectedCity) continue;
        final total = (data['total'] ?? 0).toDouble();
        final paid = (data['paidAmount'] ?? 0).toDouble();
        final method = data['paymentMethod'] ?? 'Efectivo';
        final cashAmt = (data['cashAmount'] ?? 0).toDouble();
        final transferAmt = (data['transferAmount'] ?? 0).toDouble();
        sTotal += total;
        if (method == 'Efectivo') sCash += paid;
        else if (method == 'Transferencia') sTrans += paid;
        else if (method == 'Mixto') { sCash += cashAmt; sTrans += transferAmt; }
        if (method == 'Pendiente') sPend += total;
        else if (paid < total) sPend += (total - paid);

        // Agrupar para ticket de resumen
        if (paid > 0) {
          final clientName = data['clientName'] ?? 'Sin Cliente';
          if (!clientSummary.containsKey(clientName)) {
            clientSummary[clientName] = {'cash': 0.0, 'transfer': 0.0};
          }
          if (method == 'Efectivo') {
            clientSummary[clientName]!['cash'] = (clientSummary[clientName]!['cash'] ?? 0) + paid;
          } else if (method == 'Transferencia') {
            clientSummary[clientName]!['transfer'] = (clientSummary[clientName]!['transfer'] ?? 0) + paid;
          } else if (method == 'Mixto') {
            clientSummary[clientName]!['cash'] = (clientSummary[clientName]!['cash'] ?? 0) + cashAmt;
            clientSummary[clientName]!['transfer'] = (clientSummary[clientName]!['transfer'] ?? 0) + transferAmt;
          }
        }
      }

      // 2. Cobros cuenta corriente — ídem, filtro ciudad en Dart
      Query paymentsQuery = TenantDB.collection('payments');
      if (!isAll) {
        paymentsQuery = paymentsQuery
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
      }
      final paymentsSnap = await paymentsQuery.get();

      // Cargar nombres de clientes de la base local para mapear clientId -> name en cobros
      final allClients = ClientsActionsV2().allClients;
      final Map<String, String> clientNamesMap = {for (var c in allClients) c.id: c.name};

      // Guardamos la lista de ventas mapeada para hacer la deduplicación
      final List<Map<String, dynamic>> salesList = salesSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      double pCash = 0, pTrans = 0, pTotal = 0;
      for (var doc in paymentsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isAdjustment'] == true || data['type'] == 'adjustment') continue;

        // El campo puede ser 'clientCity' o 'city' según cómo se guardó
        final docCity = data['clientCity'] ?? data['city'] ?? '';
        if (_selectedCity != null && docCity != _selectedCity) continue;
        final amount = (data['amount'] ?? 0).toDouble();
        final method = data['method'] ?? 'Efectivo';
        final cashAmt = (data['cashAmount'] ?? 0).toDouble();
        final transferAmt = (data['transferAmount'] ?? 0).toDouble();
        final clientId = data['clientId'] ?? '';

        // DEDUPLICACIÓN: Evitar duplicado de cobros automáticos en el Resumen
        bool isDuplicate = false;
        if (clientId.isNotEmpty && amount > 0) {
          for (var saleData in salesList) {
            final saleClientId = saleData['clientId'];
            final salePaidAmount = (saleData['paidAmount'] ?? 0).toDouble();
            if (saleClientId == clientId && (salePaidAmount - amount).abs() < 5.0) {
              isDuplicate = true;
              break;
            }
          }
        }

        if (!isDuplicate) {
          pTotal += amount;
          if (method == 'Efectivo') pCash += amount;
          else if (method == 'Transferencia') pTrans += amount;
          else if (method == 'Mixto') { pCash += cashAmt; pTrans += transferAmt; }

          if (amount > 0) {
            final clientName = clientNamesMap[clientId] ?? 'Sin Cliente';
            if (!clientSummary.containsKey(clientName)) {
              clientSummary[clientName] = {'cash': 0.0, 'transfer': 0.0};
            }
            if (method == 'Efectivo') {
              clientSummary[clientName]!['cash'] = (clientSummary[clientName]!['cash'] ?? 0) + amount;
            } else if (method == 'Transferencia') {
              clientSummary[clientName]!['transfer'] = (clientSummary[clientName]!['transfer'] ?? 0) + amount;
            } else if (method == 'Mixto') {
              clientSummary[clientName]!['cash'] = (clientSummary[clientName]!['cash'] ?? 0) + cashAmt;
              clientSummary[clientName]!['transfer'] = (clientSummary[clientName]!['transfer'] ?? 0) + transferAmt;
            }
          }
        }
      }

      final List<Map<String, dynamic>> consolidatedDetails = [];
      clientSummary.forEach((name, map) {
        consolidatedDetails.add({
          'clientName': name,
          'cash': map['cash'] ?? 0.0,
          'transfer': map['transfer'] ?? 0.0,
        });
      });

      setState(() {
        _salesTotal = sTotal; _salesCash = sCash;
        _salesTransfer = sTrans; _salesPending = sPend;
        _paymentsCash = pCash; _paymentsTransfer = pTrans; _paymentsTotal = pTotal;
        _totalCash = sCash + pCash;
        _totalTransfer = sTrans + pTrans;
        _totalRealCaja = _totalCash + _totalTransfer;
        _printDetails = consolidatedDetails;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      setState(() {
        _isLoading = false;
        _salesTotal = 0; _salesCash = 0; _salesTransfer = 0; _salesPending = 0;
        _paymentsCash = 0; _paymentsTransfer = 0; _paymentsTotal = 0;
        _totalCash = 0; _totalTransfer = 0; _totalRealCaja = 0;
        _printDetails.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos: $e"), backgroundColor: Colors.red[800]),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final cities = ['Todas las ciudades', ...ClientsActionsV2().cities];
    final canNavigate = _mode != PeriodMode.all;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Resumen de Caja"),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth <= 500;

          return Column(
            children: [
              // ── BARRA INTEGRADA UNIFICADA DE FILTROS (Día/Semana/Mes/Año + Fecha + Zonas) ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Selector desplegable compacto de Período
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PeriodMode>(
                            dropdownColor: AppTheme.primaryYellow,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                            value: _mode,
                            items: const [
                              DropdownMenuItem(value: PeriodMode.day, child: Text("Día")),
                              DropdownMenuItem(value: PeriodMode.week, child: Text("Semana")),
                              DropdownMenuItem(value: PeriodMode.month, child: Text("Mes")),
                              DropdownMenuItem(value: PeriodMode.year, child: Text("Año")),
                              DropdownMenuItem(value: PeriodMode.all, child: Text("Todo")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _mode = val);
                                _fetchSummaryData();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Selector de Fecha Integrado con Flechas compactas
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (canNavigate)
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.black, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => _navigate(-1),
                                ),
                              Expanded(
                                child: InkWell(
                                  onTap: _mode == PeriodMode.day ? () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _anchor,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 1)),
                                      locale: const Locale('es', 'ES'),
                                    );
                                    if (picked != null) {
                                      setState(() => _anchor = picked);
                                      _fetchSummaryData();
                                    }
                                  } : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Colors.black, size: 16),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _periodLabel(),
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (canNavigate)
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => _navigate(1),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Selector de ZONAS (con TODAS las zonas por defecto)
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_city, color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: AppTheme.primaryYellow,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                value: _selectedCity ?? 'TODAS',
                                items: cities.map((c) => DropdownMenuItem<String>(
                                  value: c == 'Todas las ciudades' ? 'TODAS' : c,
                                  child: Text(c == 'Todas las ciudades' ? 'TODAS' : c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCity = (val == 'TODAS' || val == 'Todas las ciudades') ? null : val;
                                  });
                                  _fetchSummaryData();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
 
              // ── Contenido ────────────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          children: [
                            // Tarjeta principal
                            Card(
                              color: AppTheme.primaryYellow.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.primaryYellow, width: 1.5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isPhone ? 12.0 : 24.0),
                                child: Column(
                                  children: [
                                    Text(
                                      "EFECTIVO + TRANSFERENCIAS TOTALES",
                                      style: TextStyle(fontSize: isPhone ? 11 : 15, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow, letterSpacing: 1.1),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      fmt.format(_totalRealCaja),
                                      style: TextStyle(fontSize: isPhone ? 32 : 48, fontWeight: FontWeight.w900, color: AppTheme.primaryYellow),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(children: [
                                          const Text("EFECTIVO", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(fmt.format(_totalCash), style: TextStyle(fontSize: isPhone ? 16 : 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                        ]),
                                        Container(width: 1.5, height: 36, color: Colors.white24),
                                        Column(children: [
                                          const Text("TRANSFERENCIAS", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(fmt.format(_totalTransfer), style: TextStyle(fontSize: isPhone ? 16 : 22, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                                        ]),
                                        Container(width: 1.5, height: 36, color: Colors.white24),
                                        Column(children: [
                                          const Text("VENTAS BRUTAS", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(fmt.format(_salesTotal), style: TextStyle(fontSize: isPhone ? 16 : 22, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Fila/Columna de desglose
                            isPhone
                                ? Column(
                                    children: [
                                      Card(
                                        color: AppTheme.surfaceDark,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Ventas Brutas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  Text(fmt.format(_salesTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                                                ],
                                              ),
                                              const Divider(color: Colors.white24, height: 24),
                                              _buildRow("Cobrado en Efectivo", fmt.format(_salesCash), Colors.greenAccent),
                                              const SizedBox(height: 12),
                                              _buildRow("Cobrado por Transferencia", fmt.format(_salesTransfer), Colors.lightBlueAccent),
                                              const SizedBox(height: 12),
                                              _buildRow("Fiado / Cuenta Corriente", fmt.format(_salesPending), AppTheme.danger),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Card(
                                        color: AppTheme.surfaceDark,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Cobros Cta. Cte.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  Text(fmt.format(_paymentsTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                                ],
                                              ),
                                              const Divider(color: Colors.white24, height: 24),
                                              _buildRow("Efectivo Recibido", fmt.format(_paymentsCash), Colors.greenAccent),
                                              const SizedBox(height: 12),
                                              _buildRow("Transferencias Recibidas", fmt.format(_paymentsTransfer), Colors.lightBlueAccent),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Card(
                                          color: AppTheme.surfaceDark,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text("Ventas Brutas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                    Text(fmt.format(_salesTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                                                  ],
                                                ),
                                                const Divider(color: Colors.white24, height: 24),
                                                _buildRow("Cobrado en Efectivo", fmt.format(_salesCash), Colors.greenAccent),
                                                const SizedBox(height: 12),
                                                _buildRow("Cobrado por Transferencia", fmt.format(_salesTransfer), Colors.lightBlueAccent),
                                                const SizedBox(height: 12),
                                                _buildRow("Fiado / Cuenta Corriente", fmt.format(_salesPending), AppTheme.danger),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Card(
                                          color: AppTheme.surfaceDark,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text("Cobros Cta. Cte.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                    Text(fmt.format(_paymentsTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                                  ],
                                                ),
                                                const Divider(color: Colors.white24, height: 24),
                                                _buildRow("Efectivo Recibido", fmt.format(_paymentsCash), Colors.greenAccent),
                                                const SizedBox(height: 12),
                                                _buildRow("Transferencias Recibidas", fmt.format(_paymentsTransfer), Colors.lightBlueAccent),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _modeChip(PeriodMode mode, String label, IconData icon) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _mode = mode);
          _fetchSummaryData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryYellow : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppTheme.primaryYellow : Colors.white12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.black : AppTheme.textSecondary, size: 18),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.black : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
