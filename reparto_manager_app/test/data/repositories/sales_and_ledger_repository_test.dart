// test/data/repositories/sales_and_ledger_repository_test.dart
// Pruebas Unitarias - SaleRepositoryImpl, PaymentRepositoryImpl y LedgerRepositoryImpl
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/repositories/ledger_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/payment_repository_impl.dart';
import 'package:reparto_manager_app/data/repositories/sale_repository_impl.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/entities/payment_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SaleRepositoryImpl, PaymentRepositoryImpl & LedgerRepositoryImpl', () {
    late AppDatabase appDb;
    late Database db;
    late SaleRepositoryImpl saleRepo;
    late PaymentRepositoryImpl paymentRepo;
    late LedgerRepositoryImpl ledgerRepo;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      saleRepo = SaleRepositoryImpl(appDb);
      paymentRepo = PaymentRepositoryImpl(appDb);
      ledgerRepo = LedgerRepositoryImpl(appDb);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. SaleRepositoryImpl: correlativos, guardado, rankings y anulación', () async {
      final t1 = (await saleRepo.getNextTicketNumber('tenant_t1')).valueOrNull!;
      expect(t1, equals(1));

      final sale = SaleEntity(
        id: 'sale_1',
        tenantId: 'tenant_t1',
        clientId: 'c1',
        clientName: 'Kiosco Sol',
        ticketNumber: t1,
        date: DateTime.utc(2026, 8, 31, 10, 0),
        items: const [
          SaleItemEntity(
            productId: 'p1',
            productName: 'Alfajor',
            variantName: 'Simple',
            quantity: 5,
            unitPrice: Money.fromCents(10000),
            unitCost: Money.fromCents(6000),
          ),
        ],
        subtotal: Money.fromCents(50000),
        totalDiscount: Money.zero,
        total: Money.fromCents(50000),
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.fromCents(50000),
        transferPaid: Money.zero,
        debtGenerated: Money.zero,
      );

      await saleRepo.saveSale(sale);

      final t2 = (await saleRepo.getNextTicketNumber('tenant_t1')).valueOrNull!;
      expect(t2, equals(2));

      final topProds = (await saleRepo.getTopProducts(
        'tenant_t1',
        DateTime.utc(2026, 8, 30),
        DateTime.utc(2026, 9, 1),
      )).valueOrNull!;
      expect(topProds.first['productId'], equals('p1'));
      expect(topProds.first['totalQuantity'], equals(5));

      await saleRepo.cancelSale('tenant_t1', 'sale_1', 'Devolución de mercadería');
      final cancelledSale = (await saleRepo.getSaleById('tenant_t1', 'sale_1')).valueOrNull!;
      expect(cancelledSale.isCancelled, isTrue);
    });

    test('2. Arqueo de Caja Consolidado (CashSummaryEntity) unifica ventas y cobranzas', () async {
      final sale = SaleEntity(
        id: 's_mix',
        tenantId: 't_caja',
        clientId: 'c1',
        clientName: 'Almacén Don Mario',
        ticketNumber: 10,
        date: DateTime.utc(2026, 8, 31, 12, 0),
        items: const [
          SaleItemEntity(
            productId: 'p1',
            productName: 'Galletitas',
            variantName: 'Pack',
            quantity: 2,
            unitPrice: Money.fromCents(50000),
            unitCost: Money.fromCents(30000),
          ),
        ],
        subtotal: Money.fromCents(100000),
        totalDiscount: Money.zero,
        total: Money.fromCents(100000),
        paymentMethod: PaymentMethod.mixed,
        cashPaid: Money.fromCents(60000),
        transferPaid: Money.fromCents(30000),
        debtGenerated: Money.fromCents(10000),
      );
      await saleRepo.saveSale(sale);

      final payment = PaymentEntity(
        id: 'pay_1',
        tenantId: 't_caja',
        clientId: 'c1',
        receiptNumber: 1,
        date: DateTime.utc(2026, 8, 31, 14, 0),
        amount: Money.fromCents(20000),
        cashPaid: Money.fromCents(10000),
        transferPaid: Money.fromCents(10000),
        method: PaymentMethod.mixed,
      );
      await paymentRepo.savePayment(payment);

      final summary = (await saleRepo.getCashSummary(
        't_caja',
        DateTime.utc(2026, 8, 31, 0, 0),
        DateTime.utc(2026, 8, 31, 23, 59),
      )).valueOrNull!;

      expect(summary.salesCash.cents, equals(60000));
      expect(summary.salesTransfer.cents, equals(30000));
      expect(summary.paymentsCash.cents, equals(10000));
      expect(summary.paymentsTransfer.cents, equals(10000));
      expect(summary.totalCash.cents, equals(70000));
      expect(summary.totalTransfer.cents, equals(40000));
      expect(summary.totalRevenue.cents, equals(110000));
      expect(summary.debtGenerated.cents, equals(10000));
    });

    test('3. PaymentRepositoryImpl: recibos correlativos, consultas y anulación', () async {
      final r1 = (await paymentRepo.getNextReceiptNumber('t_pay')).valueOrNull!;
      expect(r1, equals(1));

      final p = PaymentEntity(
        id: 'p_10',
        tenantId: 't_pay',
        clientId: 'c_abc',
        receiptNumber: r1,
        date: DateTime.utc(2026, 8, 31, 9, 0),
        amount: Money.fromCents(25000),
        cashPaid: Money.fromCents(25000),
        transferPaid: Money.zero,
        method: PaymentMethod.cash,
      );
      await paymentRepo.savePayment(p);

      final r2 = (await paymentRepo.getNextReceiptNumber('t_pay')).valueOrNull!;
      expect(r2, equals(2));

      final clientPayments = (await paymentRepo.getPaymentsByClient('t_pay', 'c_abc')).valueOrNull!;
      expect(clientPayments.length, equals(1));

      final cancelRes = await paymentRepo.cancelPayment('t_pay', 'p_10', 'Cheque rechazado');
      expect(cancelRes.isSuccess, isTrue);
    });

    test('4. LedgerRepositoryImpl: partida doble atómica, deuda circulante y snapshots', () async {
      final e1 = LedgerEntryEntity(
        id: 'led_v1',
        tenantId: 't_ledger',
        clientId: 'cli_99',
        date: DateTime.utc(2026, 8, 31, 10, 0),
        type: LedgerEntryType.saleDebt,
        referenceId: 'sale_1',
        amount: Money.fromCents(100000),
        description: 'Venta #1',
      );
      final e2 = LedgerEntryEntity(
        id: 'led_p1',
        tenantId: 't_ledger',
        clientId: 'cli_99',
        date: DateTime.utc(2026, 8, 31, 10, 0),
        type: LedgerEntryType.paymentCredit,
        referenceId: 'sale_1',
        amount: Money.fromCents(40000),
        description: 'Pago parcial venta #1',
      );

      final recordRes = await ledgerRepo.recordEntries([e1, e2]);
      expect(recordRes.isSuccess, isTrue);

      final entries = (await ledgerRepo.getEntriesByClient('t_ledger', 'cli_99')).valueOrNull!;
      expect(entries.length, equals(2));

      final totalDebt = (await ledgerRepo.getTotalOutstandingDebt('t_ledger')).valueOrNull!;
      expect(totalDebt.cents, equals(60000));

      final snapshot = LedgerSnapshot(
        tenantId: 't_ledger',
        clientId: 'cli_99',
        closingDate: DateTime.utc(2026, 8, 31, 23, 59),
        balance: Money.fromCents(60000),
        lastEntryId: 'led_p1',
        entryCount: 2,
      );
      await ledgerRepo.saveSnapshot(snapshot);

      final loadedSnapshot = (await ledgerRepo.getLatestSnapshot('t_ledger', 'cli_99')).valueOrNull!;
      expect(loadedSnapshot.balance.cents, equals(60000));
      expect(loadedSnapshot.entryCount, equals(2));
    });
  });
}
