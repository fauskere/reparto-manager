import 'package:cloud_firestore/cloud_firestore.dart';

class ManualDebt {
  final String id;
  final String clientId;
  final DateTime date;
  final double amount;
  final String description;
  final bool? isAdjustment;
  final String? note;

  ManualDebt({
    required this.id,
    required this.clientId,
    required this.date,
    required this.amount,
    required this.description,
    this.isAdjustment,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'description': description,
      if (isAdjustment != null) 'isAdjustment': isAdjustment,
      if (note != null) 'note': note,
    };
  }

  factory ManualDebt.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      if (map['date'] is Timestamp) {
        parsedDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
      } else if (map['date'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(map['date']);
      }
    }

    return ManualDebt(
      id: id,
      clientId: map['clientId'] ?? '',
      date: parsedDate,
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? 'Deuda anterior',
      isAdjustment: map['isAdjustment'],
      note: map['note'],
    );
  }
}
