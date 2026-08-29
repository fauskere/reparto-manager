import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Find Enrique
  final clients = await FirebaseFirestore.instance.collection('clients')
      .where('name', isGreaterThanOrEqualTo: 'Enrique')
      .where('name', isLessThan: 'Enriquez')
      .get();
      
  if (clients.docs.isEmpty) {
    print('No Enrique found');
    exit(0);
  }
  
  String cId = clients.docs.first.id;
  final clientData = clients.docs.first.data();
  print('Found Enrique: \$cId');
  
  final sales = await FirebaseFirestore.instance.collection('sales').where('clientId', isEqualTo: cId).get();
  final pays = await FirebaseFirestore.instance.collection('payments').where('clientId', isEqualTo: cId).get();
  
  File f = File('C:\\Reparto-Manager\\dump.txt');
  String out = 'Enrique (ID: \$cId)\n';
  out += 'Current Balance: \${clientData['balance']}\n\n';
  
  out += '--- SALES ---\n';
  for (var s in sales.docs) {
    var data = s.data();
    DateTime d = (data['date'] as Timestamp).toDate();
    out += '\${d.toString()} | Total: \${data['total']} | Paid: \${data['paidAmount']} | Method: \${data['paymentMethod']}\n';
  }
  
  out += '\n--- PAYMENTS ---\n';
  for (var p in pays.docs) {
    var data = p.data();
    DateTime d = (data['date'] as Timestamp).toDate();
    out += '\${d.toString()} | Amount: \${data['amount']} | Method: \${data['method']}\n';
  }
  
  // Find Ulla
  final clientsUlla = await FirebaseFirestore.instance.collection('clients')
      .where('name', isGreaterThanOrEqualTo: 'Ulla')
      .where('name', isLessThan: 'Ullb')
      .get();
      
  if (clientsUlla.docs.isNotEmpty) {
    String uId = clientsUlla.docs.first.id;
    final uData = clientsUlla.docs.first.data();
    
    final salesU = await FirebaseFirestore.instance.collection('sales').where('clientId', isEqualTo: uId).get();
    final paysU = await FirebaseFirestore.instance.collection('payments').where('clientId', isEqualTo: uId).get();
    final manualDebtsU = await FirebaseFirestore.instance.collection('manual_debts').where('clientId', isEqualTo: uId).get();
    
    out += '\n====================\nUlla (ID: \$uId)\n';
    out += 'Current Balance: \${uData['balance']}\n\n';
    
    out += '--- SALES ---\n';
    for (var s in salesU.docs) {
      var data = s.data();
      DateTime d = (data['date'] as Timestamp).toDate();
      out += '\${d.toString()} | Total: \${data['total']} | Paid: \${data['paidAmount']} | Method: \${data['paymentMethod']}\n';
    }
    
    out += '\n--- PAYMENTS ---\n';
    for (var p in paysU.docs) {
      var data = p.data();
      DateTime d = (data['date'] as Timestamp).toDate();
      out += '\${d.toString()} | Amount: \${data['amount']} | Method: \${data['method']}\n';
    }
    
    out += '\n--- MANUAL DEBTS ---\n';
    for (var d in manualDebtsU.docs) {
      var data = d.data();
      DateTime dt = (data['date'] as Timestamp).toDate();
      out += '\${dt.toString()} | Amount: \${data['amount']} | Desc: \${data['description']}\n';
    }
  }

  // Find Ezequiel
  final clientsEze = await FirebaseFirestore.instance.collection('clients')
      .where('name', isGreaterThanOrEqualTo: 'Ezequiel')
      .where('name', isLessThan: 'Ezequiem')
      .get();
      
  if (clientsEze.docs.isNotEmpty) {
    String eId = clientsEze.docs.first.id;
    final eData = clientsEze.docs.first.data();
    
    final salesE = await FirebaseFirestore.instance.collection('sales').where('clientId', isEqualTo: eId).get();
    final paysE = await FirebaseFirestore.instance.collection('payments').where('clientId', isEqualTo: eId).get();
    
    out += '\n====================\nEzequiel (ID: \$eId)\n';
    out += 'Current Balance: \${eData['balance']}\n\n';
    
    out += '--- SALES ---\n';
    for (var s in salesE.docs) {
      var data = s.data();
      DateTime d = (data['date'] as Timestamp).toDate();
      out += '\${d.toString()} | Total: \${data['total']} | Paid: \${data['paidAmount']} | Method: \${data['paymentMethod']}\n';
    }
    
    out += '\n--- PAYMENTS ---\n';
    for (var p in paysE.docs) {
      var data = p.data();
      DateTime d = (data['date'] as Timestamp).toDate();
      out += '\${d.toString()} | Amount: \${data['amount']} | Method: \${data['method']}\n';
    }
  }

  f.writeAsStringSync(out);
  print('Dump complete');
  exit(0);
}
