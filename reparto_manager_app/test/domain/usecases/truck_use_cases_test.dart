// test/domain/usecases/truck_use_cases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_truck_repository.dart';
import 'package:reparto_manager_app/domain/usecases/load_truck_stock_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/register_damaged_stock_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/unload_truck_stock_use_case.dart';

class FakeTruckRepository implements ITruckRepository {
  TruckLoadEntity? currentLoad;

  @override
  Future<Result<TruckLoadEntity, DomainFailure>> getTodayTruckLoad(
    String t,
    String tr,
    DateTime d,
  ) async {
    final load = currentLoad ?? TruckLoadEntity(truckId: tr, tenantId: t, date: d);
    return Result.ok(load);
  }

  @override
  Future<Result<void, DomainFailure>> saveTruckLoad(TruckLoadEntity truckLoad) async {
    currentLoad = truckLoad;
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> applyStockDelta(
    String t,
    String tr,
    Map<String, int> deltas,
  ) async {
    final load = currentLoad ?? TruckLoadEntity(truckId: tr, tenantId: t, date: DateTime.now());
    final newInv = Map<String, int>.from(load.inventory);
    for (final e in deltas.entries) {
      newInv[e.key] = (newInv[e.key] ?? 0) + e.value;
    }
    currentLoad = load.copyWith(inventory: newInv);
    return Result.ok(null);
  }
}

void main() {
  group('Casos de Uso: Gestión de Stock en Camioneta', () {
    const tenantId = 'tenant_central';
    const truckId = 'truck_01';
    final today = DateTime.utc(2026, 8, 30);

    test('LoadTruckStockUseCase suma existencias a la carga útil', () async {
      final repo = FakeTruckRepository();
      final useCase = LoadTruckStockUseCase(repo);

      final result = await useCase.execute(
        tenantId: tenantId,
        truckId: truckId,
        loadDeltas: {'prod_alfa|triple': 50, 'prod_coca|1.5L': 24},
      );

      expect(result.isSuccess, isTrue);
      expect(repo.currentLoad!.getStock('prod_alfa|triple'), equals(50));
      expect(repo.currentLoad!.getStock('prod_coca|1.5L'), equals(24));
    });

    test('LoadTruckStockUseCase rechaza cantidades no positivas', () async {
      final repo = FakeTruckRepository();
      final useCase = LoadTruckStockUseCase(repo);

      final result = await useCase.execute(
        tenantId: tenantId,
        truckId: truckId,
        loadDeltas: {'prod_alfa|triple': 0},
      );

      expect(result.isFailure, isTrue);
    });

    test('UnloadTruckStockUseCase resta cantidades sobrantes devolviéndolas al depósito', () async {
      final repo = FakeTruckRepository();
      repo.currentLoad = TruckLoadEntity(
        truckId: truckId,
        tenantId: tenantId,
        date: today,
        inventory: {'prod_alfa|triple': 30},
      );

      final useCase = UnloadTruckStockUseCase(repo);
      final result = await useCase.execute(
        tenantId: tenantId,
        truckId: truckId,
        unloadDeltas: {'prod_alfa|triple': 10},
      );

      expect(result.isSuccess, isTrue);
      expect(repo.currentLoad!.getStock('prod_alfa|triple'), equals(20));
    });

    test('RegisterDamagedStockUseCase pasa mercadería dañada a damagedItems', () async {
      final repo = FakeTruckRepository();
      repo.currentLoad = TruckLoadEntity(
        truckId: truckId,
        tenantId: tenantId,
        date: today,
        inventory: {'prod_alfa|triple': 20},
      );

      final useCase = RegisterDamagedStockUseCase(repo);
      final result = await useCase.execute(
        tenantId: tenantId,
        truckId: truckId,
        dateUtc: today,
        variantKey: 'prod_alfa|triple',
        quantity: 3,
      );

      expect(result.isSuccess, isTrue);
      expect(repo.currentLoad!.getStock('prod_alfa|triple'), equals(17));
      expect(repo.currentLoad!.getDamaged('prod_alfa|triple'), equals(3));
    });
  });
}
