/// Network trust classification produced by the Shield Engine.
enum NetworkTrustLevel {
  trusted,
  unknown,
  publicWifi,
  hostile;

  String get plainLabel {
    switch (this) {
      case NetworkTrustLevel.trusted:
        return 'Trusted Network';
      case NetworkTrustLevel.unknown:
        return 'Unknown Network';
      case NetworkTrustLevel.publicWifi:
        return 'Public Wi-Fi';
      case NetworkTrustLevel.hostile:
        return 'Hostile Network';
    }
  }

  bool get requiresShield =>
      this == NetworkTrustLevel.unknown ||
      this == NetworkTrustLevel.publicWifi ||
      this == NetworkTrustLevel.hostile;

  bool get requiresLockdown => this == NetworkTrustLevel.hostile;
}
