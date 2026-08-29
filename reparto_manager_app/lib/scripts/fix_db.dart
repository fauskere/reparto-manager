import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> runFix() async {
  final db = FirebaseFirestore.instance;
  
  final clientsQs = await db.collection('clients').get();
  for (var cDoc in clientsQs.docs) {
    if (cDoc.data()['name'].toString().toLowerCase() == 'anita' || cDoc.data()['name'].toString().toLowerCase() == 'el colo') {
      final salesQs = await db.collection('sales').where('clientId', isEqualTo: cDoc.id).orderBy('date', descending: false).get();
      double currentRunningBalance = 0;
      for (var saleDoc in salesQs.docs) {
        final total = (saleDoc.data()['total'] ?? 0.0).toDouble();
        final paid = (saleDoc.data()['paidAmount'] ?? 0.0).toDouble();
        
        final realPrevBal = currentRunningBalance;
        final realRemaining = realPrevBal + total - paid;
        
        await db.collection('sales').doc(saleDoc.id).update({
          'previousBalance': realPrevBal,
          'remainingBalance': realRemaining
        });
        
        currentRunningBalance = realRemaining;
        print("Ticket ${saleDoc.id} de ${cDoc.data()['name']}: PrevBal ajustado a \$${realPrevBal}, Total \$${total}, Pago \$${paid}, Remaining \$${realRemaining}");
      }
    }
  }

  final lapazQs = await db.collection('clients').where('name', isEqualTo: 'La Paz Central').get();
  if (lapazQs.docs.isNotEmpty) {
    final lapazDoc = lapazQs.docs.first;
    final salesQs = await db.collection('sales').where('clientId', isEqualTo: lapazDoc.id).orderBy('date', descending: true).get();
    
    double correctBal = 0;
    if (salesQs.docs.isNotEmpty) {
      final latest = salesQs.docs.first;
      correctBal = (latest.data()['total'] ?? 0.0).toDouble() - (latest.data()['paidAmount'] ?? 0.0).toDouble();
    }
    
    await db.collection('clients').doc(lapazDoc.id).update({'balance': correctBal});
    print("La Paz Central ajustada a \$${correctBal}");
  }
}
