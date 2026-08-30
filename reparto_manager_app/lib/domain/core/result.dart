// lib/domain/core/result.dart
// Capa de Dominio Puro - Reparto-Manager V2

/// Estructura funcional inmutable para representar el éxito o fracaso de una operación.
/// Evita el uso de excepciones no controladas en el flujo de negocio.
sealed class Result<S, F> {
  const Result();

  /// Constructor de conveniencia para un resultado exitoso.
  factory Result.ok(S value) = Success<S, F>;

  /// Constructor de conveniencia para un resultado fallido.
  factory Result.fail(F error) = Failure<S, F>;

  /// Indica si la operación fue exitosa.
  bool get isSuccess => this is Success<S, F>;

  /// Indica si la operación falló.
  bool get isFailure => this is Failure<S, F>;

  /// Retorna el valor si fue exitoso, o null si falló.
  S? get valueOrNull => switch (this) {
        Success<S, F>(:final value) => value,
        Failure<S, F>() => null,
      };

  /// Retorna el error si falló, o null si fue exitoso.
  F? get failureOrNull => switch (this) {
        Success<S, F>() => null,
        Failure<S, F>(:final error) => error,
      };

  /// Ejecuta [onSuccess] si fue exitoso, o [onFailure] si falló.
  R fold<R>(
    R Function(F failure) onFailure,
    R Function(S success) onSuccess,
  ) {
    return switch (this) {
      Success<S, F>(:final value) => onSuccess(value),
      Failure<S, F>(:final error) => onFailure(error),
    };
  }

  /// Transforma el valor exitoso mediante [mapper] preservando el fallo.
  Result<T, F> map<T>(T Function(S value) mapper) {
    return switch (this) {
      Success<S, F>(:final value) => Success<T, F>(mapper(value)),
      Failure<S, F>(:final error) => Failure<T, F>(error),
    };
  }

  /// Transforma el error mediante [mapper] preservando el éxito.
  Result<S, T> mapFailure<T>(T Function(F failure) mapper) {
    return switch (this) {
      Success<S, F>(:final value) => Success<S, T>(value),
      Failure<S, F>(:final error) => Failure<S, T>(mapper(error)),
    };
  }
}

/// Representa una operación exitosa con su respectivo valor inmutable [value].
final class Success<S, F> extends Result<S, F> {
  final S value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<S, F> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Success($value)';
}

/// Representa una operación fallida con su respectivo error [error].
final class Failure<S, F> extends Result<S, F> {
  final F error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<S, F> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString() => 'Failure($error)';
}
