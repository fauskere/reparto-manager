import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';

class ClientsActions extends ChangeNotifier {
  static final ClientsActions _instance = ClientsActions._internal();
  factory ClientsActions() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Client> _clients = [];
  final List<String> _cities = [];         // Ciudades de clientes normales
  final List<String> _specialCities = [];   // Ciudades de clientes especiales
  final List<String> _resellerCities = [];  // Ciudades de revendedores
  
  String? _selectedFilterCity;

  List<Client> get clients {
    final list = _clients.where((c) => c.type == 'normal' && !c.hidden).toList();
    if (_selectedFilterCity == null || _selectedFilterCity!.isEmpty) {
      return list;
    }
    return list.where((c) => c.city == _selectedFilterCity).toList();
  }

  /// Clientes visibles en el Directorio principal: normales + especiales.
  /// Los revendedores tienen su propia sección y no aparecen aquí.
  List<Client> get directoryClients {
    final list = _clients.where((c) => (c.type == 'normal' || c.type == 'especial') && !c.hidden).toList();
    if (_selectedFilterCity == null || _selectedFilterCity!.isEmpty) {
      return list;
    }
    return list.where((c) => c.city == _selectedFilterCity).toList();
  }


  List<Client> get specialClients {
    final list = _clients.where((c) => c.type == 'especial' && !c.hidden).toList();
    if (_selectedFilterCity == null || _selectedFilterCity!.isEmpty || !_specialCities.contains(_selectedFilterCity)) {
      return list;
    }
    return list.where((c) => c.city == _selectedFilterCity).toList();
  }

  List<Client> get resellerClients {
    final list = _clients.where((c) => c.type == 'revendedor' && !c.hidden).toList();
    if (_selectedFilterCity == null || _selectedFilterCity!.isEmpty || !_resellerCities.contains(_selectedFilterCity)) {
      return list;
    }
    return list.where((c) => c.city == _selectedFilterCity).toList();
  }

  List<Client> get allClients => _clients;
  List<String> get cities => _cities;
  List<String> get specialCities => _specialCities;
  List<String> get resellerCities => _resellerCities;
  String? get selectedFilterCity => _selectedFilterCity;

