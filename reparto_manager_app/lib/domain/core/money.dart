// lib/domain/core/money.dart
// Capa de Dominio Puro - Reparto-Manager V2

import 'domain_failures.dart';
import 'result.dart';

/// Value Object inmutable para representar montos monetarios exactos.
///
/// Almacena el valor en centavos enteros ([cents]) para eliminar los errores
/// de redondeo inherentes a la representación de punto flotante binario (IEEE 754).
class Money implements Comparable<Money> {
  /// Valor exacto del monto representado en centavos enteros.
  final int cents;

  /// Constructor constante a partir de centavos enteros.
  const Money(this.cents);

  /// Constructor constante a partir de centavos enteros.
  const Money.fromCents(this.cents);

  /// Constructor a partir de unidades monetarias estándar (ej: pesos).
  ///
  /// Utiliza estrictamente [(units * 100).round()] para evitar la pérdida
  /// de precisión por truncamiento de coma flotante binaria.
  factory Money.fromUnits(num units) {
    if (units.isNaN || units.isInfinite) {
      throw ArgumentError('Las unidades deben ser un número finito: $units');
    }
    return Money.fromCents((units * 100).round());
  }

  /// Constructor seguro a partir de unidades. Retorna [Result] para evitar excepciones.
  static Result<Money, DomainFailure> tryFromUnits(num units) {
    if (units.isNaN || units.isInfinite) {
      return Result.fail(
        InvalidMoneyAmountFailure('Las unidades deben ser un número finito', units),
      );
    }
    return Result.ok(Money.fromCents((units * 100).round()));
  }

  /// Valor monetario neutro ($0).
  static const Money zero = Money.fromCents(0);

  /// Suma matemática exacta de dos montos monetarios.
  Money operator +(Money other) => Money.fromCents(cents + other.cents);

  /// Resta matemática exacta de dos montos monetarios.
  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  /// Multiplicación exacta por una cantidad o factor escalar con redondeo bancario Half-Up.
  Money operator *(num multiplier) {
    if (multiplier.isNaN || multiplier.isInfinite) {
      throw ArgumentError('El multiplicador debe ser un número finito: $multiplier');
    }
    return Money.fromCents((cents * multiplier).round());
  }

  /// División segura con redondeo bancario Half-Up.
  ///
  /// Si el divisor es 0 o un valor no numérico, retorna [InvalidMoneyAmountFailure]
  /// en lugar de generar un crasheo en la aplicación.
  Result<Money, DomainFailure> divide(num divisor) {
    if (divisor == 0 || divisor.isNaN || divisor.isInfinite) {
      return Result.fail(
        InvalidMoneyAmountFailure(
          'No es posible dividir un monto monetario por cero o valor inválido',
          divisor,
        ),
      );
    }
    final resultCents = (cents / divisor).round();
    return Result.ok(Money.fromCents(resultCents));
  }

  /// Retorna el valor absoluto del monto monetario.
  Money abs() => Money.fromCents(cents.abs());

  /// Retorna el monto con signo invertido.
  Money operator -() => Money.fromCents(-cents);

  /// Retorna el valor decimal en unidades estándar (solo para display o exportación).
  double get toDouble => cents / 100.0;

  /// Retorna la parte entera en unidades estándar.
  int get integerUnits => cents ~/ 100;

  /// Indica si el monto es exactamente igual a cero.
  bool get isZero => cents == 0;

  /// Indica si el monto es estrictamente mayor a cero.
  bool get isPositive => cents > 0;

  /// Indica si el monto es estrictamente menor a cero.
  bool get isNegative => cents < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && cents == other.cents;

  @override
  int get hashCode => cents.hashCode;

  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  /// Formatea el monto al estándar comercial argentino ($ con miles en punto y centavos en coma).
  ///
  /// Si [forceDecimals] es false (por defecto) y el monto no posee centavos residuales
  /// ([cents] termina en 00), se formatea como entero limpio (ej: "$1.250").
  /// Si posee centavos residuales o [forceDecimals] es true, se añaden los 2 decimales (ej: "$1.250,50").
  String formatted({bool includeSymbol = true, bool forceDecimals = false}) {
    final isNeg = cents < 0;
    final absCents = cents.abs();
    final intPart = absCents ~/ 100;
    final decimalPart = absCents % 100;

    final formattedInt = _formatIntegerThousands(intPart);
    final String numberString;

    if (decimalPart == 0 && !forceDecimals) {
      numberString = formattedInt;
    } else {
      final paddedDecimals = decimalPart.toString().padLeft(2, '0');
      numberString = '$formattedInt,$paddedDecimals';
    }

    final sign = isNeg ? '-' : '';
    final symbol = includeSymbol ? '\$' : '';
    return '$sign$symbol$numberString';
  }

  /// Inserta puntos (.) separadores de miles de forma pura sin dependencias externas.
  static String _formatIntegerThousands(int value) {
    final str = value.toString();
    final len = str.length;
    final buffer = StringBuffer();
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  String toString() => formatted();
}
