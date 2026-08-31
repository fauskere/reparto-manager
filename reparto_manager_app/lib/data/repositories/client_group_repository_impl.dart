// lib/data/repositories/client_group_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/money.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/client_group_entity.dart';
import '../../domain/repositories/i_client_group_repository.dart';
import '../database/app_database.dart';
import '../models/client_group_model.dart';
import '../models/group_invoice_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IClientGroupRepository] basada en SQLite.
class ClientGroupRepositoryImpl implements IClientGroupRepository {
  final AppDatabase _appDatabase;

  ClientGroupRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<List<ClientGroupEntity>, DomainFailure>> getClientGroups(
    String tenantId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'client_groups',
        where: 'tenantId = ?',
        whereArgs: [tenantId],
        orderBy: 'name ASC',
      );

      final list = rows.map((r) => ClientGroupModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar grupos de clientes', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveClientGroup(ClientGroupEntity group) async {
    try {
      final db = await _appDatabase.database;
      final model = ClientGroupModel.fromEntity(group);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('client_groups', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: group.tenantId,
          collectionName: 'client_groups',
          documentId: group.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar grupo de clientes', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteClientGroup(
    String tenantId,
    String groupId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.delete(
          'client_groups',
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, groupId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'client_groups',
          documentId: groupId,
          operation: 'delete',
          payload: {'id': groupId, 'tenantId': tenantId},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al eliminar grupo de clientes', e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getGroupInvoices(
    String tenantId,
    String groupId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'group_invoices',
        where: 'tenantId = ? AND groupId = ?',
        whereArgs: [tenantId, groupId],
        orderBy: 'invoicedAtUtc DESC',
      );
      return Result.ok(rows);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al consultar facturas grupales', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> createGroupInvoice(
    String tenantId,
    String groupId,
    Money totalAmount,
    List<String> saleIds,
  ) async {
    try {
      final db = await _appDatabase.database;
      final invoiceId = 'inv_${groupId}_${DateTime.now().microsecondsSinceEpoch}';
      final model = GroupInvoiceModel.create(
        id: invoiceId,
        tenantId: tenantId,
        groupId: groupId,
        totalAmount: totalAmount,
        invoicedAt: DateTime.now().toUtc(),
        saleIds: saleIds,
        status: 'pending',
      );
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('group_invoices', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'group_invoices',
          documentId: invoiceId,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al crear factura grupal', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> payGroupInvoice(
    String tenantId,
    String groupId,
    String invoiceId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'group_invoices',
          {'status': 'paid'},
          where: 'tenantId = ? AND groupId = ? AND id = ?',
          whereArgs: [tenantId, groupId, invoiceId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'group_invoices',
          documentId: invoiceId,
          operation: 'update',
          payload: {'status': 'paid'},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al pagar factura grupal', e));
    }
  }
}
