// test/domain/repositories/repository_contracts_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/cash_summary_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_ledger_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_sale_repository.dart';

/// Fake en memoria para validar ILedgerRepository.
class FakeLedgerRepository implements ILedgerRepository {
  final List<LedgerEntryEntity> entries = [];
  final Map<String, LedgerSnapshot> snapshots = {};

  @override
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity e) async {
    entries.add(e);
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> recordEntries(List<LedgerEntryEntity> items) async {
    entries.addAll(items);
    return Result.ok(null);
  }

  @override
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(
    String tId, String cId, {DateTime? sinceUtc, int limit = 50, int offset = 0}) async {
    final filtered = entries.where((e) => e.tenantId == tId && e.clientId == cId &&
        (sinceUtc == null || !e.date.isBefore(sinceUtc))).skip(offset).take(limit).toList();
    return Result.ok(filtered);
  }

  @override
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String tId) async {
    final total = entries.where((e) => e.tenantId == tId).fold(Money.zero, (acc, e) => acc + e.balanceImpact);
    return Result.ok(total);
  }

  @override
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(String tId, String cId) async =>
      Result.ok(snapshots['$tId|$cId']);

  @override
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot s) async {
    snapshots['${s.tenantId}|${s.clientId}'] = s;
    return Result.ok(null);
  }
}

