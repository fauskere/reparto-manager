// test/domain/usecases/ledger_and_payments_use_cases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/cash_summary_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_group_entity.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/entities/payment_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_group_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_ledger_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_payment_repository.dart';
import 'package:reparto_manager_app/domain/repositories/i_sale_repository.dart';
import 'package:reparto_manager_app/domain/usecases/calculate_client_balance_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/cancel_payment_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/create_group_invoice_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/generate_cash_summary_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/generate_ledger_snapshot_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/pay_group_invoice_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/record_manual_adjustment_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/register_payment_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/reset_zone_route_use_case.dart';

class FakeLedgerRepo implements ILedgerRepository {
  final List<LedgerEntryEntity> entries = [];
  final Map<String, LedgerSnapshot> snapshots = {};

  @override
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity e) async { entries.add(e); return Result.ok(null); }
  @override
  Future<Result<void, DomainFailure>> recordEntries(List<LedgerEntryEntity> items) async { entries.addAll(items); return Result.ok(null); }
  @override
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(String t, String c, {DateTime? sinceUtc, int limit = 50, int offset = 0}) async {
    final res = entries.where((e) => e.tenantId == t && e.clientId == c && (sinceUtc == null || !e.date.isBefore(sinceUtc))).skip(offset).take(limit).toList();
    return Result.ok(res);
  }
  @override
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(String t, String c) async => Result.ok(snapshots['$t|$c']);
  @override
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot s) async { snapshots['${s.tenantId}|${s.clientId}'] = s; return Result.ok(null); }
  @override
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String t) => throw UnimplementedError();
}

class FakePaymentRepo implements IPaymentRepository {
  final List<PaymentEntity> payments = [];
  final Map<String, String> cancellations = {};
  int receiptSeq = 0;

