// lib/data/sync/cloud_gateway.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sync_queue_model.dart';

/// Contrato abstracto para operaciones en la nube (Firestore / Network).
abstract class ICloudGateway {
  /// Envía un lote de operaciones pendientes a Firestore.
  Future<void> pushBatch(String tenantId, List<SyncQueueModel> items);

  /// Descarga documentos de una colección filtrados por fecha del servidor.
  Future<List<Map<String, dynamic>>> pullCollection(
    String tenantId,
    String collectionName, {
    DateTime? sinceUtc,
  });

  /// Actualiza la marca de latido en tiempo real en la nube.
  Future<void> updateHeartbeat(String tenantId);

  /// Resetea los sockets de red forzando reconexión limpia.
  Future<void> resetNetwork();

  /// Escucha el latido del tenant para sincronizaciones reactivas inmediatas.
  Stream<DateTime?> listenHeartbeat(String tenantId);
}

/// Implementación de producción con FirebaseFirestore para aislamiento multi-tenant.
class FirestoreCloudGateway implements ICloudGateway {
  final FirebaseFirestore _firestore;
  static const Duration timeoutDuration = Duration(seconds: 8);

  FirestoreCloudGateway([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> pushBatch(String tenantId, List<SyncQueueModel> items) async {
    if (items.isEmpty) return;
    final batch = _firestore.batch();

    for (final item in items) {
      final docRef = _firestore
          .collection('v2_tenants')
          .doc(tenantId)
          .collection(item.collectionName)
          .doc(item.documentId);

      if (item.operation == 'delete') {
        batch.set(
          docRef,
          {
            'isDeleted': true,
            'deletedAtUtc': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        final payload = Map<String, dynamic>.from(item.payload);
        payload['updatedAtUtc'] = FieldValue.serverTimestamp();
        payload['isDeleted'] = false;
        batch.set(docRef, payload, SetOptions(merge: true));
      }
    }

    await batch.commit().timeout(timeoutDuration);
  }

  @override
  Future<List<Map<String, dynamic>>> pullCollection(
    String tenantId,
    String collectionName, {
    DateTime? sinceUtc,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('v2_tenants')
        .doc(tenantId)
        .collection(collectionName);

    if (sinceUtc != null) {
      query = query.where('updatedAtUtc', isGreaterThan: Timestamp.fromDate(sinceUtc));
    }

    final snapshot = await query.get(const GetOptions(source: Source.server)).timeout(timeoutDuration);

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Future<void> updateHeartbeat(String tenantId) async {
    try {
      await _firestore
          .collection('v2_tenants')
          .doc(tenantId)
          .collection('metadata')
          .doc('sync_heartbeat')
          .set({
        'lastPulseUtc': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(timeoutDuration);
    } catch (_) {}
  }

  @override
  Future<void> resetNetwork() async {
    await _firestore.disableNetwork().timeout(const Duration(seconds: 4), onTimeout: () {});
    await _firestore.enableNetwork().timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Stream<DateTime?> listenHeartbeat(String tenantId) {
    return _firestore
        .collection('v2_tenants')
        .doc(tenantId)
        .collection('metadata')
        .doc('sync_heartbeat')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final ts = snap.data()!['lastPulseUtc'] as Timestamp?;
      return ts?.toDate().toUtc();
    });
  }
}
