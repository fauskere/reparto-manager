// test/data/repositories/operations_repository_test.dart
// Pruebas Unitarias - Truck, Zone, ClientGroup, Promotion y Settings Repositories
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/repositories/client_group_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/promotion_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/settings_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/truck_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/zone_repository_impl.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/client_group_entity.dart';
import 'package:reparto_manager_app/domain/entities/promotion_entity.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';
import 'package:reparto_manager_app/domain/entities/zone_entity.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Operations Repositories (Truck, Zone, Groups, Promos, Settings)', () {
    late AppDatabase appDb;
    late Database db;
    late TruckRepositoryImpl truckRepo;
    late ZoneRepositoryImpl zoneRepo;
    late ClientGroupRepositoryImpl groupRepo;
    late PromotionRepositoryImpl promoRepo;
    late SettingsRepositoryImpl settingsRepo;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      truckRepo = TruckRepositoryImpl(appDb);
      zoneRepo = ZoneRepositoryImpl(appDb);
      groupRepo = ClientGroupRepositoryImpl(appDb);
      promoRepo = PromotionRepositoryImpl(appDb);
      settingsRepo = SettingsRepositoryImpl(appDb);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. TruckRepositoryImpl: carga, deltas y tolerancia de stock negativo', () async {
      final initialLoad = TruckLoadEntity(
        truckId: 'truck_1',
        tenantId: 't_op',
        date: DateTime.utc(2026, 8, 31),
        inventory: {'p1|choc': 10},
        damagedItems: {'p1|choc': 1},
      );
      await truckRepo.saveTruckLoad(initialLoad);

      await truckRepo.applyStockDelta('t_op', 'truck_1', {'p1|choc': -15});
      final updated = (await truckRepo.getTodayTruckLoad('t_op', 'truck_1', DateTime.utc(2026, 8, 31))).valueOrNull!;

      expect(updated.inventory['p1|choc'], equals(-5));
      expect(updated.hasNegativeStock, isTrue);
    });

    test('2. ZoneRepositoryImpl: CRUD de zonas', () async {
      final zone = ZoneEntity(
        id: 'z_centro',
        tenantId: 't_op',
        name: 'Centro Comercial',
        cities: const ['Rosario', 'San Lorenzo'],
      );
      await zoneRepo.saveZone(zone);

      final zones = (await zoneRepo.getZones('t_op')).valueOrNull!;
      expect(zones.length, equals(1));
      expect(zones.first.cities, contains('San Lorenzo'));

      await zoneRepo.deleteZone('t_op', 'z_centro');
      final afterDelete = (await zoneRepo.getZones('t_op')).valueOrNull!;
      expect(afterDelete, isEmpty);
    });

    test('3. ClientGroupRepositoryImpl: grupos y cortes de facturación grupal', () async {
      final group = ClientGroupEntity(
        id: 'grp_cadena',
        tenantId: 't_op',
        name: 'Cadena Don Mario',
        clientIds: const ['c1', 'c2', 'c3'],
      );
      await groupRepo.saveClientGroup(group);

      final groups = (await groupRepo.getClientGroups('t_op')).valueOrNull!;
      expect(groups.first.clientIds.length, equals(3));

      await groupRepo.createGroupInvoice(
        't_op',
        'grp_cadena',
        Money.fromCents(150000),
        ['s1', 's2'],
      );

      final invoices = (await groupRepo.getGroupInvoices('t_op', 'grp_cadena')).valueOrNull!;
      expect(invoices.length, equals(1));
      expect(invoices.first['status'], equals('pending'));

      final invId = invoices.first['id'] as String;
      await groupRepo.payGroupInvoice('t_op', 'grp_cadena', invId);

      final paidInvoices = (await groupRepo.getGroupInvoices('t_op', 'grp_cadena')).valueOrNull!;
      expect(paidInvoices.first['status'], equals('paid'));
    });

    test('4. PromotionRepositoryImpl: promociones comerciales activas', () async {
      final promo = PromotionEntity(
        id: 'promo_combo',
        tenantId: 't_op',
        name: 'Lleva 5 Paga 4',
        requiredItems: const {'p1|choc': 5},
        discountPercentage: 20.0,
      );
      await promoRepo.savePromotion(promo);

      final promos = (await promoRepo.getActivePromotions('t_op')).valueOrNull!;
      expect(promos.length, equals(1));
      expect(promos.first.discountPercentage, equals(20.0));

      await promoRepo.deletePromotion('t_op', 'promo_combo');
      final afterDelete = (await promoRepo.getActivePromotions('t_op')).valueOrNull!;
      expect(afterDelete, isEmpty);
    });

    test('5. SettingsRepositoryImpl: persistencia de configuración del negocio', () async {
      await settingsRepo.setSetting('t_op', 'business_name', 'Reparto María Belén');
      await settingsRepo.setSetting('t_op', 'active_theme', 'reparto_gold');

      final name = (await settingsRepo.getSetting('t_op', 'business_name')).valueOrNull!;
      expect(name, equals('Reparto María Belén'));

      final all = (await settingsRepo.getAllSettings('t_op')).valueOrNull!;
      expect(all['active_theme'], equals('reparto_gold'));

      await settingsRepo.deleteSetting('t_op', 'business_name');
      final deletedResult = await settingsRepo.getSetting('t_op', 'business_name');
      expect(deletedResult.isSuccess, isTrue);
      expect(deletedResult.valueOrNull, isNull);
    });
  });
}
