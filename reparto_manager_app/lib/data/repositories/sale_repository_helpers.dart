// lib/data/repositories/sale_repository_helpers.dart
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/money.dart';
import '../../domain/entities/cash_summary_entity.dart';

/// Funciones auxiliares y agregaciones analíticas para [SaleRepositoryImpl].
class SaleRepositoryHelpers {
  SaleRepositoryHelpers._();

  /// Consolida el desglose de cobros en efectivo y transferencias por cliente.
  static Future<List<CashSummaryItem>> buildClientBreakdown(
    Database db,
    String tenantId,
    String startStr,
    String endStr,
  ) async {
    final clientRows = await db.rawQuery('''
      SELECT 
        clientId, 
        clientName, 
        COALESCE(SUM(cashPaidCents), 0) AS totalCash,
        COALESCE(SUM(transferPaidCents), 0) AS totalTransfer
      FROM (
        SELECT clientId, clientName, cashPaidCents, transferPaidCents 
        FROM sales 
        WHERE tenantId = ? AND isCancelled = 0 AND dateUtc >= ? AND dateUtc <= ?
        UNION ALL
        SELECT p.clientId, COALESCE(c.name, 'Cliente') as clientName, p.cashPaidCents, p.transferPaidCents 
        FROM payments p
        LEFT JOIN clients c ON c.tenantId = p.tenantId AND c.id = p.clientId
        WHERE p.tenantId = ? AND p.isCancelled = 0 AND p.dateUtc >= ? AND p.dateUtc <= ?
      )
      GROUP BY clientId, clientName
      ORDER BY clientName ASC
    ''', [tenantId, startStr, endStr, tenantId, startStr, endStr]);

    return clientRows.map((r) => CashSummaryItem(
      clientId: r['clientId'] as String,
      clientName: r['clientName'] as String,
      cash: Money.fromCents((r['totalCash'] as num).toInt()),
      transfer: Money.fromCents((r['totalTransfer'] as num).toInt()),
    )).toList();
  }

  /// Calcula el ranking de los productos más vendidos parseando el JSON embebido.
  static List<Map<String, dynamic>> parseTopProducts(
    List<Map<String, Object?>> rows,
    int limit,
  ) {
    final Map<String, int> productCounts = {};
    final Map<String, String> productNames = {};

    for (final row in rows) {
      final items = jsonDecode(row['itemsJson'] as String) as List<dynamic>;
      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final pid = item['productId'] as String;
        final qty = (item['quantity'] as num).toInt();
        productCounts[pid] = (productCounts[pid] ?? 0) + qty;
        productNames[pid] = item['productName'] as String;
      }
    }

    final sorted = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => {
      'productId': e.key,
      'productName': productNames[e.key] ?? '',
      'totalQuantity': e.value,
    }).toList();
  }
}
