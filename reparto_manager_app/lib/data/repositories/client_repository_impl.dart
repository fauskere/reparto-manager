// lib/data/repositories/client_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/money.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/i_client_repository.dart';
import '../database/app_database.dart';
import '../models/client_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IClientRepository] basada en SQLite.
class ClientRepositoryImpl implements IClientRepository {
  final AppDatabase _appDatabase;

  ClientRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(
    String tenantId,
    String clientId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'clients',
        where: 'tenantId = ? AND id = ?',
        whereArgs: [tenantId, clientId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Result.fail(const DatabaseFailure('Cliente no encontrado'));
      }
      return Result.ok(ClientModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener cliente', e));
    }
  }

  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(
    String tenantId, {
    String? zoneId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final String whereClause;
      final List<dynamic> whereArgs;

      if (zoneId != null && zoneId.trim().isNotEmpty) {
        whereClause = 'tenantId = ? AND zoneId = ?';
        whereArgs = [tenantId, zoneId.trim()];
      } else {
        whereClause = 'tenantId = ?';
        whereArgs = [tenantId];
      }

      final rows = await db.query(
        'clients',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => ClientModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar clientes', e));
    }
  }

  @override
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(
    String tenantId,
    String query, {
    int limit = 20,
  }) async {
    try {
      final db = await _appDatabase.database;
      final cleanQuery = '%${query.trim()}%';
      final rows = await db.query(
        'clients',
        where: 'tenantId = ? AND (name LIKE ? OR nickname LIKE ?)',
        whereArgs: [tenantId, cleanQuery, cleanQuery],
        orderBy: 'name ASC',
        limit: limit,
      );

      final list = rows.map((r) => ClientModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al buscar clientes', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity client) async {
    try {
      final db = await _appDatabase.database;
      final model = ClientModel.fromEntity(client);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('clients', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: client.tenantId,
          collectionName: 'clients',
          documentId: client.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar cliente', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteClient(
    String tenantId,
    String clientId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.delete(
          'clients',
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, clientId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'clients',
          documentId: clientId,
          operation: 'delete',
          payload: {'id': clientId, 'tenantId': tenantId},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al eliminar cliente', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(
    String tenantId,
    String clientId,
    VisitStatus status,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'clients',
          {'visitStatus': status.name},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, clientId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'clients',
          documentId: clientId,
          operation: 'update',
          payload: {'visitStatus': status.name},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al actualizar estado de visita', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(
    String tenantId,
    String zoneId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'clients',
          {'visitStatus': VisitStatus.notVisited.name},
          where: 'tenantId = ? AND zoneId = ?',
          whereArgs: [tenantId, zoneId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'clients',
          documentId: 'zone_$zoneId',
          operation: 'update',
          payload: {'resetZoneId': zoneId, 'visitStatus': VisitStatus.notVisited.name},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al resetear visitas de zona', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> updateClientCustomPrices(
    String tenantId,
    String clientId,
    Map<String, Money> customPrices,
  ) async {
    try {
      final db = await _appDatabase.database;
      final pricesMap = <String, int>{};
      customPrices.forEach((key, money) {
        pricesMap[key] = money.cents;
      });
      final jsonStr = pricesMap.isNotEmpty ? jsonEncode(pricesMap) : null;

      await db.transaction((txn) async {
        await txn.update(
          'clients',
          {'customPricesJson': jsonStr},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, clientId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'clients',
          documentId: clientId,
          operation: 'update',
          payload: {'customPricesJson': jsonStr},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al actualizar precios de cliente', e));
    }
  }
}
