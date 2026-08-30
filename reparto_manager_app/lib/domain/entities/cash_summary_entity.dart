// lib/domain/entities/cash_summary_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/money.dart';

/// Desglose de ingresos por cliente dentro del arqueo de caja diario.
class CashSummaryItem {
  final String clientId;
  final String clientName;
  final Money cash;
  final Money transfer;

  const CashSummaryItem({
    required this.clientId,
    required this.clientName,
    required this.cash,
    required this.transfer,
  });

  /// Total recaudado para este cliente (efectivo + transferencia).
  Money get total => cash + transfer;

  CashSummaryItem copyWith({
    String? clientId,
    String? clientName,
    Money? cash,
    Money? transfer,
  }) {
    return CashSummaryItem(
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      cash: cash ?? this.cash,
      transfer: transfer ?? this.transfer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashSummaryItem &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          clientName == other.clientName &&
          cash == other.cash &&
          transfer == other.transfer;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        clientId,
        clientName,
        cash,
        transfer,
      );

  @override
  String toString() =>
      'CashSummaryItem($clientName: cash: $cash, transfer: $transfer)';
}

/// Entidad inmutable que representa el arqueo diario consolidado de caja.
///
/// Separa de forma estricta el dinero físico a rendir en mano del dinero bancarizado,
/// y distingue las ventas del día de las cobranzas de deudas anteriores.
class CashSummaryEntity {
  /// Efectivo cobrado por ventas del día de hoy.
  final Money salesCash;

  /// Transferencias bancarias recibidas por ventas del día de hoy.
  final Money salesTransfer;

  /// Efectivo cobrado por pagos de deudas anteriores.
  final Money paymentsCash;

  /// Transferencias cobradas por pagos de deudas anteriores.
  final Money paymentsTransfer;

  /// Fiado o deuda en cuenta corriente generada en la jornada de hoy.
  final Money debtGenerated;

  /// Desglose por cliente de la recaudación de la jornada.
  final List<CashSummaryItem> clientBreakdown;

  CashSummaryEntity({
    required this.salesCash,
    required this.salesTransfer,
    required this.paymentsCash,
    required this.paymentsTransfer,
    required this.debtGenerated,
    List<CashSummaryItem>? clientBreakdown,
  }) : clientBreakdown = List.unmodifiable(clientBreakdown ?? const <CashSummaryItem>[]);

  /// Total de billetes físicos a rendir (ventas en efectivo + cobranzas en efectivo).
  Money get totalCash => salesCash + paymentsCash;

  /// Total acreditado en cuentas bancarias / billeteras (transferencias ventas + transferencias cobros).
  Money get totalTransfer => salesTransfer + paymentsTransfer;

  /// Recaudación total real de la jornada (totalCash + totalTransfer).
  Money get totalRevenue => totalCash + totalTransfer;

  CashSummaryEntity copyWith({
    Money? salesCash,
    Money? salesTransfer,
    Money? paymentsCash,
    Money? paymentsTransfer,
    Money? debtGenerated,
    List<CashSummaryItem>? clientBreakdown,
  }) {
    return CashSummaryEntity(
      salesCash: salesCash ?? this.salesCash,
      salesTransfer: salesTransfer ?? this.salesTransfer,
      paymentsCash: paymentsCash ?? this.paymentsCash,
      paymentsTransfer: paymentsTransfer ?? this.paymentsTransfer,
      debtGenerated: debtGenerated ?? this.debtGenerated,
      clientBreakdown: clientBreakdown ?? this.clientBreakdown,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashSummaryEntity &&
          runtimeType == other.runtimeType &&
          salesCash == other.salesCash &&
          salesTransfer == other.salesTransfer &&
          paymentsCash == other.paymentsCash &&
          paymentsTransfer == other.paymentsTransfer &&
          debtGenerated == other.debtGenerated &&
          _listEquals(clientBreakdown, other.clientBreakdown);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        salesCash,
        salesTransfer,
        paymentsCash,
        paymentsTransfer,
        debtGenerated,
        Object.hashAll(clientBreakdown),
      );

  static bool _listEquals(List<CashSummaryItem> a, List<CashSummaryItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'CashSummary(cash: $totalCash, transfer: $totalTransfer, revenue: $totalRevenue, debt: $debtGenerated)';
}
