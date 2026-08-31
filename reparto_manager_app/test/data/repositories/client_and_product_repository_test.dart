// test/data/repositories/client_and_product_repository_test.dart
// Pruebas Unitarias - ClientRepositoryImpl y ProductRepositoryImpl
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/repositories/client_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/product_repository_impl.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/product_entity.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ClientRepositoryImpl & ProductRepositoryImpl - SQLite Multi-Tenant', () {
    late AppDatabase appDb;
    late Database db;
    late ClientRepositoryImpl clientRepo;
    late ProductRepositoryImpl productRepo;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      clientRepo = ClientRepositoryImpl(appDb);
      productRepo = ProductRepositoryImpl(appDb);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. ClientRepositoryImpl: CRUD, búsqueda LIKE, precios personalizados y sync_queue', () async {
      final client = ClientEntity(
        id: 'cli_1',
        tenantId: 'tenant_marcos',
        name: 'Kiosco Belén',
        nickname: 'Belén',
        zoneId: 'zona_norte',
        city: 'Santa Fe',
        balance: Money.fromCents(50000),
        debtLimit: Money.fromCents(200000),
      );

      final saveResult = await clientRepo.saveClient(client);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await clientRepo.getClientById('tenant_marcos', 'cli_1');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.valueOrNull?.name, equals('Kiosco Belén'));

      final searchResult = await clientRepo.searchClients('tenant_marcos', 'Bel');
      expect(searchResult.isSuccess, isTrue);
      expect(searchResult.valueOrNull?.length, equals(1));

      await clientRepo.updateClientCustomPrices('tenant_marcos', 'cli_1', {
        'prod_1|grande': Money.fromCents(120000),
      });
      final updatedClient = (await clientRepo.getClientById('tenant_marcos', 'cli_1')).valueOrNull!;
      expect(updatedClient.customPrices['prod_1|grande']?.cents, equals(120000));

      final syncRows = await db.query('sync_queue', where: 'tenantId = ?', whereArgs: ['tenant_marcos']);
      expect(syncRows.isNotEmpty, isTrue);
      expect(syncRows.any((r) => r['collectionName'] == 'clients'), isTrue);
    });

    test('2. ClientRepositoryImpl: resetVisitStatusForZone actualiza masivamente', () async {
      final c1 = ClientEntity(
        id: 'c1',
        tenantId: 't1',
        name: 'Cliente 1',
        zoneId: 'z_sur',
        visitStatus: VisitStatus.visited,
      );
      final c2 = ClientEntity(
        id: 'c2',
        tenantId: 't1',
        name: 'Cliente 2',
        zoneId: 'z_sur',
        visitStatus: VisitStatus.pending,
      );
      await clientRepo.saveClient(c1);
      await clientRepo.saveClient(c2);

      final resetResult = await clientRepo.resetVisitStatusForZone('t1', 'z_sur');
      expect(resetResult.isSuccess, isTrue);

      final list = (await clientRepo.getClients('t1', zoneId: 'z_sur')).valueOrNull!;
      for (final c in list) {
        expect(c.visitStatus, equals(VisitStatus.notVisited));
      }
    });

    test('3. ProductRepositoryImpl: catálogo, búsqueda, código de barras y categorías', () async {
      final prod = ProductEntity(
        id: 'p1',
        tenantId: 't1',
        name: 'Alfajor Triple',
        category: 'Golosinas',
        barcode: '779123456789',
        variants: [
          ProductVariant(
            variantName: 'Chocolate',
            productId: 'p1',
            basePrice: Money.fromCents(150000),
            costPrice: Money.fromCents(80000),
          ),
        ],
      );

      await productRepo.saveProduct(prod);

      final byBarcode = await productRepo.getProductByBarcode('t1', '779123456789');
      expect(byBarcode.isSuccess, isTrue);
      expect(byBarcode.valueOrNull?.name, equals('Alfajor Triple'));

      final cats = (await productRepo.getCategories('t1')).valueOrNull!;
      expect(cats, contains('Golosinas'));

      final search = (await productRepo.searchProducts('t1', 'Triple')).valueOrNull!;
      expect(search.length, equals(1));
    });

    test('4. ProductRepositoryImpl: auditoría automática de aumentos en price_history', () async {
      final initialProd = ProductEntity(
        id: 'p1',
        tenantId: 't1',
        name: 'Alfajor Triple',
        category: 'Golosinas',
        variants: [
          ProductVariant(
            variantName: 'Chocolate',
            productId: 'p1',
            basePrice: Money.fromCents(100000),
            costPrice: Money.fromCents(60000),
          ),
        ],
      );
      await productRepo.saveProduct(initialProd);

      final updatedProd = ProductEntity(
        id: 'p1',
        tenantId: 't1',
        name: 'Alfajor Triple',
        category: 'Golosinas',
        variants: [
          ProductVariant(
            variantName: 'Chocolate',
            productId: 'p1',
            basePrice: Money.fromCents(125000),
            costPrice: Money.fromCents(75000),
          ),
        ],
      );
      await productRepo.saveProduct(updatedProd);

      final historyResult = await productRepo.getPriceHistory('t1', 'p1');
      expect(historyResult.isSuccess, isTrue);
      final history = historyResult.valueOrNull!;
      expect(history.length, equals(1));
      expect(history.first['oldPriceCents'], equals(100000));
      expect(history.first['newPriceCents'], equals(125000));
    });

    test('5. Aislamiento Multi-Tenant: tenant A no accede a datos de tenant B', () async {
      final cA = ClientEntity(id: 'c_shared', tenantId: 'tenant_A', name: 'Cliente A');
      final cB = ClientEntity(id: 'c_shared', tenantId: 'tenant_B', name: 'Cliente B');
      await clientRepo.saveClient(cA);
      await clientRepo.saveClient(cB);

      final fetchedA = (await clientRepo.getClientById('tenant_A', 'c_shared')).valueOrNull!;
      final fetchedB = (await clientRepo.getClientById('tenant_B', 'c_shared')).valueOrNull!;
      expect(fetchedA.name, equals('Cliente A'));
      expect(fetchedB.name, equals('Cliente B'));

      final listA = (await clientRepo.getClients('tenant_A')).valueOrNull!;
      expect(listA.length, equals(1));
      expect(listA.first.tenantId, equals('tenant_A'));
    });
  });
}
