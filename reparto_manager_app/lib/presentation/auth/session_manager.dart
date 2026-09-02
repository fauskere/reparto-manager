// lib/presentation/auth/session_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import 'auth_gateway.dart';
import 'user_session.dart';

/// Estados posibles de la sesión de usuario.
enum SessionState {
  unauthenticated,
  authenticating,
  authenticated,
}

/// Gestor de sesión global singleton para autenticación y soporte offline.
class SessionManager extends ChangeNotifier {
  static final SessionManager instance = SessionManager._internal();

  SessionManager._internal();

  static const String _sessionPrefKey = 'v2_saved_session';

  IAuthGateway? _gatewayInstance;
  SharedPreferences? _prefs;

  IAuthGateway get _gateway => _gatewayInstance ??= FirebaseAuthGateway();

  SessionState _state = SessionState.unauthenticated;
  UserSession? _currentSession;
  bool _isInitialized = false;

  SessionState get state => _state;
  UserSession? get currentSession => _currentSession;
  bool get isAuthenticated => _state == SessionState.authenticated;
  bool get isInitialized => _isInitialized;
  String get tenantId => _currentSession?.tenantId ?? 'tenant_maria_belen';

  /// Inicializa el gestor, restaura sesión offline recordada y configura gateway.
  Future<void> initialize({
    IAuthGateway? gateway,
    SharedPreferences? prefs,
  }) async {
    if (gateway != null) _gatewayInstance = gateway;
    _prefs = prefs ?? await SharedPreferences.getInstance();

    final savedJson = _prefs?.getString(_sessionPrefKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        _currentSession = UserSession.fromJson(map);
        _state = SessionState.authenticated;
      } catch (_) {
        _state = SessionState.unauthenticated;
      }
    } else {
      _state = SessionState.unauthenticated;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Inicia sesión con credenciales, resuelve tenant y persiste si rememberMe es true.
  Future<Result<UserSession, DomainFailure>> signIn(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    _state = SessionState.authenticating;
    notifyListeners();

    final result = await _gateway.signIn(email, password);

    switch (result) {
      case Success(:final value):
        _currentSession = value;
        _state = SessionState.authenticated;
        if (rememberMe && _prefs != null) {
          await _prefs!.setString(_sessionPrefKey, jsonEncode(value.toJson()));
        } else if (!rememberMe && _prefs != null) {
          await _prefs!.remove(_sessionPrefKey);
        }
        notifyListeners();
        return Result.ok(value);
      case Failure(:final error):
        _currentSession = null;
        _state = SessionState.unauthenticated;
        notifyListeners();
        return Result.fail(error);
    }
  }

  /// Envía un correo seguro de activación o recuperación de contraseña.
  /// Si [isSelfPasswordReset] es false, exige que la sesión activa tenga rol superadmin.
  Future<Result<void, DomainFailure>> sendInvitationOrResetEmail(
    String email, {
    bool isSelfPasswordReset = false,
  }) async {
    if (!isSelfPasswordReset) {
      if (_currentSession == null || !_currentSession!.isSuperAdmin) {
        return Result.fail(
          const AuthFailure(
            'Acceso denegado: Únicamente el usuario SuperAdmin tiene permisos para enviar invitaciones o gestionar cuentas.',
          ),
        );
      }
    }
    return await _gateway.sendInvitationOrResetEmail(email);
  }

  /// Cierra la sesión activa en Firebase y limpia la caché local.
  Future<void> signOut() async {
    await _gateway.signOut();
    if (_prefs != null) {
      await _prefs!.remove(_sessionPrefKey);
    }
    _currentSession = null;
    _state = SessionState.unauthenticated;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTesting() {
    _state = SessionState.unauthenticated;
    _currentSession = null;
    _isInitialized = false;
  }
}
