import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../clients/client.dart';

class GlobalLedgerView extends StatefulWidget {
  const GlobalLedgerView({super.key});

  @override
  State<GlobalLedgerView> createState() => _GlobalLedgerViewState();
}

class _GlobalLedgerViewState extends State<GlobalLedgerView> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  List<dynamic> _filteredTransactions = [];
  String _searchQuery = '';
  Map<String, Client> _clientsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAllLedger();
  }

  Future<void> _loadAllLedger() async {
    setState(() => _isLoading = true);
    final db = FirebaseFirestore.instance;

    // Cargar clientes para tener los nombres
    final clientsSnap = await db.collection('clients').get();
    for (var doc in clientsSnap.docs) {
      _clientsMap[doc.id] = Client.fromMap(doc.data(), doc.id);
    }

    // Cargar últimos 300 movimientos de cada colección para no sobrecargar
    final salesSnap = await db.collection('sales').orderBy('date', descending: true).limit(300).get();
    final paysSnap = await db.collection('payments').orderBy('date', descending: true).limit(300).get();
    final debtsSnap = await db.collection('manual_debts').orderBy('date', descending: true).limit(300).get();

    List<dynamic> allTx = [];

    for (var doc in salesSnap.docs) {
      var data = doc.data();
      double total = (data['total'] ?? 0).toDouble();
      double paid = (data['paidAmount'] ?? total).toDouble();
      if (total - paid != 0) { // Solo si generó deuda
        data['id'] = doc.id;
        data['type'] = 'sale';
        allTx.add(data);
      }
    }
    for (var doc in paysSnap.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      data['type'] = 'payment';
      allTx.add(data);
    }
    for (var doc in debtsSnap.docs) {
      var data = doc.data();
      data['id'] = doc.id;
      data['type'] = 'manual_debt';
      allTx.add(data);
    }

    // Ordenar todo por fecha
    allTx.sort((a, b) {
      DateTime dateA = (a['date'] as Timestamp).toDate();
      DateTime dateB = (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA);
    });

    setState(() {
      _transactions = allTx;
      _filteredTransactions = allTx;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      setState(() => _filteredTransactions = _transactions);
      return;
    }

    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        String cId = tx['clientId'] ?? '';
        Client? client = _clientsMap[cId];
        if (client == null) return false;
        
        return client.name.toLowerCase().contains(_searchQuery) ||
               client.nickname.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auditoría de Saldos Global"),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filter,
              decoration: const InputDecoration(
                labelText: 'Filtrar por cliente o apodo...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      String type = tx['type'];
                      DateTime date = (tx['date'] as Timestamp).toDate();
                      String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
                      String cId = tx['clientId'] ?? '';
                      Client? client = _clientsMap[cId];
                      String clientName = client?.name ?? 'Cliente Eliminado/Desconocido';

                      if (type == 'sale') {
                        double debtAdded = (tx['total'] ?? 0).toDouble() - (tx['paidAmount'] ?? 0).toDouble();
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppTheme.primaryYellow, child: Icon(Icons.shopping_cart, color: Colors.black)),
                            title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$dateStr\nVenta en Fiado"),
                            trailing: Text("+\$${debtAdded.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        );
                      } else if (type == 'payment') {
                        double amount = (tx['amount'] ?? 0).toDouble();
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.attach_money, color: Colors.black)),
                            title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$dateStr\nPago Recibido (${tx['method'] ?? 'Efectivo'})"),
                            trailing: Text("-\$${amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        );
                      } else {
                        double amount = (tx['amount'] ?? 0).toDouble();
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppTheme.danger, child: Icon(Icons.history, color: Colors.white)),
                            title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$dateStr\nAjuste Manual: ${tx['description'] ?? ''}"),
                            trailing: Text(amount > 0 ? "+\$${amount.toStringAsFixed(0)}" : "-\$${amount.abs().toStringAsFixed(0)}", style: TextStyle(color: amount > 0 ? AppTheme.danger : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
