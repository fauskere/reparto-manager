// lib/domain/entities/sale_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import 'sale_item_entity.dart';

export 'sale_item_entity.dart';

/// Método financiero de pago de la venta.
enum PaymentMethod {
  cash,
  transfer,
  mixed,
  onAccount,
}

/// Entidad inmutable que representa una venta o comprobante de entrega.
class SaleEntity {
  final String id;
  final String tenantId;
  final String clientId;
  final String clientName;
  final int ticketNumber;
  final DateTime date;
  final List<SaleItemEntity> items;
  final List<ExchangeItemEntity> exchanges;
  final List<String> appliedPromos;
  final Money subtotal;
  final Money totalDiscount;
  final Money total;
  final PaymentMethod paymentMethod;
  final Money cashPaid;
  final Money transferPaid;
  final Money debtGenerated;
  final Money? previousBalance;
  final Money? remainingBalance;
  final String? transferReceiptNumber;
  final bool isCancelled;

  SaleEntity({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.clientName,
    required this.ticketNumber,
    required this.date,
    required List<SaleItemEntity> items,
    List<ExchangeItemEntity>? exchanges,
    List<String>? appliedPromos,
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
    required this.paymentMethod,
    required this.cashPaid,
    required this.transferPaid,
    required this.debtGenerated,
    this.previousBalance,
    this.remainingBalance,
    this.transferReceiptNumber,
    this.isCancelled = false,
  })  : items = List.unmodifiable(items),
        exchanges = List.unmodifiable(exchanges ?? const <ExchangeItemEntity>[]),
        appliedPromos = List.unmodifiable(appliedPromos ?? const <String>[]);

  /// Valida y construye una venta asegurando los invariantes matemáticos bancarios.
  static Result<SaleEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String clientId,
    required String clientName,
    required int ticketNumber,
    required DateTime date,
    required List<SaleItemEntity> items,
    List<ExchangeItemEntity>? exchanges,
    List<String>? appliedPromos,
    required Money subtotal,
    required Money totalDiscount,
    required PaymentMethod paymentMethod,
    required Money cashPaid,
    required Money transferPaid,
    Money? previousBalance,
    Money? remainingBalance,
    String? transferReceiptNumber,
    bool isCancelled = false,
  }) {
    if (items.isEmpty && (exchanges == null || exchanges.isEmpty)) {
      return Result.fail(
        const EntityValidationFailure('La venta debe tener al menos un ítem o cambio'),
      );
    }
    if (totalDiscount > subtotal) {
      return Result.fail(
        const EntityValidationFailure(
          'El descuento total no puede superar al subtotal de la venta',
        ),
      );
    }

    final calculatedTotal = subtotal - totalDiscount;
    final totalPaid = cashPaid + transferPaid;

    if (totalPaid > calculatedTotal) {
      return Result.fail(
        const EntityValidationFailure(
          'El total abonado no puede superar el importe neto total de la venta',
        ),
      );
    }

    final debt = calculatedTotal - totalPaid;

    return Result.ok(
      SaleEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        clientId: clientId.trim(),
        clientName: clientName.trim(),
        ticketNumber: ticketNumber,
        date: date.toUtc(),
        items: items,
        exchanges: exchanges,
        appliedPromos: appliedPromos,
        subtotal: subtotal,
        totalDiscount: totalDiscount,
        total: calculatedTotal,
        paymentMethod: paymentMethod,
        cashPaid: cashPaid,
        transferPaid: transferPaid,
        debtGenerated: debt,
        previousBalance: previousBalance,
        remainingBalance: remainingBalance,
        transferReceiptNumber: transferReceiptNumber?.trim(),
        isCancelled: isCancelled,
      ),
    );
  }

  /// Ganancia total neta estimada sumando todos los renglones.
  Money get totalProfit {
    var profit = Money.zero;
    for (final item in items) {
      profit = profit + item.profit;
    }
    return profit;
  }

  /// Cantidad total de unidades vendidas.
  int get totalItemsCount {
    var count = 0;
    for (final item in items) {
      count += item.quantity;
    }
    return count;
  }

  SaleEntity copyWith({
    String? id,
    String? tenantId,
    String? clientId,
    String? clientName,
    int? ticketNumber,
    DateTime? date,
    List<SaleItemEntity>? items,
    List<ExchangeItemEntity>? exchanges,
    List<String>? appliedPromos,
    Money? subtotal,
    Money? totalDiscount,
    Money? total,
    PaymentMethod? paymentMethod,
    Money? cashPaid,
    Money? transferPaid,
    Money? debtGenerated,
    Money? previousBalance,
    Money? remainingBalance,
    String? transferReceiptNumber,
    bool? isCancelled,
  }) {
    return SaleEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      date: date ?? this.date,
      items: items ?? this.items,
      exchanges: exchanges ?? this.exchanges,
      appliedPromos: appliedPromos ?? this.appliedPromos,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashPaid: cashPaid ?? this.cashPaid,
      transferPaid: transferPaid ?? this.transferPaid,
      debtGenerated: debtGenerated ?? this.debtGenerated,
      previousBalance: previousBalance ?? this.previousBalance,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      transferReceiptNumber: transferReceiptNumber ?? this.transferReceiptNumber,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          clientId == other.clientId &&
          ticketNumber == other.ticketNumber &&
          date == other.date &&
          total == other.total &&
          isCancelled == other.isCancelled;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        clientId,
        ticketNumber,
        date,
        total,
        isCancelled,
      );

  @override
  String toString() => 'SaleEntity(#$ticketNumber, client: $clientName, total: $total)';
}
