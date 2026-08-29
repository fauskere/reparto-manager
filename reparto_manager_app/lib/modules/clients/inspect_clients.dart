import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectClients {
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('inspect_done_v3') == true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final clientsSnap = await firestore.collection('clients').get();
      
      String? normaId, marcelaId, damianId, marcosId;
      for (var c in clientsSnap.docs) {
        String name = c.data()['name'].toString().toLowerCase();
        if (name == 'norma') normaId = c.id;
        if (name.contains('marcela') && name.contains('villegas')) marcelaId = c.id;
        else if (name == 'marcela') marcelaId = c.id;
        if (name == 'damian') damianId = c.id;
        if (name == 'marcos') marcosId = c.id;
      }
      
      String logData = "";
      
      Future<void> inspect(String name, String? id) async {
        if (id == null) return;
        logData += '\n=== $name ===\n';
        final doc = await firestore.collection('clients').doc(id).get();
        logData += 'CURRENT DB BALANCE: ${doc.data()?['balance']}\n';
        
        final sales = await firestore.collection('sales').where('clientId', isEqualTo: id).get();
        for (var s in sales.docs) {
           logData += 'SALE: id=${s.id} total=${s.data()['total']} paid=${s.data()['paidAmount']} cash=${s.data()['cashAmount']} transfer=${s.data()['transferAmount']} \n';
        }
        final pays = await firestore.collection('payments').where('clientId', isEqualTo: id).get();
        for (var p in pays.docs) {
           logData += 'PAY: id=${p.id} amount=${p.data()['amount']} type=${p.data()['type']}\n';
        }
        final debts = await firestore.collection('manual_debts').where('clientId', isEqualTo: id).get();
        for (var d in debts.docs) {
           logData += 'DEBT: id=${d.id} amount=${d.data()['amount']}\n';
        }
      }

      await inspect('NORMA', normaId);
      await inspect('MARCELA', marcelaId);
      await inspect('DAMIAN', damianId);
      await inspect('MARCOS', marcosId);
      
      await firestore.collection('debug_logs').doc('latest').set({'log': logData, 'timestamp': FieldValue.serverTimestamp()});
      await prefs.setBool('inspect_done_v3', true);
    } catch(e) {
      print(e);
    }
  }
}
