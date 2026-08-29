import '../../../models/product.dart';
import '../../clients/client.dart';

abstract class AppPrinter {
  Future<bool> printTicket(
    List<CartItem> cart, double subtotal, double discountAmount, List<String> appliedPromoNames, double total,
    List<dynamic>? exchanges, double paidAmount, String paymentMethod, Client? client, double includedDebt, bool duplicate, bool showPaymentDetails, {bool cleanTicket = false}
  );

  Future<bool> printAccountStatement(Client client, List<dynamic> transactions, double currentDebt);
  Future<bool> printLastBalance(Client client, List<dynamic> transactions);
  Future<bool> printPaymentTicket(Client client, double amount, String method, double newDebt);
  Future<bool> printDailySummary(String periodLabel, double totalRealCaja, double totalCash, double totalTransfer, List<Map<String, dynamic>> details);
}

AppPrinter getPrinter() => throw UnsupportedError('Cannot create a printer');



