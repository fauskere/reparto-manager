import 'dart:js_interop';
import '../../../models/product.dart';
import '../../clients/client.dart';
import 'printer_stub.dart';

@JS('webPrintHtml')
external void _webPrintHtml(String html);

class WebPrinter implements AppPrinter {
  String _htmlBuffer = '';

  void _print(String text, int size, int align) {
    String escaped = text.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    _htmlBuffer += '<div class="align-$align size-$size">$escaped</div>';
  }

  void _printRow(String left, String right) {
    String eLeft = left.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    String eRight = right.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    _htmlBuffer += '<div class="row size-0"><div class="left">$eLeft</div><div class="right">$eRight</div></div>';
  }

  Future<bool> _executePrint(void Function() printOps) async {
    _htmlBuffer = '';
    printOps();
    _htmlBuffer += '<br><br><br>';
    try {
      _webPrintHtml(_htmlBuffer);
      return true;
    } catch (e) {
      print("WebPrint Error: $e");
      return false;
    }
  }

  @override
  Future<bool> printTicket(
    List<CartItem> cart, double subtotal, double discountAmount, List<String> appliedPromoNames, double total,
    List<dynamic>? exchanges, double paidAmount, String paymentMethod, Client? client, double includedDebt, bool duplicate, bool showPaymentDetails, {bool cleanTicket = false}
  ) async {
    return _executePrint(() {
      _print("REPARTO MANAGER", 2, 1);
      _print("Ticket de Venta", 0, 1);
      _print("--------------------------------", 0, 1);

      if (cleanTicket) {
        _print("TICKET DE CAMBIO", 1, 1);
        _print("Valido por los sig. productos", 0, 1);
        _print("--------------------------------", 0, 1);
      }

      for (var item in cart) {
        _print("${item.quantity}x ${item.product.name}", 1, 0);
        if (!cleanTicket) {
          _printRow("  $paymentMethod:", "\{(item.unitPrice * item.quantity).toStringAsFixed(0)}");
        }
      }

      if (!cleanTicket) {
        if (exchanges != null && exchanges.isNotEmpty) {
          _print("--------------------------------", 0, 1);
          _print("CAMBIOS:", 1, 0);
          for (var exc in exchanges) {
            String eName = exc['productName'] ?? exc['name'] ?? 'Desconocido';
            int eQty = (exc['quantity'] as num).toInt();
            _print("$eQty x $eName", 0, 0);
          }
        }

        _print("--------------------------------", 0, 1);
        final double rawSubtotal = cart.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
        if (discountAmount > 0) {
          _printRow("SUBTOTAL:", "\{rawSubtotal.toStringAsFixed(0)}");
          for (var pName in appliedPromoNames) {
            _print("PROMO: $pName", 0, 0);
          }
          _printRow("DESCUENTOS:", "-\{discountAmount.toStringAsFixed(0)}");
          _print("--------------------------------", 0, 1);
        }
        
        _printRow("TOTAL:", "\{total.toStringAsFixed(0)}");

        if (client != null && showPaymentDetails) {
          _print("--------------------------------", 0, 1);
          _print("CLIENTE: ${client.name}", 1, 0);
          if (includedDebt > 0) {
            _printRow("Saldo Anterior:", "\{includedDebt.toStringAsFixed(0)}");
            _printRow("Total a Pagar:", "\{(total + includedDebt).toStringAsFixed(0)}");
          }
          _printRow("Pagado ($paymentMethod):", "\{paidAmount.toStringAsFixed(0)}");
          double newDebt = (total + includedDebt) - paidAmount;
          _printRow("Saldo Actual:", "\{newDebt.toStringAsFixed(0)}");
        }
      }

      if (duplicate) {
        _print("--------------------------------", 0, 1);
        _print("*** DUPLICADO ***", 1, 1);
      }
    });
  }

  @override
  Future<bool> printAccountStatement(Client client, List<dynamic> transactions, double currentDebt) async {
    return _executePrint(() {
      _print("ESTADO DE CUENTA", 2, 1);
      _print(client.name.toUpperCase(), 1, 1);
      _print("--------------------------------", 0, 1);

      for (var t in transactions) {
        String type = t['type'] == 'sale' ? 'Venta' : (t['type'] == 'payment' ? 'Pago' : 'Ajuste');
        String dateStr = 'Fecha';
        if (t['date'] != null) {
          try {
            final dt = t['date'].toDate();
            dateStr = "${dt.day}/${dt.month}/${dt.year}";
          } catch (_) {}
        }
        double amt = (t['amount'] as num).toDouble();
        String sign = (t['type'] == 'payment') ? '-' : '';
        
        _printRow("$dateStr - $type", "$sign\{amt.toStringAsFixed(0)}");
      }

      _print("--------------------------------", 0, 1);
      _printRow("SALDO ACTUAL:", "\{currentDebt.toStringAsFixed(0)}");
    });
  }

  @override
  Future<bool> printLastBalance(Client client, List<dynamic> transactions) async {
    return _executePrint(() {
      _print("SALDO ACTUAL", 2, 1);
      _print(client.name.toUpperCase(), 1, 1);
      _print("--------------------------------", 0, 1);
      
      _printRow("SALDO:", "\{client.debt.toStringAsFixed(0)}");
    });
  }

  @override
  Future<bool> printPaymentTicket(Client client, double amount, String method, double newDebt) async {
    return _executePrint(() {
      _print("RECIBO DE PAGO", 2, 1);
      _print("--------------------------------", 0, 1);
      _print("CLIENTE: ${client.name}", 1, 0);
      _printRow("PAGO RECIBIDO:", "\{amount.toStringAsFixed(0)}");
      _printRow("METODO:", method);
      _print("--------------------------------", 0, 1);
      _printRow("SALDO ACTUAL:", "\{newDebt.toStringAsFixed(0)}");
    });
  }

  @override
  Future<bool> printDailySummary(String periodLabel, double totalRealCaja, double totalCash, double totalTransfer, List<Map<String, dynamic>> details) async {
    return _executePrint(() {
      _print("RESUMEN DE CAJA", 1, 1);
      _print(periodLabel, 0, 1);
      _print("--------------------------------", 0, 1);
      
      _printRow("EFECTIVO EN CAJA:", "\{totalCash.toStringAsFixed(0)}");
      _printRow("TRANSF EN CAJA:", "\{totalTransfer.toStringAsFixed(0)}");
      _print("--------------------------------", 0, 1);
      _printRow("TOTAL CAJA:", "\{totalRealCaja.toStringAsFixed(0)}");
    });
  }
}

AppPrinter getPrinter() => WebPrinter();
