import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('==== INICIANDO FIX ====');

  final firestore = FirebaseFirestore.instance;
  
  final paymentsQuery = await firestore.collection('payments').get();
  
  for (var doc in paymentsQuery.docs) {
    final data = doc.data();
    final ts = data['date'] as Timestamp?;
    if (ts != null) {
      final date = ts.toDate();
      if (!data.containsKey('invoiceId') && !data.containsKey('isGroup')) {
        print('PAGO EXISTENTE: ${doc.id} - FECHA: $date - CIUDAD: ${data['clientCity']} - MONTO: \$${data['amount']}');
      }
    }
  }

  final groups = await firestore.collection('clientGroups').get();
  for (var g in groups.docs) {
    final invoices = await g.reference.collection('invoices').where('status', isEqualTo: 'paid').get();
    for (var inv in invoices.docs) {
      final idata = inv.data();
      final its = idata['paidAt'] as Timestamp?;
      print('FACTURA GRUPO ${g.data()['name']}: ${inv.id} - COBRADA EL ${its?.toDate()} - TOTAL: \$${idata['total']}');
    }
  }
  
  print('==== FIN FIX ====');
}
