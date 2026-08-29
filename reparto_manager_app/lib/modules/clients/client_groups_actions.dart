import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_group.dart';
import '../../core/tenant_db.dart';

class ClientGroupsActions extends ChangeNotifier {
  static final ClientGroupsActions _instance = ClientGroupsActions._internal();
  factory ClientGroupsActions() => _instance;

  final List<ClientGroup> _groups = [];

  ClientGroupsActions._internal() {
    _listenToGroups();
  }

  List<ClientGroup> get groups => _groups;

  void _listenToGroups() {
    TenantDB.collection('clientGroups').orderBy('name').snapshots().listen((snapshot) {
      _groups.clear();
      for (var doc in snapshot.docs) {
        _groups.add(ClientGroup.fromMap(doc.data(), doc.id));
      }
      notifyListeners();
    });
  }

  Future<void> createGroup(String name, List<String> clientIds) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final docRef = await TenantDB.collection('clientGroups').add({
      'name': name,
      'clientIds': clientIds,
      'createdAt': Timestamp.now(),
      'lastInvoicedDate': Timestamp.fromDate(startOfDay),
      'status': 'open',
    });

    final batch = FirebaseFirestore.instance.batch();
    for (var id in clientIds) {
      batch.update(TenantDB.collection('clients').doc(id), {'groupId': docRef.id});
    }
    await batch.commit();
  }

  Future<void> updateGroup(String groupId, String name, List<String> clientIds) async {
    final snap = await TenantDB.collection('clients').where('groupId', isEqualTo: groupId).get();
    final batch = FirebaseFirestore.instance.batch();
    
    for (var doc in snap.docs) {
      if (!clientIds.contains(doc.id)) {
        batch.update(doc.reference, {'groupId': FieldValue.delete()});
      }
    }

    for (var id in clientIds) {
      batch.update(TenantDB.collection('clients').doc(id), {'groupId': groupId});
    }

    batch.update(TenantDB.collection('clientGroups').doc(groupId), {
      'name': name,
      'clientIds': clientIds,
    });

    await batch.commit();
  }

  Future<void> deleteGroup(String groupId) async {
    final snap = await TenantDB.collection('clients').where('groupId', isEqualTo: groupId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'groupId': FieldValue.delete()});
    }
    batch.delete(TenantDB.collection('clientGroups').doc(groupId));
    await batch.commit();
  }

  Future<void> invoiceGroup(String groupId, double totalAmount, List<Map<String, dynamic>> items, Timestamp newLastInvoicedDate, List<String> saleIds) async {
    final now = Timestamp.now();
    
    // 1. Guardar la factura congelada en una subcolección
    await TenantDB.collection('clientGroups').doc(groupId).collection('invoices').add({
      'totalAmount': totalAmount,
      'items': items,
      'saleIds': saleIds,
      'invoicedAt': now,
      'status': 'invoiced', // 'invoiced' o 'paid'
    });

    // 2. Actualizar la fecha del último corte del grupo para iniciar un nuevo período
    await TenantDB.collection('clientGroups').doc(groupId).update({
      'lastInvoicedDate': newLastInvoicedDate,
    });
  }

  Future<void> deleteInvoice(String groupId, String invoiceId) async {
    await TenantDB.collection('clientGroups').doc(groupId).collection('invoices').doc(invoiceId).delete();
  }

  Future<void> payInvoice(String groupId, String invoiceId) async {
    await TenantDB.collection('clientGroups').doc(groupId).collection('invoices').doc(invoiceId).update({
      'status': 'paid',
      'paidAt': Timestamp.now(),
    });
  }

  Future<void> updateInvoicePaidDate(String groupId, String invoiceId, DateTime newDate) async {
    final batch = FirebaseFirestore.instance.batch();
    final invoiceRef = TenantDB.collection('clientGroups').doc(groupId).collection('invoices').doc(invoiceId);
    batch.update(invoiceRef, {
      'paidAt': Timestamp.fromDate(newDate),
    });

    final paymentsQuery = await TenantDB.collection('payments').where('invoiceId', isEqualTo: invoiceId).get();
    for (var doc in paymentsQuery.docs) {
      batch.update(doc.reference, {
        'date': Timestamp.fromDate(newDate),
      });
    }

    await batch.commit();
  }
}
