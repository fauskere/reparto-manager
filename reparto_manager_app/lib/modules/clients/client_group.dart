import 'package:cloud_firestore/cloud_firestore.dart';

class ClientGroup {
  final String id;
  final String name;
  final List<String> clientIds;
  final DateTime createdAt;
  final DateTime lastInvoicedDate;
  final String status; // 'open', 'invoiced', 'paid'

  ClientGroup({
    required this.id,
    required this.name,
    required this.clientIds,
    required this.createdAt,
    required this.lastInvoicedDate,
    this.status = 'open',
  });

  factory ClientGroup.fromMap(Map<String, dynamic> data, String documentId) {
    List<String> parsedIds = [];
    if (data['clientIds'] != null) {
      parsedIds = List<String>.from(data['clientIds']);
    }
    
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    DateTime parsedInvoicedDate = parsedDate;
    if (data['lastInvoicedDate'] != null) {
      if (data['lastInvoicedDate'] is Timestamp) {
        parsedInvoicedDate = (data['lastInvoicedDate'] as Timestamp).toDate();
      } else if (data['lastInvoicedDate'] is String) {
        parsedInvoicedDate = DateTime.tryParse(data['lastInvoicedDate']) ?? parsedDate;
      }
    }

    return ClientGroup(
      id: documentId,
      name: data['name'] ?? '',
      clientIds: parsedIds,
      createdAt: parsedDate,
      lastInvoicedDate: parsedInvoicedDate,
      status: data['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'clientIds': clientIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastInvoicedDate': Timestamp.fromDate(lastInvoicedDate),
      'status': status,
    };
  }
}
