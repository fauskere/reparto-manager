import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final clients = await FirebaseFirestore.instance.collection('clients').get();
  int count = 0;
  for (var doc in clients.docs) {
    double realBalance = 0.0;
    
    final sales = await FirebaseFirestore.instance.collection('sales').where('clientId', isEqualTo: doc.id).get();
    for (var sale in sales.docs) {
      double total = (sale.data()['total'] ?? 0.0).toDouble();
      double paid = 0.0;
      if (sale.data().containsKey('paidAmount') && sale.data()['paidAmount'] != null) {
        paid = (sale.data()['paidAmount'] as num).toDouble();
      } else if (sale.data()['paymentMethod'] == 'Pendiente') {
        paid = 0.0;
      } else {
        paid = total;
      }
      realBalance += (total - paid);
    }
    
    final payments = await FirebaseFirestore.instance.collection('payments').where('clientId', isEqualTo: doc.id).get();
    for (var payment in payments.docs) {
      double amount = (payment.data()['amount'] ?? 0.0).toDouble();
      realBalance -= amount;
    }
    
    final manualDebts = await FirebaseFirestore.instance.collection('manual_debts').where('clientId', isEqualTo: doc.id).get();
    for (var debt in manualDebts.docs) {
      double amount = (debt.data()['amount'] ?? 0.0).toDouble();
      realBalance += amount;
    }
    
    double currentBalance = (doc.data()['balance'] ?? 0.0).toDouble();
    if ((currentBalance - realBalance).abs() > 0.01) {
      print('Fixing ${doc.data()['name']}: $currentBalance -> $realBalance');
      await FirebaseFirestore.instance.collection('clients').doc(doc.id).update({'balance': realBalance});
      count++;
    }
  }
  print('FIXED $count CLIENTS. READY.');
}
