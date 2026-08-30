// test/domain/entities/ledger_entry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/entities/ledger_entry_entity.dart';

void main() {
  group('LedgerEntryEntity & LedgerSnapshot - Event Sourcing Contable', () {
    const tenantId = 'tenant_sucursal_central';
    const clientId = 'client_panaderia_sol';

    test('b) Un débito (venta) y un crédito (pago) se restan a la perfección dando el balance esperado', () {
      // 1. Venta a crédito de $10.000 (saleDebt)
      final saleEntry = LedgerEntryEntity(
        id: 'entry_001',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.utc(2026, 8, 30, 10, 0),
        type: LedgerEntryType.saleDebt,
        referenceId: 'ticket_1001',
        amount: Money.fromUnits(10000),
        description: 'Venta 10 cajas de alfajores',
      );

      // 2. Cobro posterior de $6.500 (paymentCredit)
      final paymentEntry = LedgerEntryEntity(
        id: 'entry_002',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.utc(2026, 8, 30, 14, 30),
        type: LedgerEntryType.paymentCredit,
        referenceId: 'recibo_501',
        amount: Money.fromUnits(6500),
        description: 'Pago en efectivo parcial',
      );

      // El balance se computa matemáticamente sin mutaciones manuales
      final balance = saleEntry.balanceImpact + paymentEntry.balanceImpact;

      // Deuda restante esperada: $3.500
      expect(balance.cents, equals(350000));
      expect(balance, equals(Money.fromUnits(3500)));
      expect(balance.formatted(), equals(r'$3.500'));
    });

    test('Directive 4: Venta con pago parcial registra 2 asientos independientes con auditoría total', () {
      // Venta total de $8.000 donde el cliente entrega $3.000 en mano en el acto
      final now = DateTime.utc(2026, 8, 30, 11, 15);

      // Asiento 1: Deuda total de la venta ($8.000)
      final saleEntry = LedgerEntryEntity(
        id: 'ledger_sale_201',
        tenantId: tenantId,
        clientId: clientId,
        date: now,
        type: LedgerEntryType.saleDebt,
        referenceId: 'ticket_201',
        amount: Money.fromUnits(8000),
        description: 'Venta mostrador ticket #201',
      );

      // Asiento 2: Cobranza inmediata en efectivo ($3.000)
      final partialPayment = LedgerEntryEntity(
        id: 'ledger_pay_201',
        tenantId: tenantId,
        clientId: clientId,
        date: now,
        type: LedgerEntryType.paymentCredit,
        referenceId: 'ticket_201_pago_efectivo',
        amount: Money.fromUnits(3000),
        description: 'Entrega inicial en efectivo ticket #201',
      );

      final entries = [saleEntry, partialPayment];

      // Verificación de impacto individual
      expect(saleEntry.balanceImpact, equals(Money.fromUnits(8000)));
      expect(partialPayment.balanceImpact, equals(Money.fromUnits(-3000)));

      // Verificación de balance neto auditado: $8.000 - $3.000 = $5.000
      var netBalance = Money.zero;
      for (final entry in entries) {
        netBalance = netBalance + entry.balanceImpact;
      }

      expect(netBalance, equals(Money.fromUnits(5000)));
      expect(netBalance.formatted(), equals(r'$5.000'));
    });

    test('c) Es físicamente imposible crear un asiento contable con monto negativo o IDs vacíos', () {
      final negativeResult = LedgerEntryEntity.create(
        id: 'entry_invalid',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.now(),
        type: LedgerEntryType.saleDebt,
        referenceId: 'ref_1',
        amount: Money.fromUnits(-100),
        description: 'Monto negativo ilegal',
      );

      expect(negativeResult.isFailure, isTrue);
      expect(negativeResult.failureOrNull, isA<NegativeAmountNotAllowedFailure>());

      final emptyIdResult = LedgerEntryEntity.create(
        id: '',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.now(),
        type: LedgerEntryType.saleDebt,
        referenceId: 'ref_2',
        amount: Money.fromUnits(100),
        description: 'ID vacío',
      );

      expect(emptyIdResult.isFailure, isTrue);
      expect(emptyIdResult.failureOrNull, isA<InvalidMoneyAmountFailure>());
    });

    test('Ajustes contables (crédito y débito) modifican el saldo con precisión', () {
      // Ajuste a favor (descuento / bonificación posterior de $500)
      final bonusCredit = LedgerEntryEntity(
        id: 'adj_01',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.utc(2026, 8, 30, 16, 0),
        type: LedgerEntryType.adjustmentCredit,
        referenceId: 'nc_001',
        amount: Money.fromUnits(500),
        description: 'Bonificación por mercadería fallada',
      );

      // Ajuste deudor (recargo por flete o mora de $200)
      final chargeDebt = LedgerEntryEntity(
        id: 'adj_02',
        tenantId: tenantId,
        clientId: clientId,
        date: DateTime.utc(2026, 8, 30, 16, 30),
        type: LedgerEntryType.adjustmentDebt,
        referenceId: 'nd_001',
        amount: Money.fromUnits(200),
        description: 'Recargo de flete especial',
      );

      expect(bonusCredit.balanceImpact, equals(Money.fromUnits(-500)));
      expect(chargeDebt.balanceImpact, equals(Money.fromUnits(200)));
    });

    test('LedgerSnapshot: Cierres periódicos consolidan balances y procesan asientos subsiguientes', () {
      // Snapshot al 31 de Julio con saldo consolidado de $12.000 tras 45 movimientos
      final julySnapshot = LedgerSnapshot(
        tenantId: tenantId,
        clientId: clientId,
        closingDate: DateTime.utc(2026, 7, 31, 23, 59, 59),
        balance: Money.fromUnits(12000),
        lastEntryId: 'entry_july_045',
        entryCount: 45,
      );

      // En Agosto solo se computan los eventos nuevos (sin reprocesar los 45 anteriores)
      final augustEntries = [
        LedgerEntryEntity(
          id: 'entry_aug_001',
          tenantId: tenantId,
          clientId: clientId,
          date: DateTime.utc(2026, 8, 5),
          type: LedgerEntryType.paymentCredit,
          referenceId: 'rec_aug_01',
          amount: Money.fromUnits(10000),
          description: 'Cobranza mensual',
        ),
        LedgerEntryEntity(
          id: 'entry_aug_002',
          tenantId: tenantId,
          clientId: clientId,
          date: DateTime.utc(2026, 8, 12),
          type: LedgerEntryType.saleDebt,
          referenceId: 'tick_aug_01',
          amount: Money.fromUnits(4000),
          description: 'Nueva entrega de mercadería',
        ),
      ];

      // Saldo resultante: $12.000 - $10.000 + $4.000 = $6.000
      final updatedBalance = julySnapshot.computeBalanceWithEntries(augustEntries);

      expect(updatedBalance, equals(Money.fromUnits(6000)));
      expect(updatedBalance.formatted(), equals(r'$6.000'));
    });
  });
}