  @override
  Future<Result<int, DomainFailure>> getNextReceiptNumber(String t) async => Result.ok(++receiptSeq);
  @override
  Future<Result<void, DomainFailure>> savePayment(PaymentEntity p) async { payments.add(p); return Result.ok(null); }
  @override
  Future<Result<void, DomainFailure>> cancelPayment(String t, String id, String r) async { cancellations['$t|$id'] = r; return Result.ok(null); }
  @override
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByClient(String t, String c, {int limit = 20, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByDateRange(String t, DateTime s, DateTime e, {int limit = 50, int offset = 0}) => throw UnimplementedError();
}

class FakeClientRepo implements IClientRepository {
  final Map<String, VisitStatus> visits = {};
  final List<String> resetZones = [];

  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(String t, String c, VisitStatus s) async { visits['$t|$c'] = s; return Result.ok(null); }
  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(String t, String z) async { resetZones.add(z); return Result.ok(null); }
  @override
  Future<Result<void, DomainFailure>> deleteClient(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(String t, {String? zoneId, int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(String t, String q, {int limit = 20}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> updateClientCustomPrices(String t, String c, Map<String, Money> cp) => throw UnimplementedError();
}

class FakeGroupRepo implements IClientGroupRepository {
  final List<Map<String, dynamic>> createdInvoices = [];
  final List<String> paidInvoices = [];

  @override
  Future<Result<void, DomainFailure>> createGroupInvoice(String t, String g, Money a, List<String> s) async {
    createdInvoices.add({'tenantId': t, 'groupId': g, 'amount': a, 'saleIds': s});
    return Result.ok(null);
  }
  @override
  Future<Result<void, DomainFailure>> payGroupInvoice(String t, String g, String invId) async { paidInvoices.add(invId); return Result.ok(null); }
  @override
  Future<Result<void, DomainFailure>> deleteClientGroup(String t, String g) => throw UnimplementedError();
  @override
  Future<Result<List<ClientGroupEntity>, DomainFailure>> getClientGroups(String t) => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getGroupInvoices(String t, String g) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveClientGroup(ClientGroupEntity g) => throw UnimplementedError();
}

class FakeSaleRepoForCash implements ISaleRepository {
  @override
  Future<Result<CashSummaryEntity, DomainFailure>> getCashSummary(String t, DateTime s, DateTime e) async {
    return Result.ok(CashSummaryEntity(
      salesCash: Money(300000),
      salesTransfer: Money(200000),
      paymentsCash: Money(100000),
      paymentsTransfer: Money(50000),
      debtGenerated: Money(400000),
    ));
  }
  @override
  Future<Result<void, DomainFailure>> cancelSale(String t, String id, String r) => throw UnimplementedError();
  @override
  Future<Result<int, DomainFailure>> getNextTicketNumber(String t) => throw UnimplementedError();
  @override
  Future<Result<SaleEntity, DomainFailure>> getSaleById(String t, String id) => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByClient(String t, String c, {int limit = 20, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByDateRange(String t, DateTime s, DateTime e, {int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopClients(String t, DateTime s, DateTime e, {int limit = 10}) => throw UnimplementedError();
  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopProducts(String t, DateTime s, DateTime e, {int limit = 10}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveSale(SaleEntity s) => throw UnimplementedError();
}

void main() {
  group('Casos de Uso: Pagos, Ledger, Ajustes y Arqueo (Reglas 9 y 11)', () {
    const tenantId = 'tenant_1';
    const clientId = 'client_mario';

    test('CalculateClientBalanceUseCase calcula saldo sumando snapshot + deltas (Regla 9)', () async {
      final ledger = FakeLedgerRepo();
      final snapDate = DateTime.utc(2026, 8, 1);
      ledger.snapshots['$tenantId|$clientId'] = LedgerSnapshot(
        tenantId: tenantId,
        clientId: clientId,
        closingDate: snapDate,
        balance: Money(500000), // $5.000 deudor base
        lastEntryId: 'snap_0',
        entryCount: 1,
      );

      await ledger.recordEntry(LedgerEntryEntity(
        id: 'e1', tenantId: tenantId, clientId: clientId,
        date: DateTime.utc(2026, 8, 5), type: LedgerEntryType.saleDebt,
        referenceId: 's1', amount: Money(300000), description: 'Venta',
      ));

      await ledger.recordEntry(LedgerEntryEntity(
        id: 'e2', tenantId: tenantId, clientId: clientId,
        date: DateTime.utc(2026, 8, 10), type: LedgerEntryType.paymentCredit,
        referenceId: 'p1', amount: Money(200000), description: 'Pago',
      ));

      final useCase = CalculateClientBalanceUseCase(ledger);
      final balanceRes = await useCase.execute(tenantId: tenantId, clientId: clientId);

      expect(balanceRes.isSuccess, isTrue);
      // $5.000 + $3.000 - $2.000 = $6.000
      expect(balanceRes.valueOrNull, equals(Money(600000)));
    });

    test('RegisterPaymentUseCase registra cobro mixto, emite crédito y recibo', () async {
      final payRepo = FakePaymentRepo();
      final ledgerRepo = FakeLedgerRepo();
      final clientRepo = FakeClientRepo();

      final useCase = RegisterPaymentUseCase(payRepo, ledgerRepo, clientRepo);

      final payment = PaymentEntity(
        id: 'pay_1',
        tenantId: tenantId,
        clientId: clientId,
        receiptNumber: 0,
        date: DateTime.utc(2026, 8, 30),
        amount: Money(400000),
        method: PaymentMethod.mixed,
        cashPaid: Money(250000),
        transferPaid: Money(150000),
      );

      final result = await useCase.execute(payment: payment);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.receiptNumber, equals(1));
      expect(ledgerRepo.entries.length, equals(1));
      expect(ledgerRepo.entries.first.type, equals(LedgerEntryType.paymentCredit));
      expect(clientRepo.visits['$tenantId|$clientId'], equals(VisitStatus.visited));
    });

    test('CancelPaymentUseCase anula recibo y asienta contra-asiento de débito', () async {
      final payRepo = FakePaymentRepo();
      final ledgerRepo = FakeLedgerRepo();
      final useCase = CancelPaymentUseCase(payRepo, ledgerRepo);

      final result = await useCase.execute(
        tenantId: tenantId, paymentId: 'pay_bad', clientId: clientId,
        paymentAmount: Money(150000), reason: 'Cheque rechazado',
      );
      expect(result.isSuccess, isTrue);
      expect(payRepo.cancellations['$tenantId|pay_bad'], equals('Cheque rechazado'));
      expect(ledgerRepo.entries.first.type, equals(LedgerEntryType.adjustmentDebt));
      expect(ledgerRepo.entries.first.amount, equals(Money(150000)));
    });

    test('RecordManualAdjustmentUseCase asienta saldo inicial auditado', () async {
      final ledger = FakeLedgerRepo();
      final useCase = RecordManualAdjustmentUseCase(ledger);

      final result = await useCase.execute(
        tenantId: tenantId, clientId: clientId, amount: Money(800000),
        isCredit: false, reason: 'Saldo inicial libreta vieja V1',
      );
      expect(result.isSuccess, isTrue);
      expect(ledger.entries.first.type, equals(LedgerEntryType.adjustmentDebt));
      expect(ledger.entries.first.amount, equals(Money(800000)));
    });

    test('GenerateLedgerSnapshotUseCase consolida saldo periódico (Regla 11)', () async {
      final ledger = FakeLedgerRepo();
      await ledger.recordEntry(LedgerEntryEntity(
        id: 'e1', tenantId: tenantId, clientId: clientId,
        date: DateTime.utc(2026, 8, 1), type: LedgerEntryType.saleDebt,
        referenceId: 's1', amount: Money(1000000), description: 'Venta',
      ));

      final useCase = GenerateLedgerSnapshotUseCase(ledger);
      final snapRes = await useCase.execute(
        tenantId: tenantId,
        clientId: clientId,
        closingDateUtc: DateTime.utc(2026, 8, 30),
      );

      expect(snapRes.isSuccess, isTrue);
      expect(snapRes.valueOrNull!.balance, equals(Money(1000000)));
      expect(ledger.snapshots['$tenantId|$clientId']!.balance, equals(Money(1000000)));
    });

    test('CreateGroupInvoiceUseCase y PayGroupInvoiceUseCase operan con corte y crédito', () async {
      final grpRepo = FakeGroupRepo();
      final ledger = FakeLedgerRepo();

      final createUseCase = CreateGroupInvoiceUseCase(grpRepo);
      final createRes = await createUseCase.execute(
        tenantId: tenantId,
        groupId: 'grp_belgrano',
        totalAmount: Money(1500000),
        saleIds: ['s1', 's2'],
      );
      expect(createRes.isSuccess, isTrue);
      expect(grpRepo.createdInvoices.length, equals(1));

      final payUseCase = PayGroupInvoiceUseCase(grpRepo, ledger);
      final payRes = await payUseCase.execute(
        tenantId: tenantId,
        groupId: 'grp_belgrano',
        invoiceId: 'inv_01',
        mainClientId: 'cli_central',
        amount: Money(1500000),
      );
      expect(payRes.isSuccess, isTrue);
      expect(grpRepo.paidInvoices, contains('inv_01'));
      expect(ledger.entries.first.type, equals(LedgerEntryType.paymentCredit));
    });

    test('GenerateCashSummaryUseCase y ResetZoneRouteUseCase ejecutan correctamente', () async {
      final clientRepo = FakeClientRepo();
      final resetUseCase = ResetZoneRouteUseCase(clientRepo);
      final resetRes = await resetUseCase.execute(tenantId: tenantId, zoneId: 'zona_lunes');
      expect(resetRes.isSuccess, isTrue);
      expect(clientRepo.resetZones, contains('zona_lunes'));

      final saleRepo = FakeSaleRepoForCash();
      final cashUseCase = GenerateCashSummaryUseCase(saleRepo);
      final cashRes = await cashUseCase.execute(
        tenantId: tenantId,
        startUtc: DateTime.utc(2026, 8, 30),
        endUtc: DateTime.utc(2026, 8, 30, 23, 59),
      );
      expect(cashRes.isSuccess, isTrue);
      final sum = cashRes.valueOrNull!;
      expect(sum.totalCash, equals(Money(400000))); // 3.000 + 1.000
      expect(sum.totalTransfer, equals(Money(250000))); // 2.000 + 500
      expect(sum.totalRevenue, equals(Money(650000)));
    });
  });
}
