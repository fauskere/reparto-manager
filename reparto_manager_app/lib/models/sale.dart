import 'package:cloud_firestore/cloud_firestore.dart';
// From product.dart
import 'product.dart';

class ExchangeItem {
  final Product product;
  final ProductVariant? selectedVariant;
  final int quantity;

  ExchangeItem({
    required this.product,
    this.selectedVariant,
    required this.quantity,
  });
}

class Sale {
  final String id;
  final DateTime date;
  final double total;
  final double discountAmount;
  final List<String> appliedPromos;
  final List<CartItem> items;
  final List<ExchangeItem> exchanges;
  final String? clientId;
  final String? clientName;
  final String? city;
  final double paidAmount;
  final String paymentMethod; // 'Efectivo', 'Transferencia', 'Pendiente', 'Mixto'
  final double? cashAmount;
  final double? transferAmount;
  final double? previousBalance;
  final double? remainingBalance;

  Sale({
    required this.id,
    required this.date,
    required this.total,
    this.discountAmount = 0.0,
    this.appliedPromos = const [],
    required this.items,
    this.exchanges = const [],
    this.clientId,
    this.clientName,
    this.city,
    required this.paidAmount,
    required this.paymentMethod,
    this.cashAmount,
    this.transferAmount,
    this.previousBalance,
    this.remainingBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'total': total,
      'discountAmount': discountAmount,
      'appliedPromos': appliedPromos,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod,
      'cashAmount': cashAmount,
      'transferAmount': transferAmount,
      'previousBalance': previousBalance,
      'remainingBalance': remainingBalance,
      'items': items.map((e) => {
        'productId': e.product.id,
        'productName': e.product.name,
        'price': e.unitPrice,
        'quantity': e.quantity,
        'variantName': e.selectedVariant?.name,
        'manualDiscount': e.manualDiscount,
      }).toList(),
      'exchanges': exchanges.map((e) => {
        'productId': e.product.id,
        'productName': e.product.name,
        'quantity': e.quantity,
        'variantName': e.selectedVariant?.name,
      }).toList(),
      'clientId': clientId,
      'clientName': clientName,
      'city': city,
    };
  }

  factory Sale.fromMap(String id, Map<String, dynamic> map) {
    var itemsList = map['items'] as List<dynamic>? ?? [];
    List<CartItem> parsedItems = itemsList.map((e) {
      final String? variantName = e['variantName'];
      final double price = e['price'] != null ? (double.tryParse(e['price'].toString()) ?? 0.0) : 0.0;
      final int quantity = e['quantity'] != null ? (int.tryParse(e['quantity'].toString()) ?? 1) : 1;
      final double manualDiscount = e['manualDiscount'] != null ? (double.tryParse(e['manualDiscount'].toString()) ?? 0.0) : 0.0;
      
      return CartItem(
        product: Product(
          id: e['productId'] ?? '',
          name: e['productName'] ?? '',
          price: variantName == null ? price : 0, 
        ),
        selectedVariant: variantName != null ? ProductVariant(name: variantName, price: price) : null,
        quantity: quantity,
        manualDiscount: manualDiscount,
      );
    }).toList();

    var exchangesList = map['exchanges'] as List<dynamic>? ?? [];
    List<ExchangeItem> parsedExchanges = exchangesList.map((e) {
      final String? variantName = e['variantName'];
      final int quantity = e['quantity'] != null ? (int.tryParse(e['quantity'].toString()) ?? 1) : 1;
      
      return ExchangeItem(
        product: Product(
          id: e['productId'] ?? '',
          name: e['productName'] ?? '',
          price: 0, 
        ),
        selectedVariant: variantName != null ? ProductVariant(name: variantName, price: 0) : null,
        quantity: quantity,
      );
    }).toList();

    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else if (map['date'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(map['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return Sale(
      id: id,
      date: parsedDate,
      total: map['total'] != null ? (double.tryParse(map['total'].toString()) ?? 0.0) : 0.0,
      discountAmount: map['discountAmount'] != null ? (double.tryParse(map['discountAmount'].toString()) ?? 0.0) : 0.0,
      appliedPromos: List<String>.from(map['appliedPromos'] ?? []),
      items: parsedItems,
      exchanges: parsedExchanges,
      clientId: map['clientId'],
      clientName: map['clientName'],
      city: map['city'],
      paidAmount: map.containsKey('paidAmount') && map['paidAmount'] != null
          ? (map['paidAmount'] as num).toDouble()
          : (map['paymentMethod'] == 'Pendiente' ? 0.0 : (map['total'] != null ? (map['total'] as num).toDouble() : 0.0)),
      paymentMethod: map['paymentMethod'] ?? 'Efectivo',
      cashAmount: map['cashAmount'] != null ? (map['cashAmount'] as num).toDouble() : null,
      transferAmount: map['transferAmount'] != null ? (map['transferAmount'] as num).toDouble() : null,
      previousBalance: map['previousBalance'] != null ? (map['previousBalance'] as num).toDouble() : null,
      remainingBalance: map['remainingBalance'] != null ? (map['remainingBalance'] as num).toDouble() : null,
    );
  }
}
