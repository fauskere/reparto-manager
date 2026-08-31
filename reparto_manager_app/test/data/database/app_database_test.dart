// test/data/database/app_database_test.dart
// Pruebas Unitarias - Capa de Infraestructura SQLite V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase - Infraestructura SQLite Multiplataforma y Multi-Tenant', () {
    late Database db;
    late AppDatabase appDb;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. Debe crear exactamente las 15 tablas del esquema V2', () async {
      final tablesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%';",
      );

      final createdTables = tablesResult.map((row) => row['name'] as String).toSet();
      final expectedTables = {
        'clients',
        'products',
        'price_history',
        'sales',
        'payments',
        'truck_loads',
        'ledger_entries',
        'ledger_snapshots',
        'cash_summaries',
        'zones',
        'client_groups',
        'group_invoices',
        'promotions',
        'app_settings',
        'sync_queue',
      };

      for (final table in expectedTables) {
        expect(createdTables.contains(table), isTrue, reason: 'Tabla faltante: $table');
      }
      expect(createdTables.length, equals(15));
    });

    test('2. Debe crear los 8 índices compuestos de alto rendimiento', () async {
      final indexesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%';",
      );

      final createdIndexes = indexesResult.map((row) => row['name'] as String).toSet();
      final expectedIndexes = {
        'idx_clients_tenant_zone',
        'idx_clients_tenant_name',
        'idx_sales_tenant_date',
        'idx_sales_tenant_client',
        'idx_payments_tenant_date',
        'idx_payments_tenant_client',
        'idx_ledger_tenant_client_date',
        'idx_sync_tenant_status',
      };

      for (final index in expectedIndexes) {
        expect(createdIndexes.contains(index), isTrue, reason: 'Índice faltante: $index');
      }
      expect(createdIndexes.length, equals(8));
    });

    test('3. Particionado Multi-Tenant: consultas estrictamente aisladas por tenantId', () async {
      await db.insert('clients', {
        'id': 'cli_1',
        'tenantId': 'tenant_marcos',
        'name': 'Kiosco Central',
        'nickname': 'El Central',
        'city': 'Rosario',
        'clientType': 'normal',
        'visitStatus': 'notVisited',
        'balanceCents': 250000,
        'debtLimitCents': 500000,
        'isStore': 1,
        'isOpenContinuous': 0,
        'isActive': 1,
      });

      final resultTenantB = await db.query(
        'clients',
        where: 'tenantId = ?',
        whereArgs: ['tenant_belen'],
      );
      expect(resultTenantB, isEmpty);

      final resultTenantA = await db.query(
        'clients',
        where: 'tenantId = ?',
        whereArgs: ['tenant_marcos'],
      );
      expect(resultTenantA.length, equals(1));
      expect(resultTenantA.first['name'], equals('Kiosco Central'));
      expect(resultTenantA.first['balanceCents'], equals(250000));
    });

    test('4. Clave compuesta (tenantId, id): permite mismo ID en distintos tenants', () async {
      await db.insert('products', {
        'id': 'prod_alfa',
        'tenantId': 'tenant_marcos',
        'name': 'Alfajor Chocolate',
        'category': 'Golosinas',
        'variantsJson': '[]',
        'isActive': 1,
      });

      await db.insert('products', {
        'id': 'prod_alfa',
        'tenantId': 'tenant_belen',
        'name': 'Alfajor Nieve',
        'category': 'Golosinas',
        'variantsJson': '[]',
        'isActive': 1,
      });

      final resA = await db.rawQuery('SELECT COUNT(*) FROM products WHERE tenantId = ?', ['tenant_marcos']);
      final countA = (resA.first.values.first as num).toInt();
      final resB = await db.rawQuery('SELECT COUNT(*) FROM products WHERE tenantId = ?', ['tenant_belen']);
      final countB = (resB.first.values.first as num).toInt();

      expect(countA, equals(1));
      expect(countB, equals(1));

      expect(
        () async => await db.insert('products', {
          'id': 'prod_alfa',
          'tenantId': 'tenant_marcos',
          'name': 'Duplicado Prohibido',
          'category': 'Golosinas',
          'variantsJson': '[]',
          'isActive': 1,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('5. Sync Queue: inserción de eventos offline y consulta por estado e índice', () async {
      await db.insert('sync_queue', {
        'id': 'sync_1',
        'tenantId': 'tenant_marcos',
        'collectionName': 'sales',
        'documentId': 'sale_101',
        'operation': 'create',
        'payloadJson': '{"totalCents": 15000}',
        'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
        'status': 'pending',
      });

      final pendingRows = await db.query(
        'sync_queue',
        where: 'tenantId = ? AND status = ?',
        whereArgs: ['tenant_marcos', 'pending'],
      );

      expect(pendingRows.length, equals(1));
      expect(pendingRows.first['documentId'], equals('sale_101'));
      expect(pendingRows.first['operation'], equals('create'));
    });
  });
}
