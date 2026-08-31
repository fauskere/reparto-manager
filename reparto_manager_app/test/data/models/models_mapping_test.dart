// test/data/models/models_mapping_test.dart
// Pruebas Unitarias - Mapeadores Bidireccionales Data Models V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/product_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/entities/payment_entity.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';
import 'package:reparto_manager_app/domain/entities/cash_summary_entity.dart';
import 'package:reparto_manager_app/domain/entities/zone_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_group_entity.dart';
import 'package:reparto_manager_app/domain/entities/promotion_entity.dart';
import 'package:reparto_manager_app/data/models/client_model.dart';
import 'package:reparto_manager_app/data/models/product_model.dart';
import 'package:reparto_manager_app/data/models/price_history_model.dart';
import 'package:reparto_manager_app/data/models/sale_model.dart';
import 'package:reparto_manager_app/data/models/payment_model.dart';
import 'package:reparto_manager_app/data/models/truck_load_model.dart';
import 'package:reparto_manager_app/data/models/ledger_entry_model.dart';
import 'package:reparto_manager_app/data/models/cash_summary_model.dart';
import 'package:reparto_manager_app/data/models/zone_model.dart';
import 'package:reparto_manager_app/data/models/client_group_model.dart';
import 'package:reparto_manager_app/data/models/group_invoice_model.dart';
import 'package:reparto_manager_app/data/models/promotion_model.dart';
import 'package:reparto_manager_app/data/models/sync_queue_model.dart';

