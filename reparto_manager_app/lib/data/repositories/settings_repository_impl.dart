// lib/data/repositories/settings_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../database/app_database.dart';

/// Implementación local de [ISettingsRepository] basada en SQLite.
class SettingsRepositoryImpl implements ISettingsRepository {
  final AppDatabase _appDatabase;

  SettingsRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<String?, DomainFailure>> getSetting(
    String tenantId,
    String key,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'app_settings',
        where: 'tenantId = ? AND key = ?',
        whereArgs: [tenantId, key],
        limit: 1,
      );

      if (rows.isEmpty) {
        return Result.ok(null);
      }

      return Result.ok(rows.first['value'] as String?);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener configuración', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> setSetting(
    String tenantId,
    String key,
    String value,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_settings',
        {
          'tenantId': tenantId,
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar configuración', e));
    }
  }

  @override
  Future<Result<Map<String, String>, DomainFailure>> getAllSettings(
    String tenantId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'app_settings',
        where: 'tenantId = ?',
        whereArgs: [tenantId],
      );

      final Map<String, String> result = {};
      for (final r in rows) {
        final k = r['key'] as String;
        final v = (r['value'] as String?) ?? '';
        result[k] = v;
      }
      return Result.ok(result);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener todas las configuraciones', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteSetting(
    String tenantId,
    String key,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        'app_settings',
        where: 'tenantId = ? AND key = ?',
        whereArgs: [tenantId, key],
      );
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al eliminar configuración', e));
    }
  }
}
