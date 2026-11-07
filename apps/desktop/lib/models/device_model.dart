class NexoraDevice {
  final String deviceId;
  final String displayName;
  final String platform;
  final String fingerprint;
  final String? address;
  final int? port;
  final bool isTrusted;
  final DateTime lastSeen;

  const NexoraDevice({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.fingerprint,
    this.address,
    this.port,
    this.isTrusted = false,
    required this.lastSeen,
  });

  NexoraDevice copyWith({
    String? deviceId,
    String? displayName,
    String? platform,
    String? fingerprint,
    String? address,
    int? port,
    bool? isTrusted,
    DateTime? lastSeen,
  }) {
    return NexoraDevice(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      platform: platform ?? this.platform,
      fingerprint: fingerprint ?? this.fingerprint,
      address: address ?? this.address,
      port: port ?? this.port,
      isTrusted: isTrusted ?? this.isTrusted,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