  /// Actualiza el saldo del cliente en la lista local de forma INMEDIATA,
  /// sin esperar a que Firestore responda. Crucial para funcionamiento offline.
  void updateLocalBalance(String clientId, double delta) {
    final idx = _clients.indexWhere((c) => c.id == clientId);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate, lastVisitStatus: c.lastVisitStatus,
        balance: c.balance + delta,
        type: c.type, customPrices: c.customPrices,
        hidden: c.hidden,
      );
      notifyListeners();
    }
  }

  /// Marca visita en la lista local INMEDIATAMENTE (sin esperar Firestore).
  void markVisitLocal(String clientId, String status) {
    final today = DateTime.now().toString().substring(0, 10);
    final idx = _clients.indexWhere((c) => c.id == clientId);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: status.isEmpty ? '' : today,
        lastVisitStatus: status,
        balance: c.balance,
        type: c.type, customPrices: c.customPrices,
        hidden: c.hidden,
      );
      notifyListeners();
    }
  }

  ClientsActions._internal() {
    _selectedFilterCity = PreferencesService().getString('clients_city');
    _listenToClients();
  }

  void setFilterCity(String? city) {
    _selectedFilterCity = city;
    if (city == null) {
      PreferencesService().remove('clients_city');
    } else {
      PreferencesService().setString('clients_city', city);
    }
    notifyListeners();
  }

  void _listenToClients() {
    TenantDB.collection('clients').orderBy('name').snapshots().listen((snapshot) {
      _clients.clear();
      _cities.clear();
      _specialCities.clear();
      _resellerCities.clear();
      
      for (var doc in snapshot.docs) {
        final client = Client.fromMap(doc.data(), doc.id);
        _clients.add(client);
        
        final city = client.city.trim();
        if (city.isNotEmpty) {
          if (client.type == 'normal' && !_cities.contains(city)) {
            _cities.add(city);
          } else if (client.type == 'especial' && !_specialCities.contains(city)) {
            _specialCities.add(city);
          } else if (client.type == 'revendedor' && !_resellerCities.contains(city)) {
            _resellerCities.add(city);
          }
        }
      }
      
      _cities.sort();
      _specialCities.sort();
      _resellerCities.sort();
      
      // Auto-repair script para saldos corruptos por el bug de doble-click offline
      for (var c in _clients) {
        if (c.name.toLowerCase().contains('herrera') && c.balance == -52400) {
          TenantDB.collection('clients').doc(c.id).update({'balance': 0});
        }
        if (c.name.toLowerCase().contains('jorge') && c.balance < 0) {
          // El saldo de Jorge quedó muy negativo por los clicks repetidos
          TenantDB.collection('clients').doc(c.id).update({'balance': 54800});
        }
      }

      notifyListeners();
    });
  }

  Future<Client> addClient(String name, String phone, String city, String address, {String nickname = '', bool isOpenContinuous = false, String type = 'normal', Map<String, double> customPrices = const {}, bool hidden = false}) async {
    final docRef = TenantDB.collection('clients').doc();
    docRef.set({
      'name': name.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'nickname': nickname.trim(),
      'isOpenContinuous': isOpenContinuous,
      'lastVisitDate': '',
      'lastVisitStatus': '',
      'balance': 0.0,
      'type': type,
      'customPrices': customPrices,
      'hidden': hidden,
    }).catchError((e) => debugPrint("Error guardando cliente offline: $e"));

    final client = Client(
      id: docRef.id,
      name: name.trim(),
      phone: phone.trim(),
      city: city.trim(),
      address: address.trim(),
      nickname: nickname.trim(),
      isOpenContinuous: isOpenContinuous,
      lastVisitDate: '',
      lastVisitStatus: '',
      balance: 0.0,
      type: type,
      customPrices: customPrices,
      hidden: hidden,
    );

    _clients.add(client);
    
    final cityTrim = client.city.trim();
    if (cityTrim.isNotEmpty) {
      if (client.type == 'normal' && !_cities.contains(cityTrim)) {
        _cities.add(cityTrim);
      } else if (client.type == 'especial' && !_specialCities.contains(cityTrim)) {
        _specialCities.add(cityTrim);
      } else if (client.type == 'revendedor' && !_resellerCities.contains(cityTrim)) {
        _resellerCities.add(cityTrim);
      }
    }
    
    _cities.sort();
    _specialCities.sort();
    _resellerCities.sort();
    notifyListeners();
    return client;
  }

  Future<void> updateClient(String id, String name, String phone, String city, String address, {String nickname = '', bool isOpenContinuous = false, String? type, Map<String, double>? customPrices, bool? hidden}) async {
    final Map<String, dynamic> updateData = {
      'name': name.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'nickname': nickname.trim(),
      'isOpenContinuous': isOpenContinuous,
    };
    if (type != null) updateData['type'] = type;
    if (customPrices != null) updateData['customPrices'] = customPrices;
    if (hidden != null) {
      updateData['hidden'] = hidden;
    }
    await TenantDB.collection('clients').doc(id).update(updateData);
  }

  Future<void> hideClient(String id) async {
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate, lastVisitStatus: c.lastVisitStatus,
        balance: c.balance,
        type: c.type, customPrices: c.customPrices,
        hidden: true,
      );
      notifyListeners();
    }
    await TenantDB.collection('clients').doc(id).update({'hidden': true});
  }

  Future<void> restoreClient(String id) async {
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate, lastVisitStatus: c.lastVisitStatus,
        balance: c.balance,
        type: c.type, customPrices: c.customPrices,
        hidden: false,
      );
      notifyListeners();
    }
    await TenantDB.collection('clients').doc(id).update({'hidden': false});
  }

  Future<void> promoteToSpecial(String id) async {
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate, lastVisitStatus: c.lastVisitStatus,
        balance: c.balance,
        type: 'especial', customPrices: c.customPrices,
        hidden: c.hidden,
      );
      notifyListeners();
    }
    await TenantDB.collection('clients').doc(id).update({'type': 'especial'});
  }

  Future<void> demoteFromSpecial(String id) async {
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _clients[idx];
      _clients[idx] = Client(
        id: c.id, name: c.name, phone: c.phone, city: c.city,
        address: c.address, nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate, lastVisitStatus: c.lastVisitStatus,
        balance: c.balance,
        type: 'normal', customPrices: const {},
        hidden: c.hidden,
      );
      notifyListeners();
    }
    await TenantDB.collection('clients').doc(id).update({'type': 'normal', 'customPrices': const {}});
  }

  Future<void> toggleOpenContinuous(String id, bool currentValue) async {
    await TenantDB.collection('clients').doc(id).update({
      'isOpenContinuous': !currentValue,
    });
  }

  Future<void> markVisit(String id, String status) async {
    // Actualizar localmente de inmediato (funciona offline)
    markVisitLocal(id, status);
    // Sincronizar con Firestore en segundo plano
    final today = DateTime.now().toString().substring(0, 10);
    await TenantDB.collection('clients').doc(id).update({
      'lastVisitDate': status.isEmpty ? '' : today,
      'lastVisitStatus': status,
    });
  }

  void deleteClient(String id) {
    TenantDB.collection('clients').doc(id).delete();
  }

  Future<void> fixLincolnBalances() async {
    final bool? fixed = PreferencesService().getBool('lincoln_fixed');
    if (fixed == true) return;

    try {
      final clientsSnap = await TenantDB.collection('clients').get();
      final batch = _firestore.batch();
      
      for (var doc in clientsSnap.docs) {
        final name = (doc.data()['name'] ?? '').toString().toLowerCase();
        if (name.contains('brown') || name.contains('lucas') || name.contains('tellechea')) {
          final clientId = doc.id;
          double currentBalance = (doc.data()['balance'] ?? 0).toDouble();
          
          final salesSnap = await TenantDB.collection('sales').where('clientId', isEqualTo: clientId).get();
          double totalCorrection = 0.0;
          
          for (var saleDoc in salesSnap.docs) {
            final data = saleDoc.data();
            double saleTotal = (data['total'] ?? 0).toDouble();
            double salePaid = (data['paidAmount'] ?? 0).toDouble();
            
            if (salePaid > saleTotal && saleTotal > 0) {
              double diff = salePaid - saleTotal;
              print('Corrigiendo ticket ${saleDoc.id} de $salePaid a $saleTotal (Diff: $diff)');
              batch.update(saleDoc.reference, {'paidAmount': saleTotal});
              totalCorrection += diff;
            }
          }
          
          if (totalCorrection > 0) {
            double newBalance = currentBalance + totalCorrection;
            print('Cliente: $name | Balance actual: $currentBalance | Correccion: +$totalCorrection | Nuevo balance: $newBalance');
            batch.update(doc.reference, {'balance': newBalance});
          }
        }
      }
      
      await batch.commit();
      PreferencesService().setBool('lincoln_fixed', true);
      print('Lincoln balances fixed successfully!');
    } catch (e) {
      print('Error fixing Lincoln balances: $e');
    }
  }

  Future<void> fixVillegasBalances() async {
    final bool? fixed = PreferencesService().getBool('villegas_fixed');
    if (fixed == true) return;

    try {
      final clientsSnap = await TenantDB.collection('clients').where('city', isEqualTo: 'Villegas').get();
      print('Encontrados ${clientsSnap.docs.length} clientes en Villegas.');
      final batch = _firestore.batch();
      
      for (var doc in clientsSnap.docs) {
        final clientId = doc.id;
        
        final salesSnap = await TenantDB.collection('sales').where('clientId', isEqualTo: clientId).get();
        double totalSales = 0.0;
        double totalTicketsPaid = 0.0;
        
        for (var saleDoc in salesSnap.docs) {
          final data = saleDoc.data();
          double saleTotal = (data['total'] ?? 0).toDouble();
          double salePaid = (data['paidAmount'] ?? 0).toDouble();
          
          if (salePaid > saleTotal && saleTotal > 0) {
            print('Corrigiendo ticket ${saleDoc.id} de \$salePaid a \$saleTotal');
            salePaid = saleTotal;
            batch.update(saleDoc.reference, {'paidAmount': saleTotal});
          }
          
          totalSales += saleTotal;
          totalTicketsPaid += salePaid;
        }

        final paymentsSnap = await TenantDB.collection('payments').where('clientId', isEqualTo: clientId).get();
        double totalGeneralPayments = 0.0;
        for (var payDoc in paymentsSnap.docs) {
           if (payDoc.data()['type'] != 'sale_payment') {
             totalGeneralPayments += (payDoc.data()['amount'] ?? 0).toDouble();
           }
        }
        
        double correctBalance = totalSales - totalTicketsPaid - totalGeneralPayments;
        print('Cliente: ${doc.data()['name'] ?? clientId} | Ventas: \$totalSales | Tickets Pagados: \$totalTicketsPaid | Pagos Generales: \$totalGeneralPayments | Saldo Calculado: \$correctBalance');
        batch.update(doc.reference, {'balance': correctBalance});
      }
      
      await batch.commit();
      PreferencesService().setBool('villegas_fixed', true);
      print('Villegas balances fixed successfully!');
    } catch (e) {
      print('Error fixing Villegas balances: $e');
    }
  }
}

