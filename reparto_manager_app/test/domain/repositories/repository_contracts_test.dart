// test/domain/repositories/repository_contracts_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_ledger_repository.dart';

/// Fake en memoria para validar el contrato abstracto ILedgerRepository.
class FakeLedgerRepository implements ILedgerRepository {
  final List<LedgerEntryEntity> entries = [];
  final Map<String, LedgerSnapshot> snapshots = {};

  @override
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity entry) async {
    entries.add(entry);
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> recordEntries(List<LedgerEntryEntity> items) async {
    entries.addAll(items);
    return Result.ok(null);
  }

  @override
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(
    String tenantId,
    String clientId, {
    DateTime? sinceUtc,
    int limit = 50,
    int offset = 0,
  }) async {
    final filtered = entries.where((e) {
      if (e.tenantId != tenantId || e.clientId != clientId) return false;
      if (sinceUtc != null && e.date.isBefore(sinceUtc)) return false;
      return true;
    }).skip(offset).take(limit).toList();

    return Result.ok(filtered);
  }

  @override
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String tenantId) async {
    var total = Money.zero;
    for (final e in entries.where((e) => e.tenantId == tenantId)) {
      total = total + e.balanceImpact;
    }
    return Result.ok(total);
  }

  @override
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(
    String tenantId,
    String clientId,
  ) async {
    final key = '$tenantId|$clientId';
    return Result.ok(snapshots[key]);
  }

  @override
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot snapshot) async {
    final key = '${snapshot.tenantId}|${snapshot.clientId}';
    snapshots[key] = snapshot;
    return Result.ok(null);
  }
}

/// Fake en memoria para validar el contrato abstracto IClientRepository.
class FakeClientRepository implements IClientRepository {
  final Map<String, ClientEntity> clients = {};

  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(
    String tenantId,
    String clientId,
  ) async {
    final key = '$tenantId|$clientId';
    final client = clients[key];
    if (client == null) {
      return Result.fail(const EntityValidationFailure('Cliente no encontrado'));
    }
    return Result.ok(client);
  }

  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(
    String tenantId, {
    String? zoneId,
    int limit = 50,
    int offset = 0,
  }) async {
    final list = clients.values.where((c) {
      if (c.tenantId != tenantId) return false;
      if (zoneId != null && c.zoneId != zoneId) return false;
      return true;
    }).skip(offset).take(limit).toList();

    return Result.ok(list);
  }

  @override
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(
    String tenantId,
    String query, {
    int limit = 20,
  }) async {
    final q = query.toLowerCase();
    final list = clients.values.where((c) {
      if (c.tenantId != tenantId) return false;
      return c.name.toLowerCase().contains(q) || c.nickname.toLowerCase().contains(q);
    }).take(limit).toList();

    return Result.ok(list);
  }

  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity client) async {
    final key = '${client.tenantId}|${client.id}';
    clients[key] = client;
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> deleteClient(String tenantId, String clientId) async {
    final key = '$tenantId|$clientId';
    clients.remove(key);
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(
    String tenantId,
    String clientId,
    VisitStatus status,
  ) async {
    final key = '$tenantId|$clientId';
    final client = clients[key];
    if (client != null) {
      clients[key] = client.copyWith(visitStatus: status);
    }
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(
    String tenantId,
    String zoneId,
  ) async {
    for (final entry in clients.entries) {
      if (entry.value.tenantId == tenantId && entry.value.zoneId == zoneId) {
        clients[entry.key] = entry.value.copyWith(visitStatus: VisitStatus.notVisited);
      }
    }
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> updateClientCustomPrices(
    String tenantId,
    String clientId,
    Map<String, Money> customPrices,
  ) async {
    final key = '$tenantId|$clientId';
    final client = clients[key];
    if (client != null) {
      clients[key] = client.copyWith(customPrices: customPrices);
    }
    return Result.ok(null);
  }
}

void main() {
  group('Contratos de Repositorio Abstractos (IoC)', () {
    const tenantA = 'tenant_sucursal_a';
    const tenantB = 'tenant_sucursal_b';

    test('ILedgerRepository: Aislamiento multi-tenant y cálculo de deuda', () async {
      final repo = FakeLedgerRepository();

      // Registro de asiento para Tenant A
      await repo.recordEntry(
        LedgerEntryEntity(
          id: 'e1',
          tenantId: tenantA,
          clientId: 'cli_01',
          date: DateTime.utc(2026, 8, 30),
          type: LedgerEntryType.saleDebt,
          referenceId: 'ref_1',
          amount: Money.fromUnits(10000),
          description: 'Venta ticket 1',
        ),
      );

      // Registro de asiento para Tenant B
      await repo.recordEntry(
        LedgerEntryEntity(
          id: 'e2',
          tenantId: tenantB,
          clientId: 'cli_99',
          date: DateTime.utc(2026, 8, 30),
          type: LedgerEntryType.saleDebt,
          referenceId: 'ref_2',
          amount: Money.fromUnits(50000),
          description: 'Venta de otro tenant',
        ),
      );

      final debtA = await repo.getTotalOutstandingDebt(tenantA);
      expect(debtA.isSuccess, isTrue);
      expect(debtA.valueOrNull, equals(Money.fromUnits(10000)));

      final entriesA = await repo.getEntriesByClient(tenantA, 'cli_01');
      expect(entriesA.isSuccess, isTrue);
      expect(entriesA.valueOrNull!.length, equals(1));
    });

    test('IClientRepository: Paginación, búsqueda y reseteo por zona', () async {
      final repo = FakeClientRepository();

      for (var i = 1; i <= 5; i++) {
        await repo.saveClient(
          ClientEntity(
            id: 'c$i',
            tenantId: tenantA,
            name: 'Cliente $i',
            zoneId: 'zona_lunes',
            visitStatus: VisitStatus.visited,
          ),
        );
      }

      // Paginación: pedir limit 2, offset 0
      final page1 = await repo.getClients(tenantA, zoneId: 'zona_lunes', limit: 2, offset: 0);
      expect(page1.isSuccess, isTrue);
      expect(page1.valueOrNull!.length, equals(2));

      // Búsqueda por coincidencia
      final searchRes = await repo.searchClients(tenantA, 'Cliente 3');
      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.valueOrNull!.first.name, equals('Cliente 3'));

      // Reseteo de zona
      await repo.resetVisitStatusForZone(tenantA, 'zona_lunes');
      final afterReset = await repo.getClientById(tenantA, 'c1');
      expect(afterReset.valueOrNull!.visitStatus, equals(VisitStatus.notVisited));
    });
  });
}
