// lib/presentation/auth/user_role.dart

/// Roles del sistema basados en Control de Acceso Basado en Roles (RBAC).
enum UserRole {
  superadmin,
  owner,
  driver,
  cashier;

  String get displayName {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Administrador';
      case UserRole.owner:
        return 'Dueño de Comercio';
      case UserRole.driver:
        return 'Chofer / Repartidor';
      case UserRole.cashier:
        return 'Cajero de Mostrador';
    }
  }

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.superadmin;
    switch (value.trim().toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
      case 'admin':
        return UserRole.superadmin;
      case 'owner':
      case 'dueno':
        return UserRole.owner;
      case 'driver':
      case 'chofer':
      case 'repartidor':
        return UserRole.driver;
      case 'cashier':
      case 'cajero':
        return UserRole.cashier;
      default:
        return UserRole.owner;
    }
  }
}