/// Fake en memoria para validar IClientRepository.
class FakeClientRepository implements IClientRepository {
  final Map<String, ClientEntity> clients = {};

  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(String tenantId, String clientId) async {
    final client = clients['$tenantId|$clientId'];
    return client != null
        ? Result.ok(client)
        : Result.fail(const EntityValidationFailure('No encontrado'));
  }

  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(
    String tenantId, {
    String? zoneId,
    int limit = 50,
    int offset = 0,
  }) async {
    final list = clients.values.where((c) {
      return c.tenantId == tenantId && (zoneId == null || c.zoneId == zoneId);
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
      return c.tenantId == tenantId &&
          (c.name.toLowerCase().contains(q) || c.nickname.toLowerCase().contains(q));
    }).take(limit).toList();
    return Result.ok(list);
  }

  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity client) async {
    clients['${client.tenantId}|${client.id}'] = client;
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> deleteClient(String tenantId, String clientId) async {
    clients.remove('$tenantId|$clientId');
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(
    String tenantId,
    String clientId,
    VisitStatus status,
  ) async {
    final c = clients['$tenantId|$clientId'];
    if (c != null) clients['$tenantId|$clientId'] = c.copyWith(visitStatus: status);
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(String tenantId, String zoneId) async {
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
    final c = clients['$tenantId|$clientId'];
    if (c != null) clients['$tenantId|$clientId'] = c.copyWith(customPrices: customPrices);
    return Result.ok(null);
  }
}

/// Fake en memoria para ISaleRepository probando CashSummaryEntity.
class FakeSaleRepository implements ISaleRepository {
  final List<SaleEntity> sales = [];

  @override
  Future<Result<CashSummaryEntity, DomainFailure>> getCashSummary(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    var sCash = Money.zero;
    var sTransfer = Money.zero;
    var debt = Money.zero;
    final breakdown = <CashSummaryItem>[];

    for (final s in sales.where((s) => s.tenantId == tenantId)) {
      sCash = sCash + s.cashPaid;
      sTransfer = sTransfer + s.transferPaid;
      debt = debt + s.debtGenerated;
      breakdown.add(CashSummaryItem(
        clientId: s.clientId,
        clientName: s.clientName,
        cash: s.cashPaid,
        transfer: s.transferPaid,
      ));
    }

    return Result.ok(CashSummaryEntity(
      salesCash: sCash,
      salesTransfer: sTransfer,
      paymentsCash: Money.zero,
      paymentsTransfer: Money.zero,
      debtGenerated: debt,
      clientBreakdown: breakdown,
    ));
  }

  @override
  Future<Result<void, DomainFailure>> saveSale(SaleEntity sale) async {
    sales.add(sale);
    return Result.ok(null);
  }

  @override
  Future<Result<SaleEntity, DomainFailure>> getSaleById(String t, String s) async => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByDateRange(String t, DateTime st, DateTime e, {int limit = 50, int offset = 0}) async => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByClient(String t, String c, {int limit = 20, int offset = 0}) async => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopProducts(String t, DateTime st, DateTime e, {int limit = 10}) async => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopClients(String t, DateTime st, DateTime e, {int limit = 10}) async => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> cancelSale(String t, String s, String r) async => throw UnimplementedError();
  @override
  Future<Result<int, DomainFailure>> getNextTicketNumber(String t) async => Result.ok(sales.length + 1);
}

void main() {
  group('Contratos de Repositorio Abstractos (IoC)', () {
    const tenantA = 'tenant_sucursal_a';
    const tenantB = 'tenant_sucursal_b';

    test('ILedgerRepository: Aislamiento multi-tenant y cálculo de deuda', () async {
      final repo = FakeLedgerRepository();

      await repo.recordEntry(LedgerEntryEntity(
        id: 'e1',
        tenantId: tenantA,
        clientId: 'cli_01',
        date: DateTime.utc(2026, 8, 30),
        type: LedgerEntryType.saleDebt,
        referenceId: 'ref_1',
        amount: Money.fromUnits(10000),
        description: 'Venta ticket 1',
      ));

      await repo.recordEntry(LedgerEntryEntity(
        id: 'e2',
        tenantId: tenantB,
        clientId: 'cli_99',
        date: DateTime.utc(2026, 8, 30),
        type: LedgerEntryType.saleDebt,
        referenceId: 'ref_2',
        amount: Money.fromUnits(50000),
        description: 'Venta de otro tenant',
      ));

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
        await repo.saveClient(ClientEntity(
          id: 'c$i',
          tenantId: tenantA,
          name: 'Cliente $i',
          zoneId: 'zona_lunes',
          visitStatus: VisitStatus.visited,
        ));
      }

      final page1 = await repo.getClients(tenantA, zoneId: 'zona_lunes', limit: 2, offset: 0);
      expect(page1.isSuccess, isTrue);
      expect(page1.valueOrNull!.length, equals(2));

      final searchRes = await repo.searchClients(tenantA, 'Cliente 3');
      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.valueOrNull!.first.name, equals('Cliente 3'));

      await repo.resetVisitStatusForZone(tenantA, 'zona_lunes');
      final afterReset = await repo.getClientById(tenantA, 'c1');
      expect(afterReset.valueOrNull!.visitStatus, equals(VisitStatus.notVisited));
    });

    test('ISaleRepository: Arqueo de caja diario con CashSummaryEntity', () async {
      final repo = FakeSaleRepository();

      await repo.saveSale(SaleEntity(
        id: 's1',
        tenantId: tenantA,
        clientId: 'cli_01',
        clientName: 'Panadería Central',
        ticketNumber: 1,
        date: DateTime.utc(2026, 8, 30),
        items: const [],
        subtotal: Money.fromUnits(5000),
        totalDiscount: Money.zero,
        total: Money.fromUnits(5000),
        paymentMethod: PaymentMethod.mixed,
        cashPaid: Money.fromUnits(3000),
        transferPaid: Money.fromUnits(1000),
        debtGenerated: Money.fromUnits(1000),
      ));

      final summaryRes = await repo.getCashSummary(tenantA, DateTime.utc(2026, 8, 30), DateTime.utc(2026, 8, 30, 23, 59));
      expect(summaryRes.isSuccess, isTrue);
      final summary = summaryRes.valueOrNull!;

      expect(summary.salesCash, equals(Money.fromUnits(3000)));
      expect(summary.salesTransfer, equals(Money.fromUnits(1000)));
      expect(summary.totalCash, equals(Money.fromUnits(3000)));
      expect(summary.totalTransfer, equals(Money.fromUnits(1000)));
      expect(summary.totalRevenue, equals(Money.fromUnits(4000)));
      expect(summary.debtGenerated, equals(Money.fromUnits(1000)));
      expect(summary.clientBreakdown.length, equals(1));
    });
  });
}
