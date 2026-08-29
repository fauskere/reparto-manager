import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/preferences_service.dart';

class TruckLoadSettings extends ChangeNotifier {
  static final TruckLoadSettings _instance = TruckLoadSettings._internal();
  factory TruckLoadSettings() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TruckLoadSettings._internal() {
    _loadLocalSettings();
    _listenToFirebaseConfig();
  }

  List<String> customOrder = [];
  String sortMethod = 'Personalizado'; // Personalizado, Nombre, Categoria, Precio
  bool isGridView = false;

  void _loadLocalSettings() {
    final prefs = PreferencesService();
    sortMethod = prefs.getString('truck_load_sort_method') ?? 'Personalizado';
    isGridView = prefs.getBool('truck_load_is_grid') ?? false;
  }

  void _listenToFirebaseConfig() {
    _db.collection('config').doc('truck_load').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('customOrder')) {
          customOrder = List<String>.from(data['customOrder'] ?? []);
          final localPreference = PreferencesService().getString('truck_load_sort_method');
          if (localPreference == null && customOrder.isNotEmpty) {
            sortMethod = 'Personalizado';
          }
          notifyListeners();
        }
      }
    });
  }

  Future<void> saveCustomOrder(List<String> order) async {
    customOrder = order;
    sortMethod = 'Personalizado';
    await PreferencesService().setString('truck_load_sort_method', 'Personalizado');
    await _db.collection('config').doc('truck_load').set({
      'customOrder': order,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> setSortMethod(String method) async {
    sortMethod = method;
    await PreferencesService().setString('truck_load_sort_method', sortMethod);
    notifyListeners();
  }

  Future<void> setGridView(bool isGrid) async {
    isGridView = isGrid;
    await PreferencesService().setBool('truck_load_is_grid', isGrid);
    notifyListeners();
  }
}
