import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UltimateMathFix {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ultimate_math_done') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      final clientsSnap = await firestore.collection('clients').get();
      String? marcosId, damianId, marcelaId, normaId;
      
      for (var c in clientsSnap.docs) {
        String name = c.data()['name'].toString().toLowerCase();
        if (name == 'marcos') marcosId = c.id;
        if (name == 'damian') damianId = c.id;
        if (name.contains('marcela') && name.contains('villegas')) marcelaId = c.id;
        else if (name == 'marcela') marcelaId = c.id;
        if (name == 'norma') normaId = c.id;
      }

      // 1. LIMPIAR A MARCOS
      if (marcosId != null) {
        final s = await firestore.collection('sales').where('clientId', isEqualTo: marcosId).get();
        for (var doc in s.docs) batch.delete(doc.reference);
        final p = await firestore.collection('payments').where('clientId', isEqualTo: marcosId).get();
        for (var doc in p.docs) batch.delete(doc.reference);
        final d = await firestore.collection('manual_debts').where('clientId', isEqualTo: marcosId).get();
        for (var doc in d.docs) batch.delete(doc.reference);
        batch.update(firestore.collection('clients').doc(marcosId), {'balance': 0.0});
      }

      // 2. ARREGLAR NORMA (Borrar el ticket duplicado de 101800 si existe)
      if (normaId != null) {
        final s = await firestore.collection('sales').where('clientId', isEqualTo: normaId).get();
        int duplicateCount = 0;
        for (var doc in s.docs) {
          if ((doc.data()['total'] ?? 0).toDouble() == 101800 && (doc.data()['paidAmount'] ?? 0).toDouble() == 0) {
            duplicateCount++;
            if (duplicateCount > 1) { // Borramos el duplicado
               batch.delete(doc.reference);
            }
          }
        }
      }

      // 3. ARREGLAR MARCELA (Agregar el pago perdido de 67800)
      if (marcelaId != null) {
         final pRef = firestore.collection('payments').doc();
         batch.set(pRef, {
           'clientId': marcelaId,
           'amount': 67800.0,
           'type': 'transferencia',
           'date': Timestamp.fromDate(DateTime.now()), // Lo ponemos hoy asi lo ve en CC
         });
      }

      // 4. ARREGLAR DAMIAN (Agregar la deuda faltante de 20300 que se perdió)
      if (damianId != null) {
         final dRef = firestore.collection('manual_debts').doc();
         batch.set(dRef, {
           'clientId': damianId,
           'amount': 20300.0,
           'date': Timestamp.fromDate(DateTime.now()), // Lo ponemos hoy asi cuadra
           'reason': 'Ajuste de deuda perdida',
         });
      }

      await batch.commit();

      // 5. RESINCRONIZAR SUS SALDOS PARA QUE LA MATEMÁTICA SEA PERFECTA
      final batch2 = firestore.batch();
      List<String?> idsToSync = [marcelaId, damianId, normaId]; // Marcos ya esta en 0
      
      for (var id in idsToSync) {
        if (id == null) continue;
        final doc = await firestore.collection('clients').doc(id).get();
        
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
        batch2.update(doc.reference, {'balance': newBalance});
      }

      await batch2.commit();
      await prefs.setBool('ultimate_math_done', true);
    } catch (e) {
      print('ERROR: $e');
    }
  }
}
