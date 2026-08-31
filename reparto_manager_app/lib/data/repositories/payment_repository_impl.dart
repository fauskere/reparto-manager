// lib/data/repositories/payment_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../database/app_database.dart';
import '../models/payment_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IPaymentRepository] basada en SQLite.
class PaymentRepositoryImpl implements IPaymentRepository {
  final AppDatabase _appDatabase;

  PaymentRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<void, DomainFailure>> savePayment(PaymentEntity payment) async {
    try {
      final db = await _appDatabase.database;
      final model = PaymentModel.fromEntity(payment);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('payments', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: payment.tenantId,
          collectionName: 'payments',
          documentId: payment.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar cobranza', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> cancelPayment(
    String tenantId,
    String paymentId,
    String reason,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'payments',
          {'isCancelled': 1, 'notes': 'Anulado: $reason'},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, paymentId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'payments',
          documentId: paymentId,
          operation: 'update',
          payload: {'isCancelled': 1, 'cancellationReason': reason},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al anular cobranza', e));
    }
  }

  @override
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByClient(
    String tenantId,
    String clientId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'payments',
        where: 'tenantId = ? AND clientId = ?',
        whereArgs: [tenantId, clientId],
        orderBy: 'dateUtc DESC, receiptNumber DESC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => PaymentModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener pagos por cliente', e));
    }
  }

  @override
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByDateRange(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'payments',
        where: 'tenantId = ? AND dateUtc >= ? AND dateUtc <= ?',
        whereArgs: [tenantId, startUtc.toUtc().toIso8601String(), endUtc.toUtc().toIso8601String()],
        orderBy: 'dateUtc DESC, receiptNumber DESC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => PaymentModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar pagos por fecha', e));
    }
  }

  @override
  Future<Result<int, DomainFailure>> getNextReceiptNumber(String tenantId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COALESCE(MAX(receiptNumber), 0) + 1 AS nextNumber FROM payments WHERE tenantId = ?',
        [tenantId],
      );
      final nextNum = (rows.first['nextNumber'] as num).toInt();
      return Result.ok(nextNum);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener próximo número de recibo', e));
    }
  }
}
