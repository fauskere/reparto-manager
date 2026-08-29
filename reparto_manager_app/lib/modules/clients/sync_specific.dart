import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncSpecificBalances {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sync_specific_done') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      print('--- INICIANDO RESINCRONIZACION DE HISTORIAL ---');

      final clientsSnap = await firestore.collection('clients').get();
      for (var doc in clientsSnap.docs) {
        String name = doc.data()['name'].toString().toLowerCase();
        
        // Solo resincronizamos a los que tocaste el historial hoy para que les cuadre perfecto
        if (name == 'pollo loco' || (name.contains('marcela') && name.contains('villegas')) || name == 'marcela') {
          final clientId = doc.id;
          
          final salesSnap = await firestore.collection('sales').where('clientId', isEqualTo: clientId).get();
          double totalSales = 0;
          double totalSalePaid = 0;
          for (var sale in salesSnap.docs) {
            double t = (sale.data()['total'] ?? 0).toDouble();
            double p = (sale.data()['paidAmount'] ?? 0).toDouble();
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
          print('Cliente: ${doc.data()['name']} | Nuevo Saldo Sincronizado: $newBalance');
        }
      }

      await batch.commit();
      await prefs.setBool('sync_specific_done', true);
      print('--- RESINCRONIZACION COMPLETADA ---');
    } catch (e) {
      print('ERROR: $e');
    }
  }
}
