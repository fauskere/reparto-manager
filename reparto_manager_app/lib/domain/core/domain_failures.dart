// lib/domain/core/domain_failures.dart
// Capa de Dominio Puro - Reparto-Manager V2

/// Clase base inmutable para todos los fallos del dominio.
abstract class DomainFailure {
  final String message;
  final Object? details;

  const DomainFailure(this.message, [this.details]);

  @override
  String toString() => '$runtimeType: $message${details != null ? ' (Detalles: $details)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          details == other.details;

  @override
  int get hashCode => Object.hash(runtimeType, message, details);
}

/// Fallo cuando un monto financiero es inválido (división por cero, NaN, infinito, etc.).
class InvalidMoneyAmountFailure extends DomainFailure {
  const InvalidMoneyAmountFailure(super.message, [super.details]);
}

/// Fallo cuando una operación rechaza valores negativos por regla de negocio.
class NegativeAmountNotAllowedFailure extends DomainFailure {
  const NegativeAmountNotAllowedFailure(super.message, [super.details]);
}

/// Fallo cuando existe una inconsistencia o desborde en el cálculo del balance.
class BalanceCalculationFailure extends DomainFailure {
  const BalanceCalculationFailure(super.message, [super.details]);
}

/// Fallo cuando una entidad viola una regla o invariante de negocio.
class EntityValidationFailure extends DomainFailure {
  const EntityValidationFailure(super.message, [super.details]);
}
