/// The 10 product protection modes.
enum ProtectionMode {
  home,
  work,
  publicWifi,
  travel,
  banking,
  gaming,
  childSafety,
  sleep,
  lockdown,
  custom;

  String get displayName {
    switch (this) {
      case ProtectionMode.home:
        return 'Home';
      case ProtectionMode.work:
        return 'Work';
      case ProtectionMode.publicWifi:
        return 'Public Wi-Fi';
      case ProtectionMode.travel:
        return 'Travel';
      case ProtectionMode.banking:
        return 'Banking';
      case ProtectionMode.gaming:
        return 'Gaming';
      case ProtectionMode.childSafety:
        return 'Child Safety';
      case ProtectionMode.sleep:
        return 'Sleep';
      case ProtectionMode.lockdown:
        return 'Lockdown';
      case ProtectionMode.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case ProtectionMode.home:
        return '🏠';
      case ProtectionMode.work:
        return '💼';
      case ProtectionMode.publicWifi:
        return '☕';
      case ProtectionMode.travel:
        return '✈️';
      case ProtectionMode.banking:
        return '🏦';
      case ProtectionMode.gaming:
        return '🎮';
      case ProtectionMode.childSafety:
        return '👶';
      case ProtectionMode.sleep:
        return '😴';
      case ProtectionMode.lockdown:
        return '🔒';
      case ProtectionMode.custom:
        return '⚙️';
    }
  }
}
