// lib/data/models/ledger_entry_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import '../../domain/core/money.dart';
import '../../domain/entities/ledger_entry_entity.dart';

/// Modelo de datos para la tabla SQLite `ledger_entries`.
/// Mapea asientos contables bajo el patrón Event Sourcing.
class LedgerEntryModel {
  final String id;
  final String tenantId;
  final String clientId;
  final String dateUtc;
  final String type;
  final int amountCents;
  final int balanceImpactCents;
  final String description;
  final String? documentReference;

  const LedgerEntryModel({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.dateUtc,
    required this.type,
    required this.amountCents,
    required this.balanceImpactCents,
    required this.description,
    this.documentReference,
  });

  /// Crea un [LedgerEntryModel] a partir de una entidad [LedgerEntryEntity].
  factory LedgerEntryModel.fromEntity(LedgerEntryEntity entity) {
    return LedgerEntryModel(
      id: entity.id,
      tenantId: entity.tenantId,
      clientId: entity.clientId,
      dateUtc: entity.date.toUtc().toIso8601String(),
      type: entity.type.name,
      amountCents: entity.amount.cents,
      balanceImpactCents: entity.balanceImpact.cents,
      description: entity.description,
      documentReference: entity.referenceId,
    );
  }

  /// Convierte este modelo a una entidad [LedgerEntryEntity].
  LedgerEntryEntity toEntity() {
    return LedgerEntryEntity(
      id: id,
      tenantId: tenantId,
      clientId: clientId,
      date: DateTime.parse(dateUtc).toUtc(),
      type: _parseType(type),
      referenceId: documentReference ?? '',
      amount: Money.fromCents(amountCents),
      description: description,
    );
  }

  /// Crea un [LedgerEntryModel] desde una fila de SQLite.
  factory LedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return LedgerEntryModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      clientId: map['clientId'] as String,
      dateUtc: map['dateUtc'] as String,
      type: map['type'] as String,
      amountCents: (map['amountCents'] as num).toInt(),
      balanceImpactCents: (map['balanceImpactCents'] as num).toInt(),
      description: map['description'] as String,
      documentReference: map['documentReference'] as String?,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'clientId': clientId,
      'dateUtc': dateUtc,
      'type': type,
      'amountCents': amountCents,
      'balanceImpactCents': balanceImpactCents,
      'description': description,
      'documentReference': documentReference,
    };
  }

  static LedgerEntryType _parseType(String val) {
    return LedgerEntryType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => LedgerEntryType.saleDebt,
    );
  }
}

/// Modelo de datos para la tabla SQLite `ledger_snapshots`.
/// Representa cierres contables periódicos para resolución O(1) de saldos.
class LedgerSnapshotModel {
  final String id;
  final String tenantId;
  final String clientId;
  final String dateUtc;
  final int closingBalanceCents;
  final int entryCount;

  const LedgerSnapshotModel({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.dateUtc,
    required this.closingBalanceCents,
    required this.entryCount,
  });

  /// Crea un [LedgerSnapshotModel] a partir de [LedgerSnapshot].
  factory LedgerSnapshotModel.fromEntity(LedgerSnapshot entity, {String? snapshotId}) {
    return LedgerSnapshotModel(
      id: snapshotId ?? entity.lastEntryId,
      tenantId: entity.tenantId,
      clientId: entity.clientId,
      dateUtc: entity.closingDate.toUtc().toIso8601String(),
      closingBalanceCents: entity.balance.cents,
      entryCount: entity.entryCount,
    );
  }

  /// Convierte este modelo a una entidad [LedgerSnapshot].
  LedgerSnapshot toEntity() {
    return LedgerSnapshot(
      tenantId: tenantId,
      clientId: clientId,
      closingDate: DateTime.parse(dateUtc).toUtc(),
      balance: Money.fromCents(closingBalanceCents),
      lastEntryId: id,
      entryCount: entryCount,
    );
  }

  /// Crea un [LedgerSnapshotModel] desde una fila de SQLite.
  factory LedgerSnapshotModel.fromMap(Map<String, dynamic> map) {
    return LedgerSnapshotModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      clientId: map['clientId'] as String,
      dateUtc: map['dateUtc'] as String,
      closingBalanceCents: (map['closingBalanceCents'] as num).toInt(),
      entryCount: (map['entryCount'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'clientId': clientId,
      'dateUtc': dateUtc,
      'closingBalanceCents': closingBalanceCents,
      'entryCount': entryCount,
    };
  }
}
