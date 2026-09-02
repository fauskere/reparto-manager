import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/presentation/auth/auth_gateway.dart';
import 'package:reparto_manager_app/presentation/auth/session_manager.dart';
import 'package:reparto_manager_app/presentation/auth/user_role.dart';
import 'package:reparto_manager_app/presentation/auth/user_session.dart';

class FakeAuthGateway implements IAuthGateway {
  bool shouldFail = false;
  String? failMessage;
  UserSession? currentMockSession;
  String? lastResetEmailRequested;
  UserRole roleToAssign = UserRole.superadmin;

  @override
  UserSession? get currentUserSession => currentMockSession;

  @override
  Future<Result<UserSession, DomainFailure>> signIn(
    String email,
    String password,
  ) async {
    if (shouldFail) {
      return Result.fail(
        AuthFailure(failMessage ?? 'Credenciales inválidas.'),
      );
    }
    final session = UserSession(
      tenantId: 'tenant_maria_belen',
      userId: 'usr_admin_maria_belen',
      email: email == 'admin' ? 'admin@mariabelen.com' : email,
      businessName: 'Distribuidora María Belén',
      role: roleToAssign,
    );
    currentMockSession = session;
    return Result.ok(session);
  }

  @override
  Future<Result<void, DomainFailure>> sendInvitationOrResetEmail(
    String email,
  ) async {
    lastResetEmailRequested = email;
    if (shouldFail) {
      return Result.fail(
        AuthFailure(failMessage ?? 'Error al enviar correo.'),
      );
    }
    return Result.ok(null);
  }

  @override
  Future<void> signOut() async {
    currentMockSession = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthGateway fakeGateway;
  final manager = SessionManager.instance;

  setUp(() {
    fakeGateway = FakeAuthGateway();
    manager.resetForTesting();
  });

  group('SessionManager - Pruebas Unitarias de Autenticación & RBAC', () {
    test('1. initialize() sin sesión previa arranca en unauthenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      expect(manager.state, SessionState.unauthenticated);
      expect(manager.isAuthenticated, isFalse);
      expect(manager.currentSession, isNull);
      expect(manager.tenantId, 'tenant_maria_belen');
    });

    test('2. initialize() restaura sesión offline previa con rol driver', () async {
      const savedSession = UserSession(
        tenantId: 'tenant_sucursal_sur',
        userId: 'usr_offline_456',
        email: 'reparto@mariabelen.com',
        businessName: 'María Belén Sucursal Sur',
        role: UserRole.driver,
      );

      SharedPreferences.setMockInitialValues({
        'v2_saved_session': jsonEncode(savedSession.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();

      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      expect(manager.state, SessionState.authenticated);
      expect(manager.isAuthenticated, isTrue);
      expect(manager.currentSession, isNotNull);
      expect(manager.currentSession!.isDriver, isTrue);
      expect(manager.currentSession!.isSuperAdmin, isFalse);
      expect(manager.currentSession!.canManageUsers, isFalse);
      expect(manager.tenantId, 'tenant_sucursal_sur');
    });

    test('3. signIn() con alias "admin" autentica superadmin y persiste', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      final result = await manager.signIn(
        'admin',
        'admin123',
        rememberMe: true,
      );

      expect(result.isSuccess, isTrue);
      expect(manager.state, SessionState.authenticated);
      expect(manager.isAuthenticated, isTrue);
      expect(manager.currentSession?.email, 'admin@mariabelen.com');
      expect(manager.currentSession?.isSuperAdmin, isTrue);
      expect(manager.currentSession?.canManageUsers, isTrue);
      expect(manager.tenantId, 'tenant_maria_belen');

      final persistedJson = prefs.getString('v2_saved_session');
      expect(persistedJson, isNotNull);
      expect(persistedJson, contains('admin@mariabelen.com'));
    });

    test('4. signIn() con error retorna AuthFailure y mantiene estado unauthenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      fakeGateway.shouldFail = true;
      fakeGateway.failMessage = 'Contraseña incorrecta.';

      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      final result = await manager.signIn(
        'admin',
        'wrong_pass',
      );

      expect(result.isFailure, isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Contraseña incorrecta.');
        },
        (_) => fail('No debe ser exitoso'),
      );
      expect(manager.state, SessionState.unauthenticated);
      expect(manager.isAuthenticated, isFalse);
    });

    test('5. sendInvitationOrResetEmail(isSelfPasswordReset: true) funciona desde login', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      final result = await manager.sendInvitationOrResetEmail(
        'admin@mariabelen.com',
        isSelfPasswordReset: true,
      );

      expect(result.isSuccess, isTrue);
      expect(fakeGateway.lastResetEmailRequested, 'admin@mariabelen.com');
    });

    test('6. sendInvitationOrResetEmail() exige rol superadmin para invitar comercios/choferes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      fakeGateway.roleToAssign = UserRole.driver;

      await manager.initialize(gateway: fakeGateway, prefs: prefs);
      await manager.signIn('chofer@mariabelen.com', 'pass123');

      expect(manager.currentSession?.isDriver, isTrue);
      expect(manager.currentSession?.isSuperAdmin, isFalse);

      final result = await manager.sendInvitationOrResetEmail('nuevo_cliente@correo.com');

      expect(result.isFailure, isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, contains('Únicamente el usuario SuperAdmin'));
        },
        (_) => fail('No debe permitir invitar sin superadmin'),
      );
    });

    test('7. SuperAdmin puede enviar invitaciones corporativas', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      fakeGateway.roleToAssign = UserRole.superadmin;

      await manager.initialize(gateway: fakeGateway, prefs: prefs);
      await manager.signIn('admin', 'admin123');

      final result = await manager.sendInvitationOrResetEmail('nuevo_chofer@mariabelen.com');

      expect(result.isSuccess, isTrue);
      expect(fakeGateway.lastResetEmailRequested, 'nuevo_chofer@mariabelen.com');
    });

    test('8. signOut() cierra sesión y borra datos recordados', () async {
      final session = const UserSession(
        tenantId: 'tenant_maria_belen',
        userId: 'usr_789',
        email: 'admin@mariabelen.com',
        businessName: 'Distribuidora María Belén',
        role: UserRole.superadmin,
      );
      SharedPreferences.setMockInitialValues({
        'v2_saved_session': jsonEncode(session.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      await manager.initialize(gateway: fakeGateway, prefs: prefs);

      expect(manager.isAuthenticated, isTrue);

      await manager.signOut();

      expect(manager.state, SessionState.unauthenticated);
      expect(manager.isAuthenticated, isFalse);
      expect(manager.currentSession, isNull);
      expect(prefs.getString('v2_saved_session'), isNull);
    });
  });
}
