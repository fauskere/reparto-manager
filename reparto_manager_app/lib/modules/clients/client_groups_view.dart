import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/tenant_db.dart';
import '../shell/app_drawer.dart';
import 'client.dart';
import 'clients_actions.dart';
import 'client_group.dart';
import 'client_groups_actions.dart';
import 'client_details_view.dart';

class ClientGroupsView extends StatefulWidget {
  const ClientGroupsView({super.key});

  @override
  State<ClientGroupsView> createState() => _ClientGroupsViewState();
}

class _ClientGroupsViewState extends State<ClientGroupsView> {
  final fmt = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text("Grupos / FacturaciÃ³n"), elevation: 0),
      body: ListenableBuilder(
        listenable: ClientGroupsActions(),
        builder: (context, child) {
          final groups = ClientGroupsActions().groups;
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No hay grupos de clientes creados.\nPodÃ©s agrupar clientes desde la pestaÃ±a Clientes Especiales.",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListenableBuilder(
            listenable: ClientsActions(),
            builder: (context, child) {
              final allClients = ClientsActions().allClients;

              return Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final members = allClients
                        .where((c) => c.groupId == group.id)
                        .toList();

                    return Card(
                      color: AppTheme.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white10, width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClientGroupProfileView(group: group),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryYellow,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.primaryYellow,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${members.length} sucursales asociadas",
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: members.take(3).map((m) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ClientGroupProfileView extends StatefulWidget {
  final ClientGroup group;
  const ClientGroupProfileView({super.key, required this.group});

  @override
  State<ClientGroupProfileView> createState() => _ClientGroupProfileViewState();
}

class _ClientGroupProfileViewState extends State<ClientGroupProfileView> {
  final fmt = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '\$',
    decimalDigits: 0,
  );
  Set<String> _selectedSaleIds = {};
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text(
                    "Eliminar Grupo",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    "Â¿EstÃ¡s seguro de que deseas eliminar este grupo? Las sucursales quedarÃ¡n desvinculadas pero conservarÃ¡n sus balances de forma individual.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text("CANCELAR"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text(
                        "ELIMINAR",
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ClientGroupsActions().deleteGroup(widget.group.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Grupo eliminado."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ClientGroupsActions(),
        builder: (context, child) {
          final currentGroup = ClientGroupsActions().groups.firstWhere(
            (g) => g.id == widget.group.id,
            orElse: () => widget.group,
          );

          return ListenableBuilder(
            listenable: ClientsActions(),
            builder: (context, child) {
              final members = ClientsActions().allClients
                  .where((c) => c.groupId == widget.group.id)
                  .toList();
              final memberIds = members.map((m) => m.id).toList();

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ SUCURSALES MIEMBROS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    const Text(
                      "Sucursales Vinculadas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (members.isEmpty)
                      const Text(
                        "No hay sucursales vinculadas a este grupo.",
                        style: TextStyle(color: Colors.white30),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isMobile ? 3.5 : 3,
                        ),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final client = members[index];
                          return Card(
                            color: Colors.white.withOpacity(0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ClientDetailsView(client: client),
                                  ),
                                );
                              },
                              title: Text(
                                client.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                "Saldo: ${fmt.format(client.balance)}",
                                style: TextStyle(
                                  color: client.balance > 0
                                      ? AppTheme.danger
                                      : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.white54,
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    // â”€â”€ PERÃODO ACTIVO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (memberIds.isNotEmpty)
                      StreamBuilder<QuerySnapshot>(
                        stream: TenantDB
                            .collection('sales')
                            .where(
                              'date',
                              isGreaterThanOrEqualTo: Timestamp.fromDate(
                                currentGroup.lastInvoicedDate,
                              ),
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryYellow,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Error en ventas: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            );
                          }

                          final salesDocs = snapshot.data?.docs ?? [];

                          final groupSales = salesDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final clientId = data['clientId'] ?? '';
                            return memberIds.contains(clientId);
                          }).toList();

                          if (_isFirstLoad && groupSales.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _isFirstLoad) {
                                setState(() {
                                  _selectedSaleIds = groupSales
                                      .map((d) => d.id)
                                      .toSet();
                                  _isFirstLoad = false;
                                });
                              }
                            });
                          }

                          final Map<String, Map<String, dynamic>>
                          consolidatedItems = {};
                          double activeTotalAmount = 0.0;

                          final selectedSales = groupSales
                              .where((d) => _selectedSaleIds.contains(d.id))
                              .toList();

                          for (var doc in selectedSales) {
                            final data = doc.data() as Map<String, dynamic>;
                            final items = data['items'] as List<dynamic>? ?? [];
                            for (var item in items) {
                              final productId = item['productId'] ?? '';
                              final variantName = item['variantName'] ?? '';
                              final name =
                                  item['productName'] ??
                                  item['name'] ??
                                  'Producto';
                              final qty = (item['quantity'] ?? 0).toDouble();
                              final price =
                                  (item['price'] ?? item['unitPrice'] ?? 0)
                                      .toDouble();
                              final total = qty * price;

                              final key = "${productId}_$variantName";
                              if (!consolidatedItems.containsKey(key)) {
                                consolidatedItems[key] = {
                                  'name': variantName.isNotEmpty
                                      ? "$name ($variantName)"
                                      : name,
                                  'quantity': 0.0,
                                  'unitPrice': price,
                                  'total': 0.0,
                                };
                              }
                              consolidatedItems[key]!['quantity'] += qty;
                              consolidatedItems[key]!['total'] += total;
                              activeTotalAmount += total;
                            }
                          }

                          return Card(
                            color: AppTheme.surfaceDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "PerÃ­odo Activo (Ventas Nuevas)",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        fmt.format(activeTotalAmount),
                                        style: const TextStyle(
                                          color: AppTheme.primaryYellow,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.white10,
                                    height: 24,
                                  ),

                                  if (groupSales.isEmpty)
                                    const Text(
                                      "Sin ventas en el perÃ­odo actual.",
                                      style: TextStyle(color: Colors.white30),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Tickets del perÃ­odo:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...groupSales.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final total = (data['total'] ?? 0)
                                              .toDouble();
                                          final date =
                                              (data['date'] as Timestamp?)
                                                  ?.toDate() ??
                                              DateTime.now();
                                          final dateStr = DateFormat(
                                            'dd/MM HH:mm',
                                          ).format(date);
                                          final isSelected = _selectedSaleIds
                                              .contains(doc.id);

                                          return CheckboxListTile(
                                            title: Text(
                                              "Ticket del $dateStr",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Total: ${fmt.format(total)}",
                                              style: const TextStyle(
                                                color: AppTheme.primaryYellow,
                                                fontSize: 12,
                                              ),
                                            ),
                                            value: isSelected,
                                            activeColor: AppTheme.primaryYellow,
                                            checkColor: Colors.black,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedSaleIds.add(doc.id);
                                                } else {
                                                  _selectedSaleIds.remove(
                                                    doc.id,
                                                  );
                                                }
                                              });
                                            },
                                          );
                                        }),

                                        const Divider(
                                          color: Colors.white10,
                                          height: 24,
                                        ),
                                        const Text(
                                          "Resumen Consolidado:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...consolidatedItems.values.map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${item['quantity'].toStringAsFixed(0)}x ${item['name']} @ ${fmt.format(item['unitPrice'])}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  fmt.format(item['total']),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryYellow,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: selectedSales.isEmpty
                                                ? null
                                                : () async {
                                                    DateTime maxDate =
                                                        currentGroup
                                                            .lastInvoicedDate;
                                                    for (var s
                                                        in selectedSales) {
                                                      final d =
                                                          (s.data()
                                                                  as Map<
                                                                    String,
                                                                    dynamic
                                                                  >)['date']
                                                              as Timestamp?;
                                                      if (d != null &&
                                                          d.toDate().isAfter(
                                                            maxDate,
                                                          )) {
                                                        maxDate = d.toDate();
                                                      }
                                                    }
                                                    final unselectedSales =
                                                        groupSales
                                                            .where(
                                                              (s) =>
                                                                  !_selectedSaleIds
                                                                      .contains(
                                                                        s.id,
                                                                      ),
                                                            )
                                                            .toList();
                                                    bool hasOlderUnselected =
                                                        false;
                                                    for (var us
                                                        in unselectedSales) {
                                                      final d =
                                                          (us.data()
                                                                  as Map<
                                                                    String,
                                                                    dynamic
                                                                  >)['date']
                                                              as Timestamp?;
                                                      if (d != null &&
                                                          d.toDate().isBefore(
                                                            maxDate,
                                                          )) {
                                                        hasOlderUnselected =
                                                            true;
                                                        break;
                                                      }
                                                    }
                                                    if (hasOlderUnselected) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "No podés excluir tickets antiguos.",
                                                          ),
                                                          backgroundColor:
                                                              AppTheme.danger,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (c) => AlertDialog(
                                                        backgroundColor:
                                                            AppTheme
                                                                .surfaceDark,
                                                        title: const Text(
                                                          "Congelar",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        content: const Text(
                                                          "¿Confirmar?",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  c,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              "CANCELAR",
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  c,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              "FACTURAR",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      final List<
                                                        Map<String, dynamic>
                                                      >
                                                      itemsList = consolidatedItems
                                                          .values
                                                          .map(
                                                            (item) => {
                                                              'name':
                                                                  item['name'],
                                                              'quantity':
                                                                  item['quantity'],
                                                              'unitPrice':
                                                                  item['unitPrice'],
                                                              'total':
                                                                  item['total'],
                                                            },
                                                          )
                                                          .toList();
                                                      try {
                                                        await ClientGroupsActions()
                                                            .invoiceGroup(
                                                              widget.group.id,
                                                              activeTotalAmount,
                                                              itemsList,
                                                              Timestamp.fromDate(
                                                                maxDate.add(
                                                                  const Duration(
                                                                    milliseconds:
                                                                        1,
                                                                  ),
                                                                ),
                                                              ),
                                                              _selectedSaleIds
                                                                  .toList(),
                                                            );
                                                        if (context.mounted) {
                                                          setState(() {
                                                            _selectedSaleIds
                                                                .clear();
                                                            _isFirstLoad = true;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "OK",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted)
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                "Error",
                                                              ),
                                                            ),
                                                          );
                                                      }
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.receipt_long,
                                              color: Colors.black,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              "FACTURAR",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const Text(
                        "Vinculá sucursales especiales desde Clientes Especiales.",
                        style: TextStyle(color: Colors.white30),
                      ),

                    const SizedBox(height: 24),
                    const Text(
                      "Facturas Pendientes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: TenantDB
                          .collection('clientGroups')
                          .doc(widget.group.id)
                          .collection('invoices')
                          .where('status', isEqualTo: 'invoiced')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryYellow,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            "Error en facturas: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final invoices = snapshot.data?.docs ?? [];
                        if (invoices.isEmpty) {
                          return const Text(
                            "Sin facturas pendientes de cobro.",
                            style: TextStyle(color: Colors.white30),
                          );
                        }

                        return Column(
                          children: invoices.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final total = (data['totalAmount'] ?? 0.0)
                                .toDouble();
                            final items = data['items'] as List<dynamic>? ?? [];
                            final invoicedAt =
                                (data['invoicedAt'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            final formattedDate = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(invoicedAt);

                            return Card(
                              color: Colors.white.withOpacity(0.02),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                iconColor: AppTheme.primaryYellow,
                                title: Text(
                                  "Factura del $formattedDate",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Total: ${fmt.format(total)}",
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppTheme.danger,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            backgroundColor:
                                                AppTheme.surfaceDark,
                                            title: const Text(
                                              "Eliminar Factura",
                                            ),
                                            content: const Text(
                                              "Â¿EstÃ¡s seguro de eliminar esta factura? Esto no restaurarÃ¡ los tickets al perÃ­odo activo, solo borrarÃ¡ el registro de cobro.",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, false),
                                                child: const Text("CANCELAR"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, true),
                                                child: const Text(
                                                  "ELIMINAR",
                                                  style: TextStyle(
                                                    color: AppTheme.danger,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ClientGroupsActions()
                                              .deleteInvoice(
                                                widget.group.id,
                                                doc.id,
                                              );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Factura eliminada.",
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _showPaymentDialog(
                                        widget.group,
                                        doc.id,
                                        total,
                                        members,
                                      ),
                                      child: const Text(
                                        "COBRAR",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Detalle consolidado de productos:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...items.map((item) {
                                          final q = (item['quantity'] ?? 0)
                                              .toDouble();
                                          final n = item['name'] ?? '';
                                          final uPrice =
                                              (item['price'] ??
                                                      item['unitPrice'] ??
                                                      0.0)
                                                  .toDouble();
                                          final t = (item['total'] ?? 0)
                                              .toDouble();
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${q.toStringAsFixed(0)}x $n @ ${fmt.format(uPrice)}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  fmt.format(t),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Historial de Facturas Cobradas:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: TenantDB
                          .collection('clientGroups')
                          .doc(widget.group.id)
                          .collection('invoices')
                          .where('status', isEqualTo: 'paid')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryYellow,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            "Error en facturas cobradas: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        var paidInvoices = snapshot.data?.docs ?? [];
                        if (paidInvoices.isEmpty) {
                          return const Text(
                            "No hay facturas cobradas.",
                            style: TextStyle(color: Colors.white30),
                          );
                        }

                        // Sort descending by paidAt or invoicedAt
                        paidInvoices.sort((a, b) {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;
                          final dtA =
                              (dataA['paidAt'] as Timestamp?)?.toDate() ??
                              (dataA['invoicedAt'] as Timestamp?)?.toDate() ??
                              DateTime.now();
                          final dtB =
                              (dataB['paidAt'] as Timestamp?)?.toDate() ??
                              (dataB['invoicedAt'] as Timestamp?)?.toDate() ??
                              DateTime.now();
                          return dtB.compareTo(dtA);
                        });

                        return Column(
                          children: paidInvoices.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final total = (data['totalAmount'] ?? 0.0)
                                .toDouble();
                            final items = data['items'] as List<dynamic>? ?? [];
                            final paidAt =
                                (data['paidAt'] as Timestamp?)?.toDate() ??
                                (data['invoicedAt'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            final formattedDate = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(paidAt);

                            return Card(
                              color: Colors.white.withOpacity(0.02),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Colors.green,
                                  width: 1.5,
                                ),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                iconColor: Colors.green,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Cobrada el $formattedDate",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_calendar,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: paidAt,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2101),
                                            );
                                        if (picked != null) {
                                          if (!context.mounted) return;
                                          final TimeOfDay? time =
                                              await showTimePicker(
                                                context: context,
                                                initialTime:
                                                    TimeOfDay.fromDateTime(
                                                      paidAt,
                                                    ),
                                              );
                                          if (time != null) {
                                            final newDate = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                              time.hour,
                                              time.minute,
                                            );
                                            await ClientGroupsActions()
                                                .updateInvoicePaidDate(
                                                  widget.group.id,
                                                  doc.id,
                                                  newDate,
                                                );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Fecha actualizada",
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  "Total: ${fmt.format(total)}",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Detalle de productos facturados:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...items.map((item) {
                                          final q = (item['quantity'] ?? 0)
                                              .toDouble();
                                          final n = item['name'] ?? '';
                                          final uPrice =
                                              (item['price'] ??
                                                      item['unitPrice'] ??
                                                      0.0)
                                                  .toDouble();
                                          final t = (item['total'] ?? 0)
                                              .toDouble();
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${q.toStringAsFixed(0)}x $n @ ${fmt.format(uPrice)}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  fmt.format(t),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPaymentDialog(
    ClientGroup group,
    String invoiceId,
    double totalDebt,
    List<Client> members,
  ) {
    final cashController = TextEditingController(
      text: totalDebt.toStringAsFixed(0),
    );
    final transferController = TextEditingController(text: '0');
    bool isSaving = false;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final double cash = double.tryParse(cashController.text) ?? 0.0;
              final double transfer =
                  double.tryParse(transferController.text) ?? 0.0;
              final double totalPaid = cash + transfer;
              final double remaining = totalDebt - totalPaid;

              return Container(
                width: 400,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cobrar Factura: ${group.name}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monto de la Factura: ${fmt.format(totalDebt)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    TextField(
                      controller: cashController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Monto Efectivo",
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppTheme.primaryYellow,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transferController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Monto Transferencia",
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppTheme.primaryYellow,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Cobrado:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          fmt.format(totalPaid),
                          style: const TextStyle(
                            color: AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Saldo Restante:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          fmt.format(remaining),
                          style: TextStyle(
                            color: remaining > 0
                                ? AppTheme.danger
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Fecha de Cobro:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.edit_calendar,
                            color: AppTheme.primaryYellow,
                          ),
                          label: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2101),
                            );
                            if (d != null) {
                              if (!context.mounted) return;
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedDate,
                                ),
                              );
                              if (t != null) {
                                setStateDialog(() {
                                  selectedDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    t.hour,
                                    t.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            "CANCELAR",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                          ),
                          onPressed: (isSaving || totalPaid <= 0)
                              ? null
                              : () async {
                                  setStateDialog(() => isSaving = true);

                                  try {
                                    double pendingCash = cash;
                                    double pendingTransfer = transfer;

                                    final batch = FirebaseFirestore.instance
                                        .batch();
                                    final today = DateTime.now();

                                    final invoiceDoc = await TenantDB.collection('clientGroups')
                                        .doc(group.id)
                                        .collection('invoices')
                                        .doc(invoiceId)
                                        .get();
                                    final saleIds = List<String>.from(
                                      invoiceDoc.data()?['saleIds'] ?? [],
                                    );

                                    if (saleIds.isEmpty) {
                                      // Fallback para facturas viejas generadas antes de la actualizaciÃ³n
                                      for (var client in members) {
                                        if (client.balance <= 0) continue;
                                        if (pendingCash <= 0 &&
                                            pendingTransfer <= 0)
                                          break;

                                        double clientDebt = client.balance;
                                        double clientPaidCash = 0.0;
                                        double clientPaidTransfer = 0.0;

                                        if (pendingCash > 0) {
                                          if (pendingCash >= clientDebt) {
                                            clientPaidCash = clientDebt;
                                            pendingCash -= clientDebt;
                                            clientDebt = 0.0;
                                          } else {
                                            clientPaidCash = pendingCash;
                                            clientDebt -= pendingCash;
                                            pendingCash = 0.0;
                                          }
                                        }

                                        if (clientDebt > 0 &&
                                            pendingTransfer > 0) {
                                          if (pendingTransfer >= clientDebt) {
                                            clientPaidTransfer = clientDebt;
                                            pendingTransfer -= clientDebt;
                                            clientDebt = 0.0;
                                          } else {
                                            clientPaidTransfer =
                                                pendingTransfer;
                                            clientDebt -= pendingTransfer;
                                            pendingTransfer = 0.0;
                                          }
                                        }

                                        final double clientTotalPaid =
                                            clientPaidCash + clientPaidTransfer;
                                        if (clientTotalPaid > 0) {
                                          final newBalance =
                                              client.balance - clientTotalPaid;
                                          batch.update(
                                            TenantDB.collection('clients')
                                                .doc(client.id),
                                            {'balance': newBalance},
                                          );
                                        }
                                      }
                                    } else {
                                      // Nuevo sistema: pagar tickets exactos
                                      Map<String, double>
                                      clientTotalDeductions = {};

                                      for (var saleId in saleIds) {
                                        if (pendingCash <= 0 &&
                                            pendingTransfer <= 0)
                                          break;

                                        final saleDoc = await TenantDB.collection('sales')
                                            .doc(saleId)
                                            .get();
                                        if (!saleDoc.exists) continue;

                                        final saleData = saleDoc.data()!;
                                        final clientId =
                                            saleData['clientId'] as String?;
                                        if (clientId == null) continue;

                                        double saleTotal =
                                            (saleData['total'] ?? 0).toDouble();
                                        double salePaid =
                                            (saleData['paidAmount'] ?? 0)
                                                .toDouble();
                                        double saleDebt = saleTotal - salePaid;

                                        if (saleDebt <= 0) continue;

                                        double thisSalePaidCash = 0.0;
                                        double thisSalePaidTransfer = 0.0;

                                        if (pendingCash > 0) {
                                          if (pendingCash >= saleDebt) {
                                            thisSalePaidCash = saleDebt;
                                            pendingCash -= saleDebt;
                                            saleDebt = 0.0;
                                          } else {
                                            thisSalePaidCash = pendingCash;
                                            saleDebt -= pendingCash;
                                            pendingCash = 0.0;
                                          }
                                        }

                                        if (saleDebt > 0 &&
                                            pendingTransfer > 0) {
                                          if (pendingTransfer >= saleDebt) {
                                            thisSalePaidTransfer = saleDebt;
                                            pendingTransfer -= saleDebt;
                                            saleDebt = 0.0;
                                          } else {
                                            thisSalePaidTransfer =
                                                pendingTransfer;
                                            saleDebt -= pendingTransfer;
                                            pendingTransfer = 0.0;
                                          }
                                        }

                                        double thisSaleTotalPaid =
                                            thisSalePaidCash +
                                            thisSalePaidTransfer;
                                        if (thisSaleTotalPaid > 0) {
                                          batch.update(saleDoc.reference, {
                                            'paidAmount':
                                                salePaid + thisSaleTotalPaid,
                                          });
                                          clientTotalDeductions[clientId] =
                                              (clientTotalDeductions[clientId] ??
                                                  0.0) +
                                              thisSaleTotalPaid;
                                        }
                                      }

                                      for (var client in members) {
                                        final deduction =
                                            clientTotalDeductions[client.id] ??
                                            0.0;
                                        if (deduction > 0) {
                                          final newBalance =
                                              client.balance - deduction;
                                          batch.update(
                                            TenantDB.collection('clients')
                                                .doc(client.id),
                                            {'balance': newBalance},
                                          );
                                        }
                                      }
                                    }

                                    if (totalPaid > 0) {
                                      final payDoc = FirebaseFirestore.instance
                                          .collection('payments')
                                          .doc();
                                      batch.set(payDoc, {
                                        'isGroup': true,
                                        'groupId': group.id,
                                        'groupName': group.name,
                                        'amount': totalPaid,
                                        'method': (cash > 0 && transfer > 0)
                                            ? 'Mixto'
                                            : (cash > 0
                                                  ? 'Efectivo'
                                                  : 'Transferencia'),
                                        'cashAmount': cash,
                                        'transferAmount': transfer,
                                        'date': Timestamp.fromDate(
                                          selectedDate,
                                        ),
                                        'invoiceId': invoiceId,
                                      });
                                    }

                                    await ClientGroupsActions()
                                        .updateInvoicePaidDate(
                                          group.id,
                                          invoiceId,
                                          selectedDate,
                                        );
                                    await ClientGroupsActions().payInvoice(
                                      group.id,
                                      invoiceId,
                                    );
                                    await batch.commit();

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Factura cobrada y registrada exitosamente.",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error al registrar el cobro: $e",
                                          ),
                                          backgroundColor: AppTheme.danger,
                                        ),
                                      );
                                    }
                                  } finally {
                                    setStateDialog(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "CONFIRMAR COBRO",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
