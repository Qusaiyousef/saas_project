import '../l10n/app_strings.dart';

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

  String label(bool isAr) {
    switch (this) {
      case TenantType.chalet:
        return AppStrings.t('tenantChalet', isAr);
      case TenantType.gym:
        return AppStrings.t('tenantGym', isAr);
      case TenantType.pool:
        return AppStrings.t('tenantPool', isAr);
    }
  }
}
