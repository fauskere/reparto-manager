// lib/data/models/client_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/core/money.dart';
import '../../domain/entities/client_entity.dart';

/// Modelo de datos para la tabla SQLite `clients`.
/// Convierte bidireccionalmente entre [ClientEntity] y mapas SQLite.
class ClientModel {
  final String id;
  final String tenantId;
  final String name;
  final String nickname;
  final String? phone;
  final String city;
  final String? address;
  final String zoneId;
  final String clientType;
  final String visitStatus;
  final int isStore;
  final int isOpenContinuous;
  final String? groupId;
  final String? customPricesJson;
  final int balanceCents;
  final int debtLimitCents;
  final int isActive;

  const ClientModel({
    required this.id,
    required this.tenantId,
    required this.name,
    this.nickname = '',
    this.phone,
    this.city = '',
    this.address,
    this.zoneId = '',
    required this.clientType,
    required this.visitStatus,
    required this.isStore,
    required this.isOpenContinuous,
    this.groupId,
    this.customPricesJson,
    required this.balanceCents,
    required this.debtLimitCents,
    required this.isActive,
  });

  /// Crea un [ClientModel] a partir de una [ClientEntity].
  factory ClientModel.fromEntity(ClientEntity entity) {
    final pricesMap = <String, int>{};
    entity.customPrices.forEach((key, money) {
      pricesMap[key] = money.cents;
    });

    return ClientModel(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      nickname: entity.nickname,
      phone: entity.phone,
      city: entity.city,
      address: entity.address,
      zoneId: entity.zoneId,
      clientType: entity.type.name,
      visitStatus: entity.visitStatus.name,
      isStore: entity.isStore ? 1 : 0,
      isOpenContinuous: entity.isOpenContinuous ? 1 : 0,
      groupId: entity.groupId,
      customPricesJson: pricesMap.isNotEmpty ? jsonEncode(pricesMap) : null,
      balanceCents: entity.balance.cents,
      debtLimitCents: entity.debtLimit?.cents ?? 0,
      isActive: entity.isActive ? 1 : 0,
    );
  }

  /// Convierte este modelo a una [ClientEntity] de dominio puro.
  ClientEntity toEntity() {
    final Map<String, Money> customPrices = {};
    if (customPricesJson != null && customPricesJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(customPricesJson!) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        customPrices[key] = Money.fromCents((value as num).toInt());
      });
    }

    return ClientEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      nickname: nickname,
      phone: phone,
      city: city,
      address: address,
      zoneId: zoneId,
      type: _parseClientType(clientType),
      visitStatus: _parseVisitStatus(visitStatus),
      isStore: isStore == 1,
      isOpenContinuous: isOpenContinuous == 1,
      groupId: groupId,
      customPrices: customPrices,
      balance: Money.fromCents(balanceCents),
      debtLimit: debtLimitCents > 0 ? Money.fromCents(debtLimitCents) : null,
      isActive: isActive == 1,
    );
  }

  /// Crea un [ClientModel] desde una fila de SQLite.
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      nickname: (map['nickname'] as String?) ?? '',
      phone: map['phone'] as String?,
      city: (map['city'] as String?) ?? '',
      address: map['address'] as String?,
      zoneId: (map['zoneId'] as String?) ?? '',
      clientType: map['clientType'] as String,
      visitStatus: map['visitStatus'] as String,
      isStore: (map['isStore'] as num).toInt(),
      isOpenContinuous: (map['isOpenContinuous'] as num).toInt(),
      groupId: map['groupId'] as String?,
      customPricesJson: map['customPricesJson'] as String?,
      balanceCents: (map['balanceCents'] as num).toInt(),
      debtLimitCents: (map['debtLimitCents'] as num).toInt(),
      isActive: (map['isActive'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'nickname': nickname,
      'phone': phone,
      'city': city,
      'address': address,
      'zoneId': zoneId,
      'clientType': clientType,
      'visitStatus': visitStatus,
      'isStore': isStore,
      'isOpenContinuous': isOpenContinuous,
      'groupId': groupId,
      'customPricesJson': customPricesJson,
      'balanceCents': balanceCents,
      'debtLimitCents': debtLimitCents,
      'isActive': isActive,
    };
  }

  static ClientType _parseClientType(String val) {
    return ClientType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ClientType.normal,
    );
  }

  static VisitStatus _parseVisitStatus(String val) {
    return VisitStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => VisitStatus.notVisited,
    );
  }
}
