// lib/presentation/auth/user_session.dart
import 'package:flutter/foundation.dart';
import 'user_role.dart';

/// Representa la sesión inmutable de un usuario autenticado en Reparto-Manager V2.
@immutable
class UserSession {
  final String tenantId;
  final String userId;
  final String email;
  final String businessName;
  final UserRole role;

  const UserSession({
    required this.tenantId,
    required this.userId,
    required this.email,
    required this.businessName,
    this.role = UserRole.superadmin,
  });

  bool get isSuperAdmin => role == UserRole.superadmin;
  bool get isOwner => role == UserRole.owner;
  bool get isDriver => role == UserRole.driver;
  bool get cashier => role == UserRole.cashier;
  bool get isCashier => role == UserRole.cashier;
  bool get canManageUsers => role == UserRole.superadmin;
  bool get canInviteTenants => role == UserRole.superadmin;

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'userId': userId,
        'email': email,
        'businessName': businessName,
        'role': role.name,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      tenantId: json['tenantId'] as String? ?? 'tenant_maria_belen',
      userId: json['userId'] as String? ?? 'usr_admin_maria_belen',
      email: json['email'] as String? ?? 'admin@mariabelen.com',
      businessName:
          json['businessName'] as String? ?? 'Distribuidora María Belén',
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          runtimeType == other.runtimeType &&
          tenantId == other.tenantId &&
          userId == other.userId &&
          email == other.email &&
          businessName == other.businessName &&
          role == other.role;

  @override
  int get hashCode => Object.hash(tenantId, userId, email, businessName, role);

  @override
  String toString() =>
      'UserSession(tenantId: $tenantId, userId: $userId, email: $email, business: $businessName, role: ${role.name})';
}
