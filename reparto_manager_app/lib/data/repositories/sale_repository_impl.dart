// lib/data/repositories/sale_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/money.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/cash_summary_entity.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../database/app_database.dart';
import '../models/sale_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [ISaleRepository] basada en SQLite.
class SaleRepositoryImpl implements ISaleRepository {
  final AppDatabase _appDatabase;

  SaleRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<SaleEntity, DomainFailure>> getSaleById(
    String tenantId,
    String saleId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'sales',
        where: 'tenantId = ? AND id = ?',
        whereArgs: [tenantId, saleId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Result.fail(const DatabaseFailure('Venta no encontrada'));
      }
      return Result.ok(SaleModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener venta', e));
    }
  }

  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByDateRange(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'sales',
        where: 'tenantId = ? AND dateUtc >= ? AND dateUtc <= ?',
        whereArgs: [tenantId, startUtc.toUtc().toIso8601String(), endUtc.toUtc().toIso8601String()],
        orderBy: 'dateUtc DESC, ticketNumber DESC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => SaleModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar ventas por fecha', e));
    }
  }

  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByClient(
    String tenantId,
    String clientId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'sales',
        where: 'tenantId = ? AND clientId = ?',
        whereArgs: [tenantId, clientId],
        orderBy: 'dateUtc DESC, ticketNumber DESC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => SaleModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar ventas por cliente', e));
    }
  }

  @override
  Future<Result<CashSummaryEntity, DomainFailure>> getCashSummary(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    try {
      final db = await _appDatabase.database;
      final startStr = startUtc.toUtc().toIso8601String();
      final endStr = endUtc.toUtc().toIso8601String();

      final salesRows = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(cashPaidCents), 0) AS salesCash,
          COALESCE(SUM(transferPaidCents), 0) AS salesTransfer,
          COALESCE(SUM(debtGeneratedCents), 0) AS debtGenerated
        FROM sales 
        WHERE tenantId = ? AND isCancelled = 0 AND dateUtc >= ? AND dateUtc <= ?
      ''', [tenantId, startStr, endStr]);

      final paymentsRows = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(cashPaidCents), 0) AS paymentsCash,
          COALESCE(SUM(transferPaidCents), 0) AS paymentsTransfer
        FROM payments 
        WHERE tenantId = ? AND isCancelled = 0 AND dateUtc >= ? AND dateUtc <= ?
      ''', [tenantId, startStr, endStr]);

      final breakdown = await _buildClientBreakdown(db, tenantId, startStr, endStr);

      final sRow = salesRows.first;
      final pRow = paymentsRows.first;

      return Result.ok(
        CashSummaryEntity(
          salesCash: Money.fromCents((sRow['salesCash'] as num).toInt()),
          salesTransfer: Money.fromCents((sRow['salesTransfer'] as num).toInt()),
          paymentsCash: Money.fromCents((pRow['paymentsCash'] as num).toInt()),
          paymentsTransfer: Money.fromCents((pRow['paymentsTransfer'] as num).toInt()),
          debtGenerated: Money.fromCents((sRow['debtGenerated'] as num).toInt()),
          clientBreakdown: breakdown,
        ),
      );
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al calcular arqueo de caja', e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopProducts(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 10,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'sales',
        columns: ['itemsJson'],
        where: 'tenantId = ? AND isCancelled = 0 AND dateUtc >= ? AND dateUtc <= ?',
        whereArgs: [tenantId, startUtc.toUtc().toIso8601String(), endUtc.toUtc().toIso8601String()],
      );

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

      final top = sorted.take(limit).map((e) => {
        'productId': e.key,
        'productName': productNames[e.key] ?? '',
        'totalQuantity': e.value,
      }).toList();

      return Result.ok(top);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener top de productos', e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopClients(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 10,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery('''
        SELECT clientId, clientName, COALESCE(SUM(totalCents), 0) AS totalPurchasedCents
        FROM sales
        WHERE tenantId = ? AND isCancelled = 0 AND dateUtc >= ? AND dateUtc <= ?
        GROUP BY clientId, clientName
        ORDER BY totalPurchasedCents DESC
        LIMIT ?
      ''', [tenantId, startUtc.toUtc().toIso8601String(), endUtc.toUtc().toIso8601String(), limit]);

      final list = rows.map((r) => {
        'clientId': r['clientId'],
        'clientName': r['clientName'],
        'totalPurchasedCents': r['totalPurchasedCents'],
      }).toList();

      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener top de clientes', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveSale(SaleEntity sale) async {
    try {
      final db = await _appDatabase.database;
      final model = SaleModel.fromEntity(sale);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('sales', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: sale.tenantId,
          collectionName: 'sales',
          documentId: sale.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar venta', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> cancelSale(
    String tenantId,
    String saleId,
    String reason,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'sales',
          {'isCancelled': 1},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, saleId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'sales',
          documentId: saleId,
          operation: 'update',
          payload: {'isCancelled': 1, 'cancellationReason': reason},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al anular venta', e));
    }
  }

  @override
  Future<Result<int, DomainFailure>> getNextTicketNumber(String tenantId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COALESCE(MAX(ticketNumber), 0) + 1 AS nextNumber FROM sales WHERE tenantId = ?',
        [tenantId],
      );
      final nextNum = (rows.first['nextNumber'] as num).toInt();
      return Result.ok(nextNum);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener próximo número de ticket', e));
    }
  }

  Future<List<CashSummaryItem>> _buildClientBreakdown(
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
}
