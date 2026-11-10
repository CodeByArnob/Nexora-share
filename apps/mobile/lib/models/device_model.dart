class NexoraDevice {
  final String deviceId;
  final String displayName;
  final String platform;
  final String fingerprint;
  final String? address;
  final int? port;
  final bool isTrusted;
  final DateTime lastSeen;
  final String? transportHint;
  final String? directMac;

  const NexoraDevice({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    this.fingerprint = '',
    this.address,
    this.port,
    this.isTrusted = false,
    required this.lastSeen,
    this.transportHint,
    this.directMac,
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
    String? transportHint,
    String? directMac,
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
      transportHint: transportHint ?? this.transportHint,
      directMac: directMac ?? this.directMac,
    );
  }
}
