// test/domain/core/money_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';

void main() {
  group('Money - Primitivas Matemáticas y Precisión Bancaria', () {
    test('a) No existen errores de precisión decimal en sumas sucesivas de centavos', () {
      // 0.1 + 0.2 en double IEEE-754 da 0.30000000000000004
      // En Money debe dar exactamente $0,30 (30 centavos)
      final m1 = Money.fromUnits(0.1);
      final m2 = Money.fromUnits(0.2);
      final result = m1 + m2;

      expect(result.cents, equals(30));
      expect(result.toDouble, equals(0.30));
      expect(result.formatted(forceDecimals: true), equals(r'$0,30'));
    });

    test('Suma acumulativa de 100 valores de 1 centavo da exactamente 1 peso (100 centavos)', () {
      var total = Money.zero;
      final oneCent = const Money.fromCents(1);

      for (var i = 0; i < 100; i++) {
        total = total + oneCent;
      }

      expect(total.cents, equals(100));
      expect(total, equals(const Money.fromCents(100)));
      expect(total.formatted(), equals(r'$1'));
    });

    test('Directive 1: fromUnits evita la trampa de truncamiento de toInt()', () {
      // Casos clásicos donde (x * 100).toInt() falla por coma flotante (ej: 0.29 * 100 = 28.9999... -> toInt() = 28)
      final m1 = Money.fromUnits(0.29);
      expect(m1.cents, equals(29));

      final m2 = Money.fromUnits(0.57);
      expect(m2.cents, equals(57));

      final m3 = Money.fromUnits(19.99);
      expect(m3.cents, equals(1999));
    });

    test('Operaciones básicas: suma, resta y multiplicación escalar', () {
      final a = Money.fromUnits(1500);
      final b = Money.fromUnits(350);

      expect((a + b).cents, equals(185000));
      expect((a - b).cents, equals(115000));
      expect((b * 3).cents, equals(105000));
    });

    test('Directive 2: División segura maneja división por cero con InvalidMoneyAmountFailure sin crashear', () {
      final amount = Money.fromUnits(1000);
      final result = amount.divide(0);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<InvalidMoneyAmountFailure>());
      expect(result.valueOrNull, isNull);
    });

    test('División con redondeo bancario Half-Up funciona con precisión', () {
      final amount = const Money.fromCents(100); // $1.00
      // 100 / 3 = 33.333 -> 33 centavos
      final result1 = amount.divide(3);
      expect(result1.isSuccess, isTrue);
      expect(result1.valueOrNull!.cents, equals(33));

      // 100 / 6 = 16.666 -> 17 centavos (redondeo hacia arriba)
      final result2 = amount.divide(6);
      expect(result2.isSuccess, isTrue);
      expect(result2.valueOrNull!.cents, equals(17));
    });

    test('c) Es físicamente imposible crear montos corruptos (NaN / Infinito)', () {
      expect(() => Money.fromUnits(double.nan), throwsArgumentError);
      expect(() => Money.fromUnits(double.infinity), throwsArgumentError);

      final safeTry = Money.tryFromUnits(double.nan);
      expect(safeTry.isFailure, isTrue);
      expect(safeTry.failureOrNull, isA<InvalidMoneyAmountFailure>());
    });

    test('Comparadores matemáticos y signos', () {
      final positive = Money.fromUnits(500);
      final zero = Money.zero;
      final negative = Money.fromUnits(-500);

      expect(positive.isPositive, isTrue);
      expect(positive.isNegative, isFalse);
      expect(zero.isZero, isTrue);
      expect(negative.isNegative, isTrue);

      expect(positive > zero, isTrue);
      expect(negative < zero, isTrue);
      expect(positive >= const Money.fromCents(50000), isTrue);
      expect(negative.abs(), equals(positive));
    });

    test('Directive 3: Formateo de Money en estándar comercial argentino', () {
      // Si cents termina en 00, formatea como entero limpio
      final roundThousand = Money.fromUnits(1250);
      expect(roundThousand.formatted(), equals(r'$1.250'));
      expect(roundThousand.formatted(forceDecimals: true), equals(r'$1.250,00'));

      // Con centavos residuales muestra los dos decimales con coma
      final withDecimals = const Money.fromCents(125050);
      expect(withDecimals.formatted(), equals(r'$1.250,50'));

      // Millón
      final million = Money.fromUnits(1000000);
      expect(million.formatted(), equals(r'$1.000.000'));

      // Negativo
      final negativeMoney = Money.fromUnits(-750);
      expect(negativeMoney.formatted(), equals(r'-$750'));
      expect(negativeMoney.formatted(forceDecimals: true), equals(r'-$750,00'));

      // Cero
      expect(Money.zero.formatted(), equals(r'$0'));
      expect(Money.zero.formatted(forceDecimals: true), equals(r'$0,00'));
    });
  });
}
