import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixLaPazCentralV6() async {
  final db = FirebaseFirestore.instance;
  
  // Find all La Paz Central
  final qs = await db.collection('clients').where('name', isEqualTo: 'La Paz Central').get();
  if (qs.docs.isEmpty) {
    print("La Paz Central no encontrada");
    return;
  }
  
  String originalId = '';
  
  for (var doc in qs.docs) {
    double balance = (doc.data()['balance'] ?? 0.0).toDouble();
    if (balance == 650600.0) {
      print("Borrando la Paz Central duplicada con ID: ${doc.id}");
      await db.collection('clients').doc(doc.id).delete();
    } else {
      originalId = doc.id;
    }
  }
  
  if (originalId.isEmpty && qs.docs.isNotEmpty) {
      originalId = qs.docs.first.id;
  }
  
  if (originalId.isNotEmpty) {
    // SIN orderBy para evitar error de composite index
    final salesQs = await db.collection('sales').where('clientId', isEqualTo: originalId).get();
    
    double pendingFromLatest = 0.0;
    if (salesQs.docs.isNotEmpty) {
      final docs = salesQs.docs.toList();
      docs.sort((a, b) {
        final dateA = (a.data()['date'] as Timestamp).toDate();
        final dateB = (b.data()['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA); // Descending
      });
      final latestSale = docs.first;
      final total = (latestSale.data()['total'] ?? 0.0).toDouble();
      final paidAmount = (latestSale.data()['paidAmount'] ?? 0.0).toDouble();
      pendingFromLatest = total - paidAmount;
      print("Ultima venta de original el ${latestSale.data()['date'].toDate()}: Total \$${total}, Pagado \$${paidAmount}, Pendiente: \$${pendingFromLatest}");
    }
    
    // Set balance to exactly that
    await db.collection('clients').doc(originalId).update({'balance': pendingFromLatest});
    print("Saldo de La Paz Central original corregido a \$${pendingFromLatest}");
  }
}
