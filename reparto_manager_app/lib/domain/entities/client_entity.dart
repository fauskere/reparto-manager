// lib/domain/entities/client_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';

/// Clasificación comercial del cliente para la aplicación de listas de precios.
enum ClientType {
  /// Cliente estándar de reparto con lista de precios base.
  normal,

  /// Cliente institucional o de gran volumen con precios diferenciales.
  especial,

  /// Revendedor mayorista o distribuidor independiente.
  revendedor,
}

/// Estado de atención en la hoja de ruta y recorrido del día.
enum VisitStatus {
  /// Cliente atendido con venta o cobro registrado hoy.
  visited,

  /// Cliente aún no visitado en la jornada.
  notVisited,

  /// Cliente marcado en espera o postergado para más tarde.
  pending,
}

/// Entidad inmutable que representa un cliente en el sistema.
class ClientEntity {
  final String id;
  final String tenantId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final String zoneId;
  final ClientType type;

  /// Precios personalizados por variante. Clave: variantKey ("productId|variantName").
  final Map<String, Money> customPrices;
  final VisitStatus visitStatus;
  final Money balance;
  final Money? debtLimit;
  final bool isStore;
  final bool isActive;

  ClientEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.zoneId = '',
    this.type = ClientType.normal,
    Map<String, Money>? customPrices,
    this.visitStatus = VisitStatus.notVisited,
    this.balance = Money.zero,
    this.debtLimit,
    this.isStore = false,
    this.isActive = true,
  }) : customPrices = Map.unmodifiable(customPrices ?? const <String, Money>{});

  /// Crea un cliente validando los campos obligatorios.
  static Result<ClientEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    String zoneId = '',
    ClientType type = ClientType.normal,
    Map<String, Money>? customPrices,
    VisitStatus visitStatus = VisitStatus.notVisited,
    Money balance = Money.zero,
    Money? debtLimit,
    bool isStore = false,
    bool isActive = true,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || name.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'El id, tenantId y nombre del cliente son obligatorios y no pueden estar vacíos',
        ),
      );
    }

    return Result.ok(
      ClientEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        name: name.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
        notes: notes?.trim(),
        zoneId: zoneId.trim(),
        type: type,
        customPrices: customPrices,
        visitStatus: visitStatus,
        balance: balance,
        debtLimit: debtLimit,
        isStore: isStore,
        isActive: isActive,
      ),
    );
  }

  /// Retorna el precio asignado para una variante dada, o [fallbackPrice] si no tiene precio especial.
  Money getPriceForVariant(String variantKey, Money fallbackPrice) {
    return customPrices[variantKey] ?? fallbackPrice;
  }

  /// Indica si el cliente ha superado el límite de deuda configurado.
  bool get isDebtLimitExceeded {
    if (debtLimit == null) return false;
    return balance > debtLimit!;
  }

  ClientEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? phone,
    String? address,
    String? notes,
    String? zoneId,
    ClientType? type,
    Map<String, Money>? customPrices,
    VisitStatus? visitStatus,
    Money? balance,
    Money? debtLimit,
    bool? isStore,
    bool? isActive,
  }) {
    return ClientEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      zoneId: zoneId ?? this.zoneId,
      type: type ?? this.type,
      customPrices: customPrices ?? this.customPrices,
      visitStatus: visitStatus ?? this.visitStatus,
      balance: balance ?? this.balance,
      debtLimit: debtLimit ?? this.debtLimit,
      isStore: isStore ?? this.isStore,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          name == other.name &&
          phone == other.phone &&
          address == other.address &&
          notes == other.notes &&
          zoneId == other.zoneId &&
          type == other.type &&
          visitStatus == other.visitStatus &&
          balance == other.balance &&
          debtLimit == other.debtLimit &&
          isStore == other.isStore &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        name,
        phone,
        address,
        notes,
        zoneId,
        type,
        visitStatus,
        balance,
        debtLimit,
        isStore,
        isActive,
      );

  @override
  String toString() => 'ClientEntity(id: $id, name: $name, balance: $balance)';
}
