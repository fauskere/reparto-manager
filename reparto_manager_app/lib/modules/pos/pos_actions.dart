import 'package:flutter/foundation.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../clients/client.dart';
import '../clients/v2/clients_actions_v2.dart';
import '../promotions/promotions_actions.dart';
import '../../core/preferences_service.dart';

class POSActions extends ChangeNotifier {
  // Patrón Singleton para mantener el estado global
  static final POSActions _instance = POSActions._internal();
  factory POSActions() => _instance;
  POSActions._internal() {
    _selectedCity = PreferencesService().getString('pos_city');
    _selectedCategory = PreferencesService().getString('pos_category') ?? 'Todas';
  }

  final List<CartItem> _cart = [];
  final List<ExchangeItem> _exchanges = [];
  Client? _selectedClient;
  String? _selectedCity;
  String _selectedCategory = 'Todas';
  DateTime _saleDate = DateTime.now();
  final List<String> _appliedPromoNames = [];
  final List<String> _ignoredPromoNames = [];
  String? _editingSaleId;
  double? _editingSaleOriginalDebt;
  bool _resellerMode = false;

  List<CartItem> get cart => _cart;
  List<ExchangeItem> get exchanges => _exchanges;
  Client? get selectedClient => _selectedClient;
  String? get selectedCity => _selectedCity;
  String get selectedCategory => _selectedCategory;
  DateTime get saleDate => _saleDate;
  List<String> get appliedPromoNames => _appliedPromoNames;
  List<String> get ignoredPromoNames => _ignoredPromoNames;
  String? get editingSaleId => _editingSaleId;
  double? get editingSaleOriginalDebt => _editingSaleOriginalDebt;
  bool get resellerMode => _resellerMode;

  void loadOrderIntoPos(Client client, List<CartItem> items) {
    clearCart();
    _selectedClient = client;
    for (var item in items) {
      _cart.add(CartItem(
        product: item.product,
        quantity: item.quantity,
        overridePrice: item.unitPrice,
        selectedVariant: item.selectedVariant,
      ));
    }
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    PreferencesService().setString('pos_category', category);
    notifyListeners();
  }

  void setSaleDate(DateTime date) {
    _saleDate = date;
    notifyListeners();
  }

  void togglePromoIgnore(String promoName) {
    if (_ignoredPromoNames.contains(promoName)) {
      _ignoredPromoNames.remove(promoName);
    } else {
      _ignoredPromoNames.add(promoName);
    }
    notifyListeners();
  }

  double? getPriceForClient(Client? client, Product product, [ProductVariant? variant]) {
    if (client != null) {
      if (client.type == 'especial') {
        final key = variant != null ? "${product.id}_${variant.name}" : product.id;
        if (client.customPrices.containsKey(key)) {
          return client.customPrices[key];
        }
        if (variant != null) {
          return variant.specialPrice ?? product.specialPrice ?? variant.price ?? product.price;
        }
        return product.specialPrice ?? product.price;
      } else if (client.type == 'revendedor') {
        final key = variant != null ? "${product.id}_${variant.name}" : product.id;
        if (client.customPrices.containsKey(key)) {
          return client.customPrices[key];
        }
        if (variant != null) {
          return variant.resellerPrice ?? product.resellerPrice ?? variant.price ?? product.price;
        }
        return product.resellerPrice ?? product.price;
      }
    } else if (_selectedCity == 'Vendedores') {
      if (variant != null) {
        return variant.resellerPrice ?? product.resellerPrice ?? variant.price ?? product.price;
      }
      return product.resellerPrice ?? product.price;
    }
    
    return null;
  }

  void _updateCartPrices() {
    for (var item in _cart) {
      item.overridePrice = getPriceForClient(_selectedClient, item.product, item.selectedVariant);
    }
  }

