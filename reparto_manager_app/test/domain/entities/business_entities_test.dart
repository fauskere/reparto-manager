// test/domain/entities/business_entities_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/payment_entity.dart';
import 'package:reparto_manager_app/domain/entities/product_entity.dart';
import 'package:reparto_manager_app/domain/entities/sale_entity.dart';
import 'package:reparto_manager_app/domain/entities/truck_load_entity.dart';

void main() {
  group('Entidades Inmutables de Negocio V2', () {
    const tenantId = 'tenant_sucursal_central';

    test('a) SaleEntity valida invariante: cashPaid + transferPaid + debtGenerated == total', () {
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

      // Total = 10 * 1000 = $10.000. Pago mixto: $4.000 efectivo + $2.500 transferencia = $6.500 abonado
      // Deuda esperada = $3.500
      final saleResult = SaleEntity.create(
        id: 'sale_1',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco Central',
        ticketNumber: 101,
        date: DateTime.utc(2026, 8, 30, 12, 0),
        items: items,
        subtotal: Money.fromUnits(10000),
        totalDiscount: Money.zero,
        paymentMethod: PaymentMethod.mixed,
        cashPaid: Money.fromUnits(4000),
        transferPaid: Money.fromUnits(2500),
      );

      expect(saleResult.isSuccess, isTrue);
      final sale = saleResult.valueOrNull!;
      expect(sale.total, equals(Money.fromUnits(10000)));
      expect(sale.debtGenerated, equals(Money.fromUnits(3500)));
      expect(
        sale.cashPaid + sale.transferPaid + sale.debtGenerated,
        equals(sale.total),
      );
    });

    test('Directive 2: SaleEntity rechaza que totalDiscount supere al subtotal', () {
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

      final invalidDiscountResult = SaleEntity.create(
        id: 'sale_invalid_desc',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco Central',
        ticketNumber: 102,
        date: DateTime.now(),
        items: items,
        subtotal: Money.fromUnits(2000),
        totalDiscount: Money.fromUnits(2500), // Descuento > Subtotal
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.zero,
        transferPaid: Money.zero,
      );

      expect(invalidDiscountResult.isFailure, isTrue);
    });

    test('Directive 3: SaleEntity rechaza que cashPaid + transferPaid supere el total', () {
      final items = [
        SaleItemEntity(
          productId: 'p1',
          variantName: 'Estándar',
          productName: 'Alfajor Triple',
          quantity: 1,
          unitPrice: Money.fromUnits(1000),
          unitCost: Money.fromUnits(600),
        ),
      ];

      final overpaidResult = SaleEntity.create(
        id: 'sale_overpaid',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Kiosco Central',
        ticketNumber: 103,
        date: DateTime.now(),
        items: items,
        subtotal: Money.fromUnits(1000),
        totalDiscount: Money.zero,
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.fromUnits(1200), // Pagó 1200 en venta de 1000
        transferPaid: Money.zero,
      );

      expect(overpaidResult.isFailure, isTrue);
    });

    test('b) Las colecciones internas son inmutables (no modificables externamente)', () {
      final items = [
        SaleItemEntity(
          productId: 'p1',
          variantName: 'Estándar',
          productName: 'Alfajor Triple',
          quantity: 1,
          unitPrice: Money.fromUnits(500),
          unitCost: Money.fromUnits(300),
        ),
      ];

      final sale = SaleEntity(
        id: 's_imm',
        tenantId: tenantId,
        clientId: 'c1',
        clientName: 'Cliente 1',
        ticketNumber: 1,
        date: DateTime.now(),
        items: items,
        subtotal: Money.fromUnits(500),
        totalDiscount: Money.zero,
        total: Money.fromUnits(500),
        paymentMethod: PaymentMethod.cash,
        cashPaid: Money.fromUnits(500),
        transferPaid: Money.zero,
        debtGenerated: Money.zero,
      );

      expect(() => (sale.items as dynamic).add(items.first), throwsUnsupportedError);

      final client = ClientEntity(
        id: 'cl_1',
        tenantId: tenantId,
        name: 'Don Pepe',
        customPrices: {'p1|Estándar': Money.fromUnits(450)},
      );

      expect(() => client.customPrices['p1|Estándar'] = Money.fromUnits(400), throwsUnsupportedError);
    });

    test('c) Cálculo de subtotales y margen de ganancia con Money en SaleItemEntity', () {
      final item = SaleItemEntity(
        productId: 'prod_gaseosa',
        variantName: 'Pack x6',
        productName: 'Gaseosa Cola',
        quantity: 5,
        unitPrice: Money.fromUnits(3000),
        unitCost: Money.fromUnits(2000),
        discount: Money.fromUnits(1000), // $1.000 de descuento global en el renglón
      );

      // Subtotal = (5 * 3000) - 1000 = 15000 - 1000 = $14.000
      expect(item.subtotal, equals(Money.fromUnits(14000)));

      // Total Cost = 5 * 2000 = $10.000
      expect(item.totalCost, equals(Money.fromUnits(10000)));

      // Profit = 14000 - 10000 = $4.000
      expect(item.profit, equals(Money.fromUnits(4000)));
    });

    test('d) Formato y consistencia de variantKey ("productId|variantName") en Product y Client', () {
      const variant = ProductVariant(
        productId: 'prod_alfajor',
        variantName: 'Caja x12',
        basePrice: Money.fromCents(1200000), // $12.000
        costPrice: Money.fromCents(800000),  // $8.000
      );

      expect(variant.variantKey, equals('prod_alfajor|Caja x12'));
      expect(variant.unitMargin, equals(Money.fromUnits(4000)));

      // Directive 1: ClientEntity asigna precio especial usando el variantKey
      final client = ClientEntity(
        id: 'cli_especial',
        tenantId: tenantId,
        name: 'Mayorista Sol',
        type: ClientType.especial,
        customPrices: {
          variant.variantKey: Money.fromUnits(10500),
        },
      );

      // Consulta de precio especial por variantKey
      final resolvedPrice = client.getPriceForVariant(
        variant.variantKey,
        variant.basePrice,
      );
      expect(resolvedPrice, equals(Money.fromUnits(10500)));

      // Si no existe precio para otra variante, retorna el fallback
      final fallbackPrice = client.getPriceForVariant(
        'prod_alfajor|Caja x24',
        Money.fromUnits(22000),
      );
      expect(fallbackPrice, equals(Money.fromUnits(22000)));
    });

    test('Directive 4: TruckLoadEntity permite registrar ventas con stock negativo sin bloquear', () {
      final initialLoad = TruckLoadEntity(
        truckId: 'truck_principal',
        tenantId: tenantId,
        date: DateTime.now(),
        inventory: {
          'prod_agua|600ml': 2, // Solo hay 2 botellas cargadas registradas
        },
      );

      expect(initialLoad.hasNegativeStock, isFalse);

      // Se venden 5 botellas en la calle (descuadre de carga matutina)
      final loadAfterSale = initialLoad.applySale(
        variantKey: 'prod_agua|600ml',
        quantity: 5,
      );

      // El stock queda en -3, no crashea ni bloquea la venta
      expect(loadAfterSale.getStock('prod_agua|600ml'), equals(-3));
      expect(loadAfterSale.hasNegativeStock, isTrue);
      expect(loadAfterSale.negativeStockVariantKeys, contains('prod_agua|600ml'));
    });

    test('PaymentEntity valida que el monto sea estrictamente mayor a cero', () {
      final validPayment = PaymentEntity.create(
        id: 'pay_01',
        tenantId: tenantId,
        clientId: 'cli_01',
        receiptNumber: 1001,
        date: DateTime.now(),
        amount: Money.fromUnits(5000),
        method: PaymentMethod.cash,
      );

      expect(validPayment.isSuccess, isTrue);

      final zeroPayment = PaymentEntity.create(
        id: 'pay_02',
        tenantId: tenantId,
        clientId: 'cli_01',
        receiptNumber: 1002,
        date: DateTime.now(),
        amount: Money.zero,
        method: PaymentMethod.cash,
      );

      expect(zeroPayment.isFailure, isTrue);
    });
  });
}
