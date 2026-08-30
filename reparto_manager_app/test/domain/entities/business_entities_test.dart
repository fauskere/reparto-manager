// test/domain/entities/business_entities_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/client_group_entity.dart';
import 'package:reparto_manager_app/domain/entities/payment_entity.dart';
import 'package:reparto_manager_app/domain/entities/promotion_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';
import 'package:reparto_manager_app/domain/entities/zone_entity.dart';

void main() {
  group('Entidades Inmutables de Negocio V2 - Consolidación Forense', () {
    const tenantId = 'tenant_sucursal_central';

    test('SaleEntity valida invariante con pago mixto, exchanges y promociones', () {
      final items = [
        SaleItemEntity(
          productId: 'p1',
          variantName: 'Estándar',
          productName: 'Alfajor Triple',
          quantity: 10,
          unitPrice: Money.fromUnits(1000),
          unitCost: Money.fromUnits(600),
        ),
      ];
      final exchanges = [
        const ExchangeItemEntity(
          productId: 'p1',
          variantName: 'Estándar',
          productName: 'Alfajor Triple',
          quantity: 2,
        ),
      ];

      final saleResult = SaleEntity.create(
        id: 'sale_1',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco Central',
        ticketNumber: 101,
        date: DateTime.utc(2026, 8, 30, 12, 0),
        items: items,
        exchanges: exchanges,
        appliedPromos: ['PROMO_ALFAJOR_10'],
        subtotal: Money.fromUnits(10000),
        totalDiscount: Money.fromUnits(1000),
        paymentMethod: PaymentMethod.mixed,
        cashPaid: Money.fromUnits(4000),
        transferPaid: Money.fromUnits(2000),
        previousBalance: Money.fromUnits(5000),
        remainingBalance: Money.fromUnits(8000),
      );

      expect(saleResult.isSuccess, isTrue);
      final sale = saleResult.valueOrNull!;
      expect(sale.total, equals(Money.fromUnits(9000)));
      expect(sale.debtGenerated, equals(Money.fromUnits(3000)));
      expect(sale.exchanges.length, equals(1));
      expect(sale.appliedPromos, contains('PROMO_ALFAJOR_10'));
      expect(sale.previousBalance, equals(Money.fromUnits(5000)));
      expect(sale.remainingBalance, equals(Money.fromUnits(8000)));
      expect(
        sale.cashPaid + sale.transferPaid + sale.debtGenerated,
        equals(sale.total),
      );
    });

    test('SaleEntity rechaza que totalDiscount supere subtotal o pago supere total', () {
      final items = [
        SaleItemEntity(
          productId: 'p1',
          variantName: 'Estándar',
          productName: 'Alfajor Triple',
          quantity: 2,
          unitPrice: Money.fromUnits(1000),
          unitCost: Money.fromUnits(600),
        ),
      ];

      final invalidDiscount = SaleEntity.create(
        id: 'sale_inv_desc',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco',
        ticketNumber: 102,
        date: DateTime.now(),
        items: items,
        subtotal: Money.fromUnits(2000),
        totalDiscount: Money.fromUnits(2500),
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.zero,
        transferPaid: Money.zero,
      );
      expect(invalidDiscount.isFailure, isTrue);

      final overpaid = SaleEntity.create(
        id: 'sale_overpaid',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco',
        ticketNumber: 103,
        date: DateTime.now(),
        items: items,
        subtotal: Money.fromUnits(2000),
        totalDiscount: Money.zero,
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.fromUnits(2500),
        transferPaid: Money.zero,
      );
      expect(overpaid.isFailure, isTrue);
    });

    test('ClientEntity incorpora campos operativos de V1 e inmutabilidad', () {
      final client = ClientEntity(
        id: 'cli_01',
        tenantId: tenantId,
        name: 'Mario Rossi',
        nickname: 'Kiosco Mario',
        city: 'Santa Fe',
        isOpenContinuous: true,
        groupId: 'group_kioscos_centro',
        customPrices: {'p1|Estándar': Money.fromUnits(900)},
      );

      expect(client.nickname, equals('Kiosco Mario'));
      expect(client.city, equals('Santa Fe'));
      expect(client.isOpenContinuous, isTrue);
      expect(client.groupId, equals('group_kioscos_centro'));
      expect(() => client.customPrices['p1|Estándar'] = Money.zero, throwsUnsupportedError);
    });

    test('ZoneEntity y ClientGroupEntity manejan listas inmutables', () {
      final zone = ZoneEntity(
        id: 'z_lunes',
        tenantId: tenantId,
        name: 'Lunes Zona Norte',
        cities: ['Santa Fe', 'Recreo'],
      );
      expect(zone.cities.length, equals(2));
      expect(() => (zone.cities as dynamic).add('Esperanza'), throwsUnsupportedError);

      final group = ClientGroupEntity(
        id: 'grp_01',
        tenantId: tenantId,
        name: 'Kioscos Belgrano',
        clientIds: ['c1', 'c2'],
      );
      expect(group.clientIds.length, equals(2));
      expect(() => (group.clientIds as dynamic).add('c3'), throwsUnsupportedError);
    });

    test('PromotionEntity evalúa elegibilidad de combo en carrito', () {
      final promo = PromotionEntity(
        id: 'promo_combo',
        tenantId: tenantId,
        name: 'Combo Desayuno',
        requiredItems: {
          'p_cafe|250g': 2,
          'p_galletas|Pack': 1,
        },
        discountPercentage: 15.0,
      );

      expect(promo.isEligible({'p_cafe|250g': 1}), isFalse);
      expect(promo.isEligible({'p_cafe|250g': 2, 'p_galletas|Pack': 1}), isTrue);
      expect(promo.isEligible({'p_cafe|250g': 5, 'p_galletas|Pack': 2}), isTrue);
    });

    test('PaymentEntity soporta cobro mixto y valida que monto sea positivo', () {
      final mixedPayment = PaymentEntity.create(
        id: 'pay_m1',
        tenantId: tenantId,
        clientId: 'c1',
        receiptNumber: 501,
        date: DateTime.now(),
        cashPaid: Money.fromUnits(3000),
        transferPaid: Money.fromUnits(2000),
        previousBalance: Money.fromUnits(10000),
        remainingBalance: Money.fromUnits(5000),
      );

      expect(mixedPayment.isSuccess, isTrue);
      final payment = mixedPayment.valueOrNull!;
      expect(payment.amount, equals(Money.fromUnits(5000)));
      expect(payment.method, equals(PaymentMethod.mixed));
      expect(payment.previousBalance, equals(Money.fromUnits(10000)));
      expect(payment.remainingBalance, equals(Money.fromUnits(5000)));

      final zeroPayment = PaymentEntity.create(
        id: 'pay_zero',
        tenantId: tenantId,
        clientId: 'c1',
        receiptNumber: 502,
        date: DateTime.now(),
        cashPaid: Money.zero,
        transferPaid: Money.zero,
      );
      expect(zeroPayment.isFailure, isTrue);
    });

    test('TruckLoadEntity permite registrar ventas con stock negativo sin bloquear', () {
      final initialLoad = TruckLoadEntity(
        truckId: 'truck_01',
        tenantId: tenantId,
        date: DateTime.now(),
        inventory: {'p1|Estándar': 3},
      );

      final soldLoad = initialLoad.applySale(
        variantKey: 'p1|Estándar',
        quantity: 10,
      );

      expect(soldLoad.getStock('p1|Estándar'), equals(-7));
      expect(soldLoad.hasNegativeStock, isTrue);
      expect(soldLoad.negativeStockVariantKeys, contains('p1|Estándar'));
    });
  });
}
