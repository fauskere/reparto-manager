import '../../models/product.dart';
import '../clients/client.dart';
import 'printer_export.dart';

class PrinterActions {
  static final _printer = getPrinter();

  static Future<bool> printTicket(
    List<CartItem> cart, double subtotal, double discountAmount, List<String> appliedPromoNames, double total,
    List<dynamic>? exchanges, double paidAmount, String paymentMethod, Client? client, double includedDebt, bool duplicate, bool showPaymentDetails, {bool cleanTicket = false}
  ) async {
    return _printer.printTicket(cart, subtotal, discountAmount, appliedPromoNames, total, exchanges, paidAmount, paymentMethod, client, includedDebt, duplicate, showPaymentDetails, cleanTicket: cleanTicket);
  }

  static Future<bool> printAccountStatement(Client client, List<dynamic> transactions, double currentDebt) async {
    return _printer.printAccountStatement(client, transactions, currentDebt);
  }

  static Future<bool> printLastBalance(Client client, List<dynamic> transactions) async {
    return _printer.printLastBalance(client, transactions);
  }

  static Future<bool> printPaymentTicket(Client client, double amount, String method, double newDebt) async {
    return _printer.printPaymentTicket(client, amount, method, newDebt);
  }

  static Future<bool> printDailySummary(String periodLabel, double totalRealCaja, double totalCash, double totalTransfer, List<Map<String, dynamic>> details) async {
    return _printer.printDailySummary(periodLabel, totalRealCaja, totalCash, totalTransfer, details);
  }
}


