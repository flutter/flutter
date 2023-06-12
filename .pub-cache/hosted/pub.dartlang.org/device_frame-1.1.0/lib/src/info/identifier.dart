import 'package:flutter/foundation.dart';

import 'device_type.dart';

/// A unique identifier that represents a device.
///
/// See also :
///
/// * [loadDeviceInfo] to load information store in assets.
/// * [DeviceFrame] to display the frame associated to one of identifiers.
class DeviceIdentifier {
  /// The unique name of the device (preferably in snake case).
  final String name;

  /// The device form factor.
  final DeviceType type;

  /// The target platform supported by this device.
  final TargetPlatform platform;

  /// Private constructor.
  const DeviceIdentifier(
    this.platform,
    this.type,
    this.name,
  );

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is DeviceIdentifier &&
            other.name == name &&
            other.type == type &&
            other.platform == platform);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ name.hashCode ^ type.hashCode ^ platform.hashCode;

  @override
  String toString() {
    final platformKey =
        platform.toString().replaceAll('$TargetPlatform.', '').toLowerCase();
    final typeKey =
        type.toString().replaceAll('$DeviceType.', '').toLowerCase();
    return '${platformKey}_${typeKey}_$name';
  }
}
