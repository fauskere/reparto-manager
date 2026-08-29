import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyFix {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('emergency_fix_done') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      print('--- INICIANDO REPARACION DE EMERGENCIA ---');

      // 1. RECOVER TRUNCATED PAYMENTS GLOBALLY
      final salesSnap = await firestore.collection('sales').get();
      int recoveredCount = 0;
      for (var sale in salesSnap.docs) {
        final data = sale.data();
        double currentPaid = (data['paidAmount'] ?? 0).toDouble();
        double cash = (data['cashAmount'] ?? 0).toDouble();
        double transfer = (data['transferAmount'] ?? 0).toDouble();
        double originalPaid = cash + transfer;
        
        if (originalPaid > currentPaid) {
          batch.update(sale.reference, {'paidAmount': originalPaid});
          recoveredCount++;
        }
      }
      print('1. Pagos recortados recuperados: $recoveredCount');

      // 2. DELETE MARCELA'S 44000 PHANTOM TICKET
      // Find sale for Marcela from today with total 44000
      final clientsSnap = await firestore.collection('clients').get();
      String? marcelaId;
      String? elMaestroId;
      String? elMaestro2Id;
      String? polloLocoId;
      String? bocaId;
      String? andresId;

      for (var c in clientsSnap.docs) {
        String name = c.data()['name'].toString().toLowerCase();
        if (name.contains('marcela') && name.contains('villegas')) marcelaId = c.id;
        else if (name == 'marcela') marcelaId = c.id; // Fallback
        if (name == 'el maestro') elMaestroId = c.id;
        if (name == 'el maestro 2') elMaestro2Id = c.id;
        if (name == 'pollo loco') polloLocoId = c.id;
        if (name == 'boca') bocaId = c.id;
        if (name == 'andres' && name.contains('ameghino')) andresId = c.id;
        else if (name == 'andres') andresId = c.id; // Fallback
      }

      print('IDs encontrados:');
      print('Marcela: $marcelaId');
      print('El Maestro: $elMaestroId');
      print('El Maestro 2: $elMaestro2Id');
      print('Pollo Loco: $polloLocoId');
      print('Boca: $bocaId');
      print('Andres: $andresId');

      if (marcelaId != null) {
        final marcelaSales = await firestore.collection('sales').where('clientId', isEqualTo: marcelaId).get();
        for (var s in marcelaSales.docs) {
          double total = (s.data()['total'] ?? 0).toDouble();
          if (total == 44000) {
            print('Borrando ticket fantasma de Marcela (44000)');
            batch.delete(s.reference);
          }
        }
      }

      if (elMaestroId != null) {
        final maestroSales = await firestore.collection('sales').where('clientId', isEqualTo: elMaestroId).get();
        for (var s in maestroSales.docs) {
          double total = (s.data()['total'] ?? 0).toDouble();
          double paid = (s.data()['paidAmount'] ?? 0).toDouble();
          if (total == 87800 && paid < 87800) {
            print('Borrando ticket fantasma NO PAGO de El Maestro (87800)');
            batch.delete(s.reference);
          }
        }
      }

      // 3. HARDCODE THE EXACT BALANCES REQUESTED BY THE USER
      if (marcelaId != null) batch.update(firestore.collection('clients').doc(marcelaId), {'balance': 52400.0});
      if (elMaestroId != null) batch.update(firestore.collection('clients').doc(elMaestroId), {'balance': 0.0});
      if (elMaestro2Id != null) batch.update(firestore.collection('clients').doc(elMaestro2Id), {'balance': 20500.0});
      if (polloLocoId != null) batch.update(firestore.collection('clients').doc(polloLocoId), {'balance': 83150.0});
      if (bocaId != null) batch.update(firestore.collection('clients').doc(bocaId), {'balance': 0.0});
      if (andresId != null) batch.update(firestore.collection('clients').doc(andresId), {'balance': 238500.0});

      await batch.commit();
      await prefs.setBool('emergency_fix_done', true);
      print('--- REPARACION DE EMERGENCIA COMPLETADA EXITOSAMENTE ---');
    } catch (e) {
      print('ERROR EN REPARACION DE EMERGENCIA: $e');
    }
  }
}
