import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic getter/setter
  String? getString(String key) => _prefs?.getString(key);
  Future<void> setString(String key, String value) async => await _prefs?.setString(key, value);
  Future<void> remove(String key) async => await _prefs?.remove(key);

  bool? getBool(String key) => _prefs?.getBool(key);
  Future<void> setBool(String key, bool value) async => await _prefs?.setBool(key, value);
}
