// lib/presentation/auth/auth_gateway.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import 'user_role.dart';
import 'user_session.dart';

/// Contrato abstracto para la autenticación en Reparto-Manager V2.
abstract class IAuthGateway {
  Future<Result<UserSession, DomainFailure>> signIn(
    String emailOrUser,
    String password,
  );
  Future<Result<void, DomainFailure>> sendInvitationOrResetEmail(String email);
  Future<void> signOut();
  UserSession? get currentUserSession;
}

/// Implementación robusta multiplataforma (Web / Desktop / Mobile)
/// utilizando la API REST oficial de Firebase Authentication (Google Identity Toolkit).
class FirebaseAuthGateway implements IAuthGateway {
  static const String _apiKey = 'AIzaSyCmYAizbCFOiytzHPM8zCYvkBc0tCKdKDo';
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

  final http.Client _client;
  UserSession? _cachedSession;

  FirebaseAuthGateway({http.Client? client}) : _client = client ?? http.Client();

  @override
  UserSession? get currentUserSession => _cachedSession;

  @override
  Future<Result<UserSession, DomainFailure>> signIn(
    String emailOrUser,
    String password,
  ) async {
    final email = _normalizeEmail(emailOrUser);
    final cleanPass = password.trim();

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl:signInWithPassword?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': cleanPass,
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final session = _buildSessionFromAuth(data, email);
        _cachedSession = session;
        return Result.ok(session);
      }

      final errorObj = data['error'] as Map<String, dynamic>?;
      final errorCode = errorObj?['message'] as String? ?? 'UNKNOWN_ERROR';

      // Auto-creación transparente de la cuenta maestra si aún no existe en Firebase Auth
      if ((errorCode.contains('EMAIL_NOT_FOUND') || errorCode.contains('INVALID_LOGIN_CREDENTIALS')) &&
          email == 'admin@mariabelen.com' &&
          cleanPass == 'admin123') {
        return await _signUpMasterAdmin(email, cleanPass);
      }

      return Result.fail(AuthFailure(_translateError(errorCode)));
    } catch (_) {
      return Result.fail(
        const AuthFailure('No se pudo conectar con el servidor. Verifique su conexión a internet.'),
      );
    }
  }

  @override
  Future<Result<void, DomainFailure>> sendInvitationOrResetEmail(
    String email,
  ) async {
    final normalized = _normalizeEmail(email);

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl:sendOobCode?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': normalized,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return Result.ok(null);
      }

      final errorObj = data['error'] as Map<String, dynamic>?;
      final errorCode = errorObj?['message'] as String? ?? 'UNKNOWN_ERROR';

      return Result.fail(AuthFailure(_translateError(errorCode)));
    } catch (_) {
      return Result.fail(
        const AuthFailure('No se pudo conectar con el servidor. Verifique su conexión a internet.'),
      );
    }
  }

  @override
  Future<void> signOut() async {
    _cachedSession = null;
  }

  Future<Result<UserSession, DomainFailure>> _signUpMasterAdmin(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl:signUp?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final session = _buildSessionFromAuth(data, email);
        _cachedSession = session;
        return Result.ok(session);
      }

      return Result.fail(
        const AuthFailure('Error al inicializar la cuenta maestra. Intente nuevamente.'),
      );
    } catch (_) {
      return Result.fail(
        const AuthFailure('No se pudo conectar con el servidor para crear la cuenta maestra.'),
      );
    }
  }

  String _normalizeEmail(String input) {
    final trimmed = input.trim();
    if (trimmed.toLowerCase() == 'admin') {
      return 'admin@mariabelen.com';
    }
    return trimmed;
  }

  UserSession _buildSessionFromAuth(Map<String, dynamic> data, String email) {
    final userId = data['localId'] as String? ?? 'usr_admin_maria_belen';
    return UserSession(
      tenantId: 'tenant_maria_belen',
      userId: userId,
      email: email,
      businessName: 'Distribuidora María Belén',
      role: UserRole.superadmin,
    );
  }

  String _translateError(String errorCode) {
    if (errorCode.contains('EMAIL_NOT_FOUND') ||
        errorCode.contains('INVALID_PASSWORD') ||
        errorCode.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (errorCode.contains('USER_DISABLED')) {
      return 'Esta cuenta de usuario ha sido suspendida.';
    }
    if (errorCode.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'Demasiados intentos fallidos. Por seguridad, intente en unos minutos.';
    }
    if (errorCode.contains('INVALID_EMAIL')) {
      return 'El formato del correo electrónico ingresado no es válido.';
    }
    if (errorCode.contains('EMAIL_EXISTS')) {
      return 'Este correo ya se encuentra registrado.';
    }
    if (errorCode.contains('WEAK_PASSWORD')) {
      return 'La contraseña debe contener al menos 6 caracteres.';
    }
    return 'No se pudo iniciar sesión. Verifique los datos ingresados.';
  }
}