void main() {
  group('Data Models - Mapeo Bidireccional y Preservación de Precisión Bancaria', () {
    test('1. ClientModel: conversión bidireccional y preservación de centavos', () {
      final entity = ClientEntity(
        id: 'c1',
        tenantId: 't1',
        name: 'Kiosco Belén',
        nickname: 'Belén',
        city: 'Santa Fe',
        address: 'San Martín 1234',
        zoneId: 'z1',
        type: ClientType.especial,
        visitStatus: VisitStatus.pending,
        isStore: true,
        isOpenContinuous: true,
        groupId: 'g1',
        customPrices: {'p1|grande': Money.fromCents(125050)},
        balance: Money.fromCents(45000),
        debtLimit: Money.fromCents(200000),
        isActive: true,
      );

      final model = ClientModel.fromEntity(entity);
      final map = model.toMap();
      final fromMap = ClientModel.fromMap(map);
      final restored = fromMap.toEntity();

      expect(restored.id, equals(entity.id));
      expect(restored.tenantId, equals(entity.tenantId));
      expect(restored.name, equals(entity.name));
      expect(restored.type, equals(entity.type));
      expect(restored.balance.cents, equals(45000));
      expect(restored.debtLimit?.cents, equals(200000));
      expect(restored.customPrices['p1|grande']?.cents, equals(125050));
      expect(restored.isOpenContinuous, isTrue);
    });

    test('2. ProductModel: serialización de variantes y centavos de costo/venta', () {
      final entity = ProductEntity(
        id: 'p1',
        tenantId: 't1',
        name: 'Alfajor Triple',
        category: 'Golosinas',
        variants: [
          ProductVariant(
            variantName: 'Chocolate',
            productId: 'p1',
            basePrice: Money.fromCents(150000),
            costPrice: Money.fromCents(80000),
            stockWarehouse: 120,
            minStockAlert: 20,
          ),
        ],
      );

      final model = ProductModel.fromEntity(entity);
      final map = model.toMap();
      final restored = ProductModel.fromMap(map).toEntity();

      expect(restored.id, equals(entity.id));
      expect(restored.variants.length, equals(1));
      expect(restored.variants.first.variantName, equals('Chocolate'));
      expect(restored.variants.first.basePrice.cents, equals(150000));
      expect(restored.variants.first.costPrice.cents, equals(80000));
      expect(restored.variants.first.stockWarehouse, equals(120));
    });

    test('3. SaleModel: serialización de renglones, cambios y partida doble', () {
      final entity = SaleEntity(
        id: 's1',
        tenantId: 't1',
        clientId: 'c1',
        clientName: 'Kiosco Sol',
        ticketNumber: 1042,
        date: DateTime.utc(2026, 8, 30, 10, 0),
        items: [
          const SaleItemEntity(
            productId: 'p1',
            productName: 'Alfajor',
            variantName: 'Simple',
            quantity: 10,
            unitPrice: Money.fromCents(10000),
            unitCost: Money.fromCents(6000),
          ),
        ],
        exchanges: const [
          ExchangeItemEntity(
            productId: 'p1',
            productName: 'Alfajor',
            variantName: 'Simple',
            quantity: 1,
          ),
        ],
        appliedPromos: const ['PROMO10'],
        subtotal: Money.fromCents(100000),
        totalDiscount: Money.fromCents(10000),
        total: Money.fromCents(90000),
        paymentMethod: PaymentMethod.mixed,
        cashPaid: Money.fromCents(50000),
        transferPaid: Money.fromCents(40000),
        debtGenerated: Money.zero,
        previousBalance: Money.fromCents(15000),
        remainingBalance: Money.fromCents(15000),
      );

      final model = SaleModel.fromEntity(entity);
      final map = model.toMap();
      final restored = SaleModel.fromMap(map).toEntity();

      expect(restored.ticketNumber, equals(1042));
      expect(restored.items.length, equals(1));
      expect(restored.exchanges.length, equals(1));
      expect(restored.appliedPromos, contains('PROMO10'));
      expect(restored.total.cents, equals(90000));
      expect(restored.cashPaid.cents, equals(50000));
      expect(restored.transferPaid.cents, equals(40000));
      expect(restored.debtGenerated, equals(Money.zero));
    });

    test('4. PaymentModel: cobro mixto y comprobante', () {
      final entity = PaymentEntity(
        id: 'pay1',
        tenantId: 't1',
        clientId: 'c1',
        receiptNumber: 501,
        date: DateTime.utc(2026, 8, 30, 11, 0),
        amount: Money.fromCents(30000),
        cashPaid: Money.fromCents(20000),
        transferPaid: Money.fromCents(10000),
        method: PaymentMethod.mixed,
        previousBalance: Money.fromCents(50000),
        remainingBalance: Money.fromCents(20000),
        notes: 'Pago a cuenta',
      );

      final model = PaymentModel.fromEntity(entity);
      final map = model.toMap();
      final restored = PaymentModel.fromMap(map).toEntity();

      expect(restored.receiptNumber, equals(501));
      expect(restored.amount.cents, equals(30000));
      expect(restored.cashPaid.cents, equals(20000));
      expect(restored.transferPaid.cents, equals(10000));
      expect(restored.method, equals(PaymentMethod.mixed));
      expect(restored.notes, equals('Pago a cuenta'));
    });

    test('5. TruckLoadModel: inventario a bordo y mermas por variante', () {
      final entity = TruckLoadEntity(
        truckId: 'truck_1',
        tenantId: 't1',
        date: DateTime.utc(2026, 8, 30),
        inventory: {'p1|choc': 45, 'p2|vainilla': 30},
        damagedItems: {'p1|choc': 2},
      );

      final model = TruckLoadModel.fromEntity(entity);
      final map = model.toMap();
      final restored = TruckLoadModel.fromMap(map).toEntity();

      expect(restored.truckId, equals('truck_1'));
      expect(restored.inventory['p1|choc'], equals(45));
      expect(restored.damagedItems['p1|choc'], equals(2));
    });

    test('6. LedgerEntryModel & LedgerSnapshotModel: asientos y cierres contables', () {
      final entry = LedgerEntryEntity(
        id: 'led_1',
        tenantId: 't1',
        clientId: 'c1',
        date: DateTime.utc(2026, 8, 30, 9, 30),
        type: LedgerEntryType.saleDebt,
        referenceId: 'sale_101',
        amount: Money.fromCents(150000),
        description: 'Venta #101',
      );

      final entryRestored = LedgerEntryModel.fromMap(
        LedgerEntryModel.fromEntity(entry).toMap(),
      ).toEntity();
      expect(entryRestored.amount.cents, equals(150000));
      expect(entryRestored.balanceImpact.cents, equals(150000));

      final snapshot = LedgerSnapshot(
        tenantId: 't1',
        clientId: 'c1',
        closingDate: DateTime.utc(2026, 8, 30),
        balance: Money.fromCents(300000),
        lastEntryId: 'led_99',
        entryCount: 15,
      );

      final snapshotRestored = LedgerSnapshotModel.fromMap(
        LedgerSnapshotModel.fromEntity(snapshot).toMap(),
      ).toEntity();
      expect(snapshotRestored.balance.cents, equals(300000));
      expect(snapshotRestored.entryCount, equals(15));
    });

    test('7. CashSummaryModel: desglose de caja y separación físico vs transferencias', () {
      final entity = CashSummaryEntity(
        salesCash: Money.fromCents(200000),
        salesTransfer: Money.fromCents(100000),
        paymentsCash: Money.fromCents(50000),
        paymentsTransfer: Money.fromCents(25000),
        debtGenerated: Money.fromCents(40000),
        clientBreakdown: const [
          CashSummaryItem(
            clientId: 'c1',
            clientName: 'Don Pepe',
            cash: Money.fromCents(150000),
            transfer: Money.fromCents(50000),
          ),
        ],
      );

      final model = CashSummaryModel.fromEntity(
        entity,
        id: 'cs_1',
        tenantId: 't1',
        date: DateTime.utc(2026, 8, 30),
        closedAt: DateTime.utc(2026, 8, 30, 20, 0),
      );
      final restored = CashSummaryModel.fromMap(model.toMap()).toEntity();

      expect(restored.totalCash.cents, equals(250000));
      expect(restored.totalTransfer.cents, equals(125000));
      expect(restored.totalRevenue.cents, equals(375000));
      expect(restored.clientBreakdown.first.clientName, equals('Don Pepe'));
      expect(restored.clientBreakdown.first.total.cents, equals(200000));
    });

    test('8. Modelos Auxiliares: Zone, ClientGroup, Promo, PriceHistory, GroupInvoice, SyncQueue', () {
      final zone = ZoneEntity(id: 'z1', tenantId: 't1', name: 'Norte', cities: const ['Rosario', 'Funes']);
      expect(ZoneModel.fromMap(ZoneModel.fromEntity(zone).toMap()).toEntity().cities, contains('Funes'));

      final group = ClientGroupEntity(id: 'g1', tenantId: 't1', name: 'Red Kioscos', clientIds: const ['c1', 'c2']);
      expect(ClientGroupModel.fromMap(ClientGroupModel.fromEntity(group).toMap()).toEntity().clientIds.length, equals(2));

      final promo = PromotionEntity(
        id: 'pr1',
        tenantId: 't1',
        name: 'Combo Alfajores',
        requiredItems: const {'p1|choc': 3},
        discountPercentage: 10.0,
      );
      expect(PromotionModel.fromMap(PromotionModel.fromEntity(promo).toMap()).toEntity().discountPercentage, equals(10.0));

      final history = PriceHistoryModel.create(
        id: 'h1',
        tenantId: 't1',
        productId: 'p1',
        productName: 'Alfajor',
        variantName: 'Choc',
        oldPrice: Money.fromCents(1000),
        newPrice: Money.fromCents(1200),
        changedAt: DateTime.utc(2026, 8, 30),
      );
      expect(PriceHistoryModel.fromMap(history.toMap()).newPrice.cents, equals(1200));

      final invoice = GroupInvoiceModel.create(
        id: 'inv1',
        tenantId: 't1',
        groupId: 'g1',
        totalAmount: Money.fromCents(50000),
        invoicedAt: DateTime.utc(2026, 8, 30),
        saleIds: const ['s1', 's2'],
      );
      expect(GroupInvoiceModel.fromMap(invoice.toMap()).saleIds, contains('s1'));

      final sync = SyncQueueModel.create(
        id: 'sq1',
        tenantId: 't1',
        collectionName: 'clients',
        documentId: 'c1',
        operation: 'create',
        payload: {'name': 'Test'},
        createdAt: DateTime.utc(2026, 8, 30),
      );
      expect(SyncQueueModel.fromMap(sync.toMap()).payload['name'], equals('Test'));
    });
  });
}
