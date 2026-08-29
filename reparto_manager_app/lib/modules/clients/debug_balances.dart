import 'package:cloud_firestore/cloud_firestore.dart';

class DebugBalances {
  static Future<void> run() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final clientsSnap = await firestore.collection('clients').get();
      
      String? polloId;
      String? marcelaId;
      for (var c in clientsSnap.docs) {
        String name = c.data()['name'].toString().toLowerCase();
        if (name == 'pollo loco') polloId = c.id;
        if (name == 'marcela') marcelaId = c.id;
      }
      
      if (polloId != null) {
         final doc = await firestore.collection('clients').doc(polloId).get();
         print('POLLO LOCO BALANCE: ${doc.data()?['balance']}');
      }
      
      if (marcelaId != null) {
         final doc = await firestore.collection('clients').doc(marcelaId).get();
         print('MARCELA BALANCE: ${doc.data()?['balance']}');
      }
    } catch(e) {
      print(e);
    }
  }
}
