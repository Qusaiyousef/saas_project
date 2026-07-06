// lib/models/tenant_type.dart
enum TenantType {
  chalet,
  gym,
  pool,
}

extension TenantTypeExtension on TenantType {
  String get name {
    switch (this) {
      case TenantType.chalet:
        return 'Chalet';
      case TenantType.gym:
        return 'Gym';
      case TenantType.pool:
        return 'Pool';
    }
  }
}
