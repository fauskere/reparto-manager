import 'package:cloud_firestore/cloud_firestore.dart';

class RecoverPayments {
  static Future<void> run() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final salesSnap = await firestore.collection('sales').get();
      final batch = firestore.batch();
      int recoveredCount = 0;

      for (var sale in salesSnap.docs) {
        final data = sale.data();
        double currentPaid = (data['paidAmount'] ?? 0).toDouble();
        double cash = (data['cashAmount'] ?? 0).toDouble();
        double transfer = (data['transferAmount'] ?? 0).toDouble();
        
        double originalPaid = cash + transfer;
        
        if (originalPaid > currentPaid) {
          print('Encontrado pago recortado! Venta ID: ${sale.id}');
          print('Cliente: ${data['clientName']} | Total Ticket: ${data['total']}');
          print('Monto actual: $currentPaid -> Monto original (cash+transf): $originalPaid');
          print('Diferencia a recuperar: ${originalPaid - currentPaid}');
          print('-----------------------------------------');
          
          batch.update(sale.reference, {'paidAmount': originalPaid});
          recoveredCount++;
          
          // Also need to correct the client balance!
          // If the paidAmount was artificially reduced by FixAllBalances, the client's balance was incorrectly INCREASED (they owe more than they should).
          // We must DECREASE their balance by the difference!
          if (data['clientId'] != null) {
             batch.update(firestore.collection('clients').doc(data['clientId']), {
               'balance': FieldValue.increment(-(originalPaid - currentPaid))
             });
             print('Ajustando saldo del cliente ${data['clientName']} en -${originalPaid - currentPaid}');
          }
        }
      }

      if (recoveredCount > 0) {
        print('Realizando cambios en Firebase...');
        await batch.commit();
        print('Exito! $recoveredCount pagos recuperados y saldos ajustados.');
      } else {
        print('No se encontraron pagos para recuperar.');
      }
    } catch (e) {
      print('ERROR: $e');
    }
  }
}
