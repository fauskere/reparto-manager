import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../../models/product.dart';
import '../../pos/pos_actions.dart';
import '../../../models/product.dart';
import '../../clients/client.dart';
import '../../../models/payment.dart';
import '../../../models/manual_debt.dart';
import '../../../core/preferences_service.dart';

import 'printer_stub.dart';
import '../../../models/sale.dart';
import '../../../models/payment.dart';
import '../../../models/manual_debt.dart';

class MobilePrinter implements AppPrinter {
  Future<bool> _executePrintWithRetry(void Function() printOps) async {
    bool isConnected = await _ensureConnection();
    if (!isConnected) return false;
    
    try {
      printOps();
      return true;
    } catch (e) {
      print("Printer error: $e");
      try { await bluetooth.disconnect(); } catch (_) {}
      bool reconnected = await _ensureConnection();
      if (reconnected) {
        try {
          printOps();
          return true;
        } catch (e2) {
          print("Printer error after reconnect: $e2");
          return false;
        }
      }
      return false;
    }
  }

  Future<bool> _ensureConnection() async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == true) return true;
    
    final savedMac = PreferencesService().getString('printer_mac');
    if (savedMac != null && savedMac.isNotEmpty) {
      try {
        final device = BluetoothDevice('', savedMac);
        await bluetooth.connect(device);
        isConnected = await bluetooth.isConnected;
        return isConnected == true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  /// Imprime nombre y precio en el ticket.
  /// Si entran juntos en 32 chars → una sola línea.
  /// Si NO entran → nombre en línea 1 completo, precio alineado a la derecha en línea 2.
  /// NUNCA se recorta el nombre.
  /// Transliterar caracteres no-ASCII para impresoras térmicas (solo soportan ASCII básico).
  String _sanitize(String s) {
    const Map<String, String> _map = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'ñ': 'n', 'Ñ': 'N',
      'ç': 'c', 'Ç': 'C',
      '¡': '!', '¿': '?',
    };
    return s.split('').map((c) => _map[c] ?? c).join('');
  }

  void _printRow(String left, String right) {
    left = _sanitize(left);
    right = _sanitize(right);
    const int width = 32;
    final int needed = left.length + right.length + 1;
    if (needed <= width) {
      final int spaces = width - left.length - right.length;
      bluetooth.printCustom('$left${' ' * spaces}$right', 1, 0);
    } else {
      bluetooth.printCustom(left, 1, 0);
      final int spaces = (width - right.length).clamp(0, width);
      bluetooth.printCustom('${' ' * spaces}$right', 1, 0);
    }
  }

  /// Wrapper que sanitiza y luego llama a bluetooth directamente (sin recursión)
  void _print(String text, [int size = 0, int align = 0]) {
    bluetooth.printCustom(_sanitize(text), size, align);
  }


  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<bool> printTicket(
    List<CartItem> cart, double subtotal, double discountAmount, List<String> appliedPromoNames, double total,
    List<dynamic>? exchanges, double paidAmount, String paymentMethod, Client? client, double includedDebt, bool duplicate, bool showPaymentDetails, {bool cleanTicket = false}
  ) async {
    return _executePrintWithRetry(() {
      // Cabecera
      bluetooth.printNewLine();
      _print("MARIA BELEN", 2, 1);
      if (duplicate) {
        _print("(DUPLICADO)", 1, 1);
      }
      bluetooth.printNewLine();
      
      if (client != null) {
        _print("Cliente: ${client.name}", 1, 0);
      }
      
      String date = DateTime.now().toString().substring(0, 16);
      _print("Fecha: $date", 0, 0);
      _print("--------------------------------", 0, 1);
      
      // â”€â”€ Ãtems â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Los precios se muestran a precio ORIGINAL (sin descontar el manual).
      // Los descuentos manuales se detallan al pie, antes del TOTAL.
      for (var item in cart) {
        String name = item.product.name;
        name = name.replaceAll(RegExp(r'\s+x\s*1$', caseSensitive: false), '');
        if (name.length > 20) name = name.substring(0, 20);
        
        // Precio original sin descuento manual
        final double originalLinePrice = item.unitPrice * item.quantity;
        String qtyName = "${item.quantity}x $name";
        String price = "\$${originalLinePrice.toStringAsFixed(0)}";
        _printRow(qtyName, price);
        
        // Variante
        if (item.selectedVariant != null) {
          String variantLine = "   (${item.selectedVariant!.name})";
          if (variantLine.length > 32) variantLine = variantLine.substring(0, 32);
          _print(variantLine, 0, 0);
        }
        
        // Precio unitario sólo cuando la cantidad es mayor a 1
        if (item.quantity > 1) {
          _print("   (\$${item.unitPrice.toStringAsFixed(0)} c/u)", 0, 0);
        }
      }
      
      // Cambios / Devoluciones
      if (exchanges != null && exchanges.isNotEmpty) {
        _print("--------------------------------", 0, 1);
        _print("CAMBIOS / DEVOLUCIONES", 1, 1);
        for (var item in exchanges) {
          String name = item.product.name;
          name = name.replaceAll(RegExp(r'\s+x\s*1$', caseSensitive: false), '');
          if (name.length > 20) name = name.substring(0, 20);
          String qtyName = "- ${item.quantity}x $name";
          _printRow(qtyName, "");
          if (item.selectedVariant != null) {
            String variantLine = "   (${item.selectedVariant!.name})";
            if (variantLine.length > 32) variantLine = variantLine.substring(0, 32);
            _print(variantLine, 0, 0);
          }
        }
      }
      
      _print("--------------------------------", 0, 1);

      // â”€â”€ Descuentos manuales por producto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      double totalManualDiscount = 0;
      for (var item in cart) {
        if (item.manualDiscount > 0) {
          final double saved = item.manualDiscount * item.quantity;
          totalManualDiscount += saved;
          // Calcular % sobre precio original
          final double pct = (item.manualDiscount / item.unitPrice) * 100;
          String name = item.product.name;
          if (item.selectedVariant != null) name += " (${item.selectedVariant!.name})";
          if (name.length > 18) name = name.substring(0, 18);
          final String pctStr = "${pct.toStringAsFixed(0)}%";
          _printRow("Desc. $name ($pctStr):", "-\$${saved.toStringAsFixed(0)}");
        }
      }

      // â”€â”€ Bonificaciones / promos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // subtotal = suma de precios originales de todos los ítems (sin manual discount)
      final double rawSubtotal = cart.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
      final bool hasAnyDiscount = totalManualDiscount > 0 || discountAmount > 0;

      if (hasAnyDiscount) {
        _printRow("Subtotal:", "\$${rawSubtotal.toStringAsFixed(0)}");
      }

      if (discountAmount > 0) {
        String promoText = "Bonif. (${appliedPromoNames.join(', ')})";
        if (promoText.length > 22) promoText = promoText.substring(0, 22);
        _printRow(promoText, "-\$${discountAmount.toStringAsFixed(0)}");
      }

      // â”€â”€ Total â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (includedDebt != 0 && !cleanTicket) {
          _printRow("SUBTOTAL:", "\$${total.toStringAsFixed(0)}");
          String debtLabel = includedDebt > 0 ? "SALDO PENDIENTE:" : "SALDO A FAVOR:";
          String debtValue = includedDebt > 0 ? "+\$${includedDebt.toStringAsFixed(0)}" : "-\$${includedDebt.abs().toStringAsFixed(0)}";
          _printRow(debtLabel, debtValue);
          _print("--------------------------------", 0, 1);
          _printRow("TOTAL:", "\$${(total + includedDebt).toStringAsFixed(0)}");
        } else {
          _printRow("TOTAL:", "\$${total.toStringAsFixed(0)}");
        }

      // â”€â”€ Ahorro total â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final double totalSaved = totalManualDiscount + discountAmount;
      
      if (showPaymentDetails) {
        if (paymentMethod != 'Pendiente') {
          _printRow("Su Pago ($paymentMethod):", "\$${paidAmount.toStringAsFixed(0)}");
          if (paidAmount < (total + includedDebt)) {
            _printRow("Resta de esta compra:", "\$${((total + includedDebt) - paidAmount).toStringAsFixed(0)}");
          }
        }
      }

      bluetooth.printNewLine();
      _print("ALIAS: mariabelenlincoln", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
      
    });
  }



  Future<bool> printAccountStatement(Client client, List<dynamic> transactions, double currentDebt) async {
    return _executePrintWithRetry(() {
      bluetooth.printNewLine();
      _print("MARIA BELEN", 2, 1);
      _print("ESTADO DE CUENTA", 1, 1);
      bluetooth.printNewLine();
      
      _print("Cliente: ${client.name}", 1, 0);
      _print("Impreso: ${DateTime.now().toString().substring(0, 16)}", 0, 0);
      _print("--------------------------------", 0, 1);
      
      // Tomar como máximo las últimas 10 transacciones
      final List<dynamic> last10 = transactions.take(10).toList();
      // Invertir el orden para que se impriman cronológicamente (más viejas primero dentro de esas 10)
      final List<dynamic> chronologicallyOrdered = last10.reversed.toList();

      for (var tx in chronologicallyOrdered) {
        if (tx is Sale) {
          double debt = tx.total - tx.paidAmount;
          if (debt > 0) {
            String date = tx.date.toString().substring(0, 10);
            _printRow("$date (Compra)", "+\$${debt.toStringAsFixed(0)}");
          }
        } else if (tx is Payment) {
          String date = tx.date.toString().substring(0, 10);
          _printRow("$date (Pago ${tx.method})", "-\$${tx.amount.toStringAsFixed(0)}");
        } else if (tx is ManualDebt) {
          String date = tx.date.toString().substring(0, 10);
          String desc = tx.description;
          if (desc.length > 15) desc = desc.substring(0, 15);
          _printRow("$date ($desc)", "+\$${tx.amount.toStringAsFixed(0)}");
        }
      }
      
      _print("--------------------------------", 0, 1);
      _printRow("SALDO PENDIENTE:", "\$${currentDebt.toStringAsFixed(0)}");
      
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
      
    });
  }

  Future<bool> printLastBalance(Client client, List<dynamic> transactions) async {
    return _executePrintWithRetry(() {
      bluetooth.printNewLine();
      _print("MARIA BELEN", 2, 1);
      _print("SALDO DE CUENTA", 1, 1);
      bluetooth.printNewLine();
      
      _print("Cliente: ${client.name}", 1, 0);
      _print("Impreso: ${DateTime.now().toString().substring(0, 16)}", 0, 0);
      _print("--------------------------------", 0, 1);

      if (transactions.isEmpty) {
        _printRow("SALDO ANTERIOR:", "\$0");
        _print("--------------------------------", 0, 1);
        _printRow("SALDO ACTUAL CC:", "\$${client.balance.toStringAsFixed(0)}");
      } else {
        // La lista transactions está ordenada descendente (más nuevos primero)
        final tx = transactions.first;
        double impact = 0;
        String desc = '';
        String date = '';
        
        if (tx is Sale) {
          impact = tx.total - tx.paidAmount;
          date = tx.date.toString().substring(0, 10);
          desc = "Compra del $date";
        } else if (tx is Payment) {
          impact = -tx.amount;
          date = tx.date.toString().substring(0, 10);
          desc = "Pago (${tx.method}) del $date";
        } else if (tx is ManualDebt) {
          impact = tx.amount;
          date = tx.date.toString().substring(0, 10);
          String d = tx.description;
          if (d.length > 15) d = d.substring(0, 15);
          desc = "$d del $date";
        }

        double prevBalance = client.balance - impact;

        _printRow("SALDO ANTERIOR:", "\$${prevBalance.toStringAsFixed(0)}");
        _print("Ultimo Movimiento:", 0, 0);
        _printRow(" $desc", "${impact >= 0 ? '+' : ''}\$${impact.abs().toStringAsFixed(0)}");
        _print("--------------------------------", 0, 1);
        _printRow("SALDO ACTUAL CC:", "\$${client.balance.toStringAsFixed(0)}");
      }

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
      
    });
  }

  Future<bool> printPaymentTicket(Client client, double amount, String method, double newDebt) async {
    return _executePrintWithRetry(() {
      bluetooth.printNewLine();
      _print("MARIA BELEN", 2, 1);
      _print("RECIBO DE PAGO", 1, 1);
      bluetooth.printNewLine();
      
      _print("Cliente: ${client.name}", 1, 0);
      _print("Fecha: ${DateTime.now().toString().substring(0, 16)}", 0, 0);
      _print("--------------------------------", 0, 1);
      
      _printRow("Su Pago ($method):", "\$${amount.toStringAsFixed(0)}");
      _print("--------------------------------", 0, 1);
      _printRow("SALDO PENDIENTE:", "\$${newDebt.toStringAsFixed(0)}");
      
      bluetooth.printNewLine();
      _print("--------------------------------", 0, 1);
      _print("*** MUCHAS GRACIAS ***", 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
      
    });
  }

  Future<bool> printDailySummary(String periodLabel, double totalRealCaja, double totalCash, double totalTransfer, List<Map<String, dynamic>> details) async {
    return _executePrintWithRetry(() {
      bluetooth.printNewLine();
      _print("MARIA BELEN", 2, 1);
      _print("RESUMEN DE CAJA", 1, 1);
      _print(periodLabel, 0, 1);
      bluetooth.printNewLine();

      _print("INGRESOS POR CLIENTE", 1, 0);
      _print("--------------------------------", 0, 1);

      // Agrupar ingresos por cliente y método
      for (var entry in details) {
        final String name = entry['clientName'] ?? 'Sin Cliente';
        final double cash = entry['cash'] ?? 0.0;
        final double transfer = entry['transfer'] ?? 0.0;

        if (name.length > 20) {
          _print(name.substring(0, 20), 0, 0);
        } else {
          _print(name, 0, 0);
        }

        if (cash > 0) {
          _printRow("   (E) Efectivo:", "\$${cash.toStringAsFixed(0)}");
        }
        if (transfer > 0) {
          _printRow("   (T) Transferencia:", "\$${transfer.toStringAsFixed(0)}");
        }
      }

      _print("--------------------------------", 0, 1);
      _printRow("EFECTIVO TOTAL:", "\$${totalCash.toStringAsFixed(0)}");
      _printRow("TRANSFERENCIA TOTAL:", "\$${totalTransfer.toStringAsFixed(0)}");
      _print("--------------------------------", 0, 1);
      _printRow("TOTAL CAJA:", "\$${totalRealCaja.toStringAsFixed(0)}");

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    });
  }
}

AppPrinter getPrinter() => MobilePrinter();