  void setClient(Client? client) {
    _selectedClient = client;
    if (client == null) {
      _resellerMode = false;
      if (_selectedCity == 'Vendedores') {
        _selectedCity = null;
      }
    } else if (client.type == 'revendedor') {
      _resellerMode = true;
      _selectedCity = 'Vendedores';
    } else if (client.city.isNotEmpty) {
      _resellerMode = false;
      _selectedCity = client.city;
    } else {
      _resellerMode = false;
    }
    
    if (client != null && (client.type == 'especial' || client.type == 'revendedor')) {
      if (client.customPrices.isNotEmpty) {
        _cart.removeWhere((item) {
          final key = item.selectedVariant != null 
              ? "${item.product.id}_${item.selectedVariant!.name}" 
              : item.product.id;
          return !client.customPrices.containsKey(key);
        });
      }
    }
    
    _updateCartPrices();
    notifyListeners();
  }


  void setCity(String? city) {
    _selectedCity = city;
    if (city == null) {
      PreferencesService().remove('pos_city');
    } else {
      PreferencesService().setString('pos_city', city);
    }
    if (_selectedClient != null) {
      if (city == 'Vendedores') {
        if (_selectedClient!.type != 'revendedor') {
          _selectedClient = null;
        }
      } else if (city == null) {
        if (_selectedClient!.type == 'revendedor') {
          _selectedClient = null;
        }
      } else {
        if (_selectedClient!.city != city || _selectedClient!.type == 'revendedor') {
          _selectedClient = null;
        }
      }
    }
    notifyListeners();
  }

