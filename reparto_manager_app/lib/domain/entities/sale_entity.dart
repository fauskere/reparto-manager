// lib/domain/entities/sale_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';

/// Método financiero de pago de la venta.
enum PaymentMethod {
  /// Pago íntegro en efectivo en mano.
  cash,

  /// Pago íntegro por transferencia bancaria o billetera digital.
  transfer,

  /// Pago desglosado (parte en efectivo + parte en transferencia).
  mixed,

  /// Venta a crédito / fiado en cuenta corriente (sin entrega en el acto).
  onAccount,
}

/// Renglón individual de venta correspondiente a una variante de producto.
class SaleItemEntity {
  final String productId;
  final String variantName;
  final String productName;
  final int quantity;
  final Money unitPrice;
  final Money unitCost;
  final Money discount;

  const SaleItemEntity({
    required this.productId,
    required this.variantName,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.discount = Money.zero,
  });

  /// Clave unificada de la variante vendida ("productId|variantName").
  String get variantKey => '$productId|$variantName';

  /// Subtotal del renglón aplicando el descuento ((unitPrice * quantity) - discount).
  Money get subtotal => (unitPrice * quantity) - discount;

  /// Costo total de adquisición de las unidades vendidas.
  Money get totalCost => unitCost * quantity;

  /// Ganancia bruta neta generada por este renglón.
  Money get profit => subtotal - totalCost;

  SaleItemEntity copyWith({
    String? productId,
    String? variantName,
    String? productName,
    int? quantity,
    Money? unitPrice,
    Money? unitCost,
    Money? discount,
  }) {
    return SaleItemEntity(
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      discount: discount ?? this.discount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemEntity &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          variantName == other.variantName &&
          productName == other.productName &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          unitCost == other.unitCost &&
          discount == other.discount;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        productId,
        variantName,
        productName,
        quantity,
        unitPrice,
        unitCost,
        discount,
      );

  @override
  String toString() =>
      'SaleItem($productName ($variantName) x$quantity = $subtotal)';
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
  final Money subtotal;
  final Money totalDiscount;
  final Money total;
  final PaymentMethod paymentMethod;
  final Money cashPaid;
  final Money transferPaid;
  final Money debtGenerated;
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
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
    required this.paymentMethod,
    required this.cashPaid,
    required this.transferPaid,
    required this.debtGenerated,
    this.transferReceiptNumber,
    this.isCancelled = false,
  }) : items = List.unmodifiable(items);

  /// Valida y construye una venta asegurando los invariantes matemáticos bancarios.
  static Result<SaleEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String clientId,
    required String clientName,
    required int ticketNumber,
    required DateTime date,
    required List<SaleItemEntity> items,
    required Money subtotal,
    required Money totalDiscount,
    required PaymentMethod paymentMethod,
    required Money cashPaid,
    required Money transferPaid,
    String? transferReceiptNumber,
    bool isCancelled = false,
  }) {
    if (items.isEmpty) {
      return Result.fail(
        const EntityValidationFailure('La venta debe tener al menos un ítem'),
      );
    }
    // Directiva 2: totalDiscount jamás mayor a subtotal (total no puede ser negativo)
    if (totalDiscount > subtotal) {
      return Result.fail(
        const EntityValidationFailure(
          'El descuento total no puede superar al subtotal de la venta',
        ),
      );
    }

    final calculatedTotal = subtotal - totalDiscount;
    final totalPaid = cashPaid + transferPaid;

    // Directiva 3: los pagos no pueden superar el total neto de la venta
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
        subtotal: subtotal,
        totalDiscount: totalDiscount,
        total: calculatedTotal,
        paymentMethod: paymentMethod,
        cashPaid: cashPaid,
        transferPaid: transferPaid,
        debtGenerated: debt,
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

  /// Cantidad total de unidades de productos vendidas en este ticket.
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
    Money? subtotal,
    Money? totalDiscount,
    Money? total,
    PaymentMethod? paymentMethod,
    Money? cashPaid,
    Money? transferPaid,
    Money? debtGenerated,
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
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashPaid: cashPaid ?? this.cashPaid,
      transferPaid: transferPaid ?? this.transferPaid,
      debtGenerated: debtGenerated ?? this.debtGenerated,
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
