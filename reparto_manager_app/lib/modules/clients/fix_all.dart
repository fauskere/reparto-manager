import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FixAllBalances {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('fix_all_balances_v2') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final clientsSnap = await firestore.collection('clients').get();
      final batch = firestore.batch();

      for (var doc in clientsSnap.docs) {
        final clientId = doc.id;

        final salesSnap = await firestore.collection('sales').where('clientId', isEqualTo: clientId).get();
        double totalSales = 0;
        double totalSalePaid = 0;
        for (var sale in salesSnap.docs) {
          double t = (sale.data()['total'] ?? 0).toDouble();
          double p = (sale.data()['paidAmount'] ?? 0).toDouble();
          if (p > t && t > 0) { 
            p = t; 
            batch.update(sale.reference, {'paidAmount': t}); 
          }
          totalSales += t;
          totalSalePaid += p;
        }

        final debtsSnap = await firestore.collection('manual_debts').where('clientId', isEqualTo: clientId).get();
        double totalDebts = 0;
        for (var debt in debtsSnap.docs) {
          totalDebts += (debt.data()['amount'] ?? 0).toDouble();
        }

        final paysSnap = await firestore.collection('payments').where('clientId', isEqualTo: clientId).get();
        double totalPays = 0;
        for (var pay in paysSnap.docs) {
          if (pay.data()['type'] != 'sale_payment') {
            totalPays += (pay.data()['amount'] ?? 0).toDouble();
          }
        }

        double newBalance = totalSales - totalSalePaid + totalDebts - totalPays;
        batch.update(doc.reference, {'balance': newBalance});
        print('Cliente: ${doc.data()['name']} | Nuevo Saldo: $newBalance');
      }

      await batch.commit();
      await prefs.setBool('fix_all_balances_v2', true);
      print('ALL BALANCES FIXED');
    } catch (e) {
      print('ERROR: $e');
    }
  }
}