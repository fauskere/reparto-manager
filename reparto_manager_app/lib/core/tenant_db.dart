import 'package:cloud_firestore/cloud_firestore.dart';

class TenantDB {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get activeTenantId => 'main';

  /// Retorna la referencia a la colección de producción directa (/clients, /sales, /products, etc.)
  static CollectionReference<Map<String, dynamic>> collection(String collectionName) {
    return _db.collection(collectionName);
  }

  /// Helper para obtener un documento específico
  static DocumentReference<Map<String, dynamic>> doc(String collectionName, String docId) {
    return collection(collectionName).doc(docId);
  }
}
