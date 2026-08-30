// test/domain/usecases/sales_use_cases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/cash_summary_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_ledger_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_sale_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_truck_repository.dart';
import 'package:reparto_manager_app/domain/usecases/cancel_sale_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/process_sale_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/update_sale_use_case.dart';

class FakeSaleRepo implements ISaleRepository {
  final Map<String, SaleEntity> sales = {};
  final Map<String, String> cancellations = {};
  int counter = 0;

  @override
  Future<Result<int, DomainFailure>> getNextTicketNumber(String t) async => Result.ok(++counter);
  @override
  Future<Result<void, DomainFailure>> saveSale(SaleEntity s) async {
    sales['${s.tenantId}|${s.id}'] = s;
    return Result.ok(null);
  }
  @override
  Future<Result<SaleEntity, DomainFailure>> getSaleById(String t, String id) async {
    final s = sales['$t|$id'];
    return s != null ? Result.ok(s) : Result.fail(const EntityValidationFailure('Venta no encontrada'));
  }
  @override
  Future<Result<void, DomainFailure>> cancelSale(String t, String id, String r) async {
    cancellations['$t|$id'] = r;
    return Result.ok(null);
  }

  @override
  Future<Result<CashSummaryEntity, DomainFailure>> getCashSummary(String t, DateTime s, DateTime e) => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByClient(String t, String c, {int limit = 20, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByDateRange(String t, DateTime s, DateTime e, {int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopClients(String t, DateTime s, DateTime e, {int limit = 10}) => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopProducts(String t, DateTime s, DateTime e, {int limit = 10}) => throw UnimplementedError();
}

class FakeTruckRepoForSales implements ITruckRepository {
  final Map<String, int> stock = {};

  @override
  Future<Result<void, DomainFailure>> applyStockDelta(String t, String tr, Map<String, int> deltas) async {
    for (final e in deltas.entries) {
      stock[e.key] = (stock[e.key] ?? 0) + e.value;
    }
    return Result.ok(null);
  }

  @override
  Future<Result<TruckLoadEntity, DomainFailure>> getTodayTruckLoad(String t, String tr, DateTime d) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveTruckLoad(TruckLoadEntity tl) => throw UnimplementedError();
}

class FakeLedgerRepoForSales implements ILedgerRepository {
  final List<LedgerEntryEntity> entries = [];

  @override
  Future<Result<void, DomainFailure>> recordEntries(List<LedgerEntryEntity> items) async {
    entries.addAll(items);
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity entry) async {
    entries.add(entry);
    return Result.ok(null);
  }

  @override
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(String t, String c, {DateTime? sinceUtc, int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String t) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot s) => throw UnimplementedError();
}

class FakeClientRepoForSales implements IClientRepository {
  final Map<String, VisitStatus> visits = {};

  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(String t, String c, VisitStatus s) async {
    visits['$t|$c'] = s;
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> deleteClient(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(String t, {String? zoneId, int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(String t, String z) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(String t, String q, {int limit = 20}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> updateClientCustomPrices(String t, String c, Map<String, Money> cp) => throw UnimplementedError();
}

void main() {
  group('Casos de Uso: Ventas (Proceso, Modificación y Anulación)', () {
    const tenantId = 'tenant_1';
    const truckId = 'truck_01';

    test('ProcessSaleUseCase aplica partida doble, descuenta stock y marca visita', () async {
      final saleRepo = FakeSaleRepo();
      final truckRepo = FakeTruckRepoForSales();
      final ledgerRepo = FakeLedgerRepoForSales();
      final clientRepo = FakeClientRepoForSales();

      final useCase = ProcessSaleUseCase(
        saleRepo,
        truckRepo,
        ledgerRepo,
        clientRepo,
      );

      final sale = SaleEntity(
        id: 'sale_100',
        tenantId: tenantId,
        clientId: 'cli_01',
        clientName: 'Don Pepe',
        ticketNumber: 0,
        date: DateTime.utc(2026, 8, 30),
        items: const [
          SaleItemEntity(
            productId: 'p1',
            variantName: 'std',
            productName: 'Alfa',
            quantity: 5,
            unitPrice: Money(100000),
            unitCost: Money(60000),
          ),
        ],
        exchanges: const [
          ExchangeItemEntity(productId: 'p1', variantName: 'std', productName: 'Alfa', quantity: 1),
        ],
        subtotal: Money(500000),
        totalDiscount: Money.zero,
        total: Money(500000),
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money(300000),
        transferPaid: Money.zero,
        debtGenerated: Money(200000),
      );

      final result = await useCase.execute(sale: sale, truckId: truckId);

      expect(result.isSuccess, isTrue);
      final confirmed = result.valueOrNull!;
      expect(confirmed.ticketNumber, equals(1));

      // Stock: -5 vendidos + 1 devuelto/cambio = -4 neto
      expect(truckRepo.stock['p1|std'], equals(-4));

      // Partida Doble en Ledger: 2 asientos (Débito $5.000 + Crédito $3.000)
      expect(ledgerRepo.entries.length, equals(2));
      expect(ledgerRepo.entries[0].type, equals(LedgerEntryType.saleDebt));
      expect(ledgerRepo.entries[0].amount, equals(Money(500000)));
      expect(ledgerRepo.entries[1].type, equals(LedgerEntryType.paymentCredit));
      expect(ledgerRepo.entries[1].amount, equals(Money(300000)));

      // Cliente visitado
      expect(clientRepo.visits['$tenantId|cli_01'], equals(VisitStatus.visited));
    });

    test('UpdateSaleUseCase ajusta stock y emite asiento por diferencia de deuda', () async {
      final saleRepo = FakeSaleRepo();
      final truckRepo = FakeTruckRepoForSales();
      final ledgerRepo = FakeLedgerRepoForSales();

      final useCase = UpdateSaleUseCase(
        saleRepo,
        truckRepo,
        ledgerRepo,
      );

      final oldSale = SaleEntity(
        id: 's1',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco',
        ticketNumber: 1,
        date: DateTime.utc(2026, 8, 30),
        items: const [
          SaleItemEntity(productId: 'p1', variantName: 'std', productName: 'A', quantity: 2, unitPrice: Money(100000), unitCost: Money(50000)),
        ],
        subtotal: Money(200000),
        totalDiscount: Money.zero,
        total: Money(200000),
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money(200000),
        transferPaid: Money.zero,
        debtGenerated: Money.zero,
      );

      final newSale = oldSale.copyWith(
        items: const [
          SaleItemEntity(productId: 'p1', variantName: 'std', productName: 'A', quantity: 3, unitPrice: Money(100000), unitCost: Money(50000)),
        ],
        subtotal: Money(300000),
        total: Money(300000),
        debtGenerated: Money(100000), // $1.000 fiado adicional
      );

      final result = await useCase.execute(oldSale: oldSale, updatedSale: newSale, truckId: truckId);
      expect(result.isSuccess, isTrue);

      // Delta de stock: vendió 1 más => -1 en camión
      expect(truckRepo.stock['p1|std'], equals(-1));

      // Asiento contable de ajuste: aumento de deuda por $1.000
      expect(ledgerRepo.entries.length, equals(1));
      expect(ledgerRepo.entries.first.type, equals(LedgerEntryType.adjustmentDebt));
      expect(ledgerRepo.entries.first.amount, equals(Money(100000)));
    });

    test('CancelSaleUseCase repone stock y genera contra-asiento en el Ledger', () async {
      final saleRepo = FakeSaleRepo();
      final truckRepo = FakeTruckRepoForSales();
      final ledgerRepo = FakeLedgerRepoForSales();

      final sale = SaleEntity(
        id: 's_cancel',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco',
        ticketNumber: 5,
        date: DateTime.utc(2026, 8, 30),
        items: const [
          SaleItemEntity(productId: 'p1', variantName: 'std', productName: 'A', quantity: 4, unitPrice: Money(100000), unitCost: Money(50000)),
        ],
        subtotal: Money(400000),
        totalDiscount: Money.zero,
        total: Money(400000),
        paymentMethod: PaymentMethod.onAccount,
        cashPaid: Money.zero,
        transferPaid: Money.zero,
        debtGenerated: Money(400000),
      );

      await saleRepo.saveSale(sale);

      final useCase = CancelSaleUseCase(
        saleRepo,
        truckRepo,
        ledgerRepo,
      );

      final result = await useCase.execute(
        tenantId: tenantId,
        saleId: 's_cancel',
        reason: 'Error en cantidad pedida',
        truckId: truckId,
      );

      expect(result.isSuccess, isTrue);
      // Stock reincorporado: +4
      expect(truckRepo.stock['p1|std'], equals(4));

      // Contra-asiento de crédito para cancelar la deuda generada
      expect(ledgerRepo.entries.length, equals(1));
      expect(ledgerRepo.entries.first.type, equals(LedgerEntryType.adjustmentCredit));
      expect(ledgerRepo.entries.first.amount, equals(Money(400000)));
    });
  });
}
