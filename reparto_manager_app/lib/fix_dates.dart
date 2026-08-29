import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  final groups = await db.collection('clientGroups').get();
  
  for (var doc in groups.docs) {
    final data = doc.data();
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final lastInvoicedDate = (data['lastInvoicedDate'] as Timestamp).toDate();
    
    // Si lastInvoicedDate es igual a createdAt, significa que nunca fue facturado
    if (createdAt.difference(lastInvoicedDate).inSeconds.abs() < 60) {
      final startOfDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      await doc.reference.update({
        'lastInvoicedDate': Timestamp.fromDate(startOfDay)
      });
      print("Updated group ${data['name']} to start of day: $startOfDay");
    }
  }
  print("Done!");
}
