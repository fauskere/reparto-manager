import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String clientId;
  final DateTime date;
  final double amount;
  final String method; // 'Efectivo', 'Transferencia', 'Mixto'
  final double? cashAmount;
  final double? transferAmount;
  final double? previousBalance;
  final double? remainingBalance;
  final String? type;
  final bool? isAdjustment;
  final String? note;

  Payment({
    required this.id,
    required this.clientId,
    required this.date,
    required this.amount,
    required this.method,
    this.cashAmount,
    this.transferAmount,
    this.previousBalance,
    this.remainingBalance,
    this.type,
    this.isAdjustment,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'method': method,
      'cashAmount': cashAmount,
      'transferAmount': transferAmount,
      'previousBalance': previousBalance,
      'remainingBalance': remainingBalance,
      'type': type,
      if (isAdjustment != null) 'isAdjustment': isAdjustment,
      if (note != null) 'note': note,
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
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

    return Payment(
      id: id,
      clientId: map['clientId'] ?? '',
      date: parsedDate,
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? 'Efectivo',
      cashAmount: map['cashAmount'] != null ? (map['cashAmount'] as num).toDouble() : null,
      transferAmount: map['transferAmount'] != null ? (map['transferAmount'] as num).toDouble() : null,
      previousBalance: map['previousBalance'] != null ? (map['previousBalance'] as num).toDouble() : null,
      remainingBalance: map['remainingBalance'] != null ? (map['remainingBalance'] as num).toDouble() : null,
      type: map['type'],
      isAdjustment: map['isAdjustment'],
      note: map['note'],
    );
  }
}
