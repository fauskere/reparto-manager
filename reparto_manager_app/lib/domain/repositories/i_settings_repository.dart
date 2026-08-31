// lib/domain/repositories/i_settings_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import '../core/domain_failures.dart';
import '../core/result.dart';

/// Contrato abstracto para la gestión de configuraciones y preferencias del sistema.
abstract class ISettingsRepository {
  /// Obtiene el valor de una clave de configuración específica para el tenant.
  Future<Result<String?, DomainFailure>> getSetting(
    String tenantId,
    String key,
  );

  /// Guarda o actualiza el valor de una clave de configuración.
  Future<Result<void, DomainFailure>> setSetting(
    String tenantId,
    String key,
    String value,
  );

  /// Obtiene todas las claves de configuración configuradas para el tenant.
  Future<Result<Map<String, String>, DomainFailure>> getAllSettings(
    String tenantId,
  );

  /// Elimina una clave de configuración.
  Future<Result<void, DomainFailure>> deleteSetting(
    String tenantId,
    String key,
  );
}