  void addToCart(Product product, [ProductVariant? variant]) {
    if (_selectedClient != null && (_selectedClient!.type == 'especial' || _selectedClient!.type == 'revendedor')) {
      if (_selectedClient!.customPrices.isNotEmpty) {
        final key = variant != null ? "${product.id}_${variant.name}" : product.id;
        if (!_selectedClient!.customPrices.containsKey(key)) {
          return; // No compra este producto
        }
      }
    }

    int index = _cart.indexWhere((item) => item.product.id == product.id && item.selectedVariant?.name == variant?.name);
    if (index != -1) {
      _cart[index].quantity += 1;
    } else {
      final double? override = getPriceForClient(_selectedClient, product, variant);
      _cart.add(CartItem(
        product: product, 
        selectedVariant: variant, 
        quantity: 1,
        overridePrice: override,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId, [String? variantName]) {
    _cart.removeWhere((item) => item.product.id == productId && item.selectedVariant?.name == variantName);
    notifyListeners();
  }

  void updateQuantity(String productId, String? variantName, int delta) {
    int index = _cart.indexWhere((item) => item.product.id == productId && item.selectedVariant?.name == variantName);
    if (index != -1) {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateManualDiscount(String productId, String? variantName, double discount) {
    int index = _cart.indexWhere((item) => item.product.id == productId && item.selectedVariant?.name == variantName);
    if (index != -1) {
      _cart[index].manualDiscount = discount;
      notifyListeners();
    }
  }

  void addExchange(Product product, ProductVariant? variant, int quantity) {
    int index = _exchanges.indexWhere((item) => item.product.id == product.id && item.selectedVariant?.name == variant?.name);
    if (index != -1) {
      // Create new ExchangeItem with updated quantity
      final existing = _exchanges[index];
      _exchanges[index] = ExchangeItem(product: existing.product, selectedVariant: existing.selectedVariant, quantity: existing.quantity + quantity);
    } else {
      _exchanges.add(ExchangeItem(product: product, selectedVariant: variant, quantity: quantity));
    }
    notifyListeners();
  }

  void removeExchange(String productId, String? variantName) {
    _exchanges.removeWhere((item) => item.product.id == productId && item.selectedVariant?.name == variantName);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _exchanges.clear();
    _appliedPromoNames.clear();
    _ignoredPromoNames.clear();
    _editingSaleId = null;
    _editingSaleOriginalDebt = null;
    _selectedClient = null;
    _resellerMode = false;
    _selectedCity = PreferencesService().getString('pos_city');
    notifyListeners();
  }

  /// Carga un revendedor en el POS limpiando el carrito anterior.
  /// Activa el modo revendedor: bloquea el cambio de cliente desde el POS.
  void setResellerMode(Client reseller) {
    _cart.clear();
    _exchanges.clear();
    _appliedPromoNames.clear();
    _editingSaleId = null;
    _editingSaleOriginalDebt = null;
    _resellerMode = true;
    _selectedClient = reseller;
    _selectedCity = 'Vendedores';
    _updateCartPrices();
    notifyListeners();
  }

  void loadSale(Sale sale) {
    _cart.clear();
    _exchanges.clear();
    _appliedPromoNames.clear();
    _ignoredPromoNames.clear();
    
    _editingSaleId = sale.id;
    _editingSaleOriginalDebt = sale.total - sale.paidAmount;
    _saleDate = sale.date;
    _cart.addAll(sale.items);
    _exchanges.addAll(sale.exchanges);
    
    _selectedCity = sale.city;
    if (sale.clientId != null) {
      final clientsList = ClientsActionsV2().allClients;
      final idx = clientsList.indexWhere((c) => c.id == sale.clientId);
      if (idx != -1) {
        _selectedClient = clientsList[idx];
      } else {
        _selectedClient = Client(
          id: sale.clientId!,
          name: sale.clientName ?? '',
          phone: '',
          address: '',
          city: sale.city ?? '',
        );
      }
    } else {
      _selectedClient = null;
    }
    
    _resellerMode = _selectedClient?.type == 'revendedor' || sale.city == 'Vendedores';
    
    notifyListeners();
  }

  double getSubtotal() {
    return _cart.fold(0, (sum, item) => sum + item.total);
  }

  double getDiscount() {
    double totalDiscount = 0;
    Set<String> discountedProductIds = {};
    _appliedPromoNames.clear();

    // Get active promotions
    var activePromos = PromotionsActions().promotions.where((p) => p.isActive).toList();
    
    // Prioritize promos with higher discount %. If equal, prioritize promos that require MORE items
    activePromos.sort((a, b) {
      if (a.discountPercentage != b.discountPercentage) {
        return b.discountPercentage.compareTo(a.discountPercentage);
      }
      int unitsA = a.requiredItems.fold(0, (sum, req) => sum + req.quantity);
      int unitsB = b.requiredItems.fold(0, (sum, req) => sum + req.quantity);
      return unitsB.compareTo(unitsA);
    });

    for (var promo in activePromos) {

      bool qualifies = true;
      Map<String, int> availableQtys = {};
      
      for (var item in _cart) {
        if (!discountedProductIds.contains(item.product.id)) {
           String key = "${item.product.id}|${item.selectedVariant?.name ?? ''}";
           availableQtys[key] = (availableQtys[key] ?? 0) + item.quantity;
        }
      }

      for (var req in promo.requiredItems) {
        if (req.variantName != null) {
          // Specific variant
          String key = "${req.productId}|${req.variantName}";
          if ((availableQtys[key] ?? 0) >= req.quantity) {
             availableQtys[key] = (availableQtys[key]! - req.quantity).toInt();
          } else {
             qualifies = false;
             break;
          }
        } else {
          // Any variant of this product
          int needed = req.quantity;
          var matchingKeys = availableQtys.keys.where((k) => k.startsWith("${req.productId}|")).toList();
          for(var k in matchingKeys) {
            int canTake = availableQtys[k]!;
            if (canTake >= needed) {
              availableQtys[k] = canTake - needed;
              needed = 0;
              break;
            } else {
              needed -= canTake;
              availableQtys[k] = 0;
            }
          }
          if (needed > 0) {
            qualifies = false;
            break;
          }
        }
      }

      if (qualifies && !_ignoredPromoNames.contains(promo.name)) {
        double promoDiscount = 0;
        Set<CartItem> itemsToDiscount = {};

        for (var req in promo.requiredItems) {
           for (var item in _cart) {
              if (item.product.id == req.productId && !discountedProductIds.contains(item.product.id)) {
                 if (req.variantName == null || req.variantName == item.selectedVariant?.name) {
                    itemsToDiscount.add(item);
                 }
              }
           }
        }

        for (var item in itemsToDiscount) {
           promoDiscount += item.total * (promo.discountPercentage / 100);
           discountedProductIds.add(item.product.id);
        }
        
        if (promoDiscount > 0) {
          totalDiscount += promoDiscount;
          _appliedPromoNames.add(promo.name);
        }
      }
    }
    
    return totalDiscount;
  }

  double getTotal() {
    return getSubtotal() - getDiscount();
  }
}
