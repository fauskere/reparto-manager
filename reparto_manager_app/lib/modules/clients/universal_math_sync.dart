import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UniversalMathSync {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('universal_math_sync_v2') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // 1. Arreglar el tipo de pago de Marcela que quedó en minúscula
      final clientsSnap = await firestore.collection('clients').get();
      String? marcelaId;
      for (var c in clientsSnap.docs) {
        String name = c.data()['name'].toString().toLowerCase();
        if (name.contains('marcela') && name.contains('villegas')) marcelaId = c.id;
        else if (name == 'marcela') marcelaId = c.id;
      }
      if (marcelaId != null) {
        final paysSnap = await firestore.collection('payments').where('clientId', isEqualTo: marcelaId).get();
        for (var p in paysSnap.docs) {
          if ((p.data()['amount'] ?? 0).toDouble() == 67800.0 && p.data()['type'] == 'transferencia') {
            batch.update(p.reference, {'type': 'Transferencia'});
          }
        }
      }

      // 2. SINCRONIZAR A TODOS LOS CLIENTES DE LA BASE DE DATOS
      for (var doc in clientsSnap.docs) {
        final id = doc.id;
        final salesSnap = await firestore.collection('sales').where('clientId', isEqualTo: id).get();
        double totalSales = 0;
        double totalSalePaid = 0;
        for (var sale in salesSnap.docs) {
          totalSales += (sale.data()['total'] ?? 0).toDouble();
          totalSalePaid += (sale.data()['paidAmount'] ?? 0).toDouble();
        }

        final debtsSnap = await firestore.collection('manual_debts').where('clientId', isEqualTo: id).get();
        double totalDebts = 0;
        for (var debt in debtsSnap.docs) {
          totalDebts += (debt.data()['amount'] ?? 0).toDouble();
        }

        final paysSnap = await firestore.collection('payments').where('clientId', isEqualTo: id).get();
        double totalPays = 0;
        for (var pay in paysSnap.docs) {
          if (pay.data()['type'] != 'sale_payment') {
            totalPays += (pay.data()['amount'] ?? 0).toDouble();
          }
        }

        double newBalance = totalSales - totalSalePaid + totalDebts - totalPays;
        batch.update(doc.reference, {'balance': newBalance});
      }

      await batch.commit();
      await prefs.setBool('universal_math_sync_v2', true);
    } catch (e) {
      print('ERROR: $e');
    }
  }
}
