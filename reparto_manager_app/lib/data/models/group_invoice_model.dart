// lib/data/models/group_invoice_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/core/money.dart';

/// Modelo de datos para la tabla SQLite `group_invoices`.
/// Representa cortes de facturación consolidados para cadenas o sucursales.
class GroupInvoiceModel {
  final String id;
  final String tenantId;
  final String groupId;
  final int totalAmountCents;
  final String invoicedAtUtc;
  final String saleIdsJson;
  final String status;

  const GroupInvoiceModel({
    required this.id,
    required this.tenantId,
    required this.groupId,
    required this.totalAmountCents,
    required this.invoicedAtUtc,
    required this.saleIdsJson,
    required this.status,
  });

  /// Accesor para el importe con precisión Money.
  Money get totalAmount => Money.fromCents(totalAmountCents);

  /// Accesor de DateTime UTC.
  DateTime get invoicedAt => DateTime.parse(invoicedAtUtc);

  /// Lista decodificada de IDs de ventas incluidas.
  List<String> get saleIds {
    final decoded = jsonDecode(saleIdsJson) as List<dynamic>;
    return decoded.map((e) => e.toString()).toList();
  }

  /// Crea un [GroupInvoiceModel] con tipos fuertes de dominio.
  factory GroupInvoiceModel.create({
    required String id,
    required String tenantId,
    required String groupId,
    required Money totalAmount,
    required DateTime invoicedAt,
    required List<String> saleIds,
    String status = 'pending',
  }) {
    return GroupInvoiceModel(
      id: id,
      tenantId: tenantId,
      groupId: groupId,
      totalAmountCents: totalAmount.cents,
      invoicedAtUtc: invoicedAt.toUtc().toIso8601String(),
      saleIdsJson: jsonEncode(saleIds),
      status: status,
    );
  }

  /// Crea un [GroupInvoiceModel] desde una fila de SQLite.
  factory GroupInvoiceModel.fromMap(Map<String, dynamic> map) {
    return GroupInvoiceModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      groupId: map['groupId'] as String,
      totalAmountCents: (map['totalAmountCents'] as num).toInt(),
      invoicedAtUtc: map['invoicedAtUtc'] as String,
      saleIdsJson: map['saleIdsJson'] as String,
      status: map['status'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'groupId': groupId,
      'totalAmountCents': totalAmountCents,
      'invoicedAtUtc': invoicedAtUtc,
      'saleIdsJson': saleIdsJson,
      'status': status,
    };
  }
}
