import 'transport_type.dart';

/// Detected hardware, radio, and operating system capabilities for direct transport
class TransportCapabilities {
  final bool wifiDirectSupported;
  final bool wifiAwareSupported;
  final bool bleSupported;
  final bool isWifiEnabled;
  final bool isBleEnabled;
  final bool isAwareAvailable;
  final int sdkInt;

  const TransportCapabilities({
    this.wifiDirectSupported = false,
    this.wifiAwareSupported = false,
    this.bleSupported = false,
    this.isWifiEnabled = false,
    this.isBleEnabled = false,
    this.isAwareAvailable = false,
    this.sdkInt = 34,
  });

  factory TransportCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return TransportCapabilities(
      wifiDirectSupported: map['wifiDirectSupported'] == true,
      wifiAwareSupported: map['wifiAwareSupported'] == true,
      bleSupported: map['bleSupported'] == true,
      isWifiEnabled: map['isWifiEnabled'] == true,
      isBleEnabled: map['isBleEnabled'] == true,
      isAwareAvailable: map['isAwareAvailable'] == true,
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 34,
    );
  }

  /// Automatically resolves the optimal direct transport supported by this hardware
  TransportType get optimalTransport {
    if (wifiDirectSupported && isWifiEnabled) {
      return TransportType.wifiDirect;
    }
    if (wifiAwareSupported && isAwareAvailable) {
      return TransportType.wifiAware;
    }
    return TransportType.localNetwork;
  }

  /// Determines whether BLE assisted discovery should be engaged
  bool get canUseBleDiscovery => bleSupported && isBleEnabled;

  /// Android 13+ (API 33+) does not require Location permission when NEARBY_WIFI_DEVICES is granted
  bool get isAndroid13OrHigher => sdkInt >= 33;
}
