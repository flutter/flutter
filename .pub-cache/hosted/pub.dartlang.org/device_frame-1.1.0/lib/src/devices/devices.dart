import 'package:device_frame/src/info/info.dart';

import 'android/devices.dart';
import 'ios/devices.dart';
import 'linux/devices.dart';
import 'windows/devices.dart';
import 'macos/devices.dart';

/// A list of common device specifications sorted by target platform.
abstract class Devices {
  /// All iOS devices.
  static const ios = IosDevices();

  /// All macOS devices.
  static const macOS = MacOSDevices();

  /// All Android devices.
  static const android = AndroidDevices();

  /// All Windows devices.
  static const windows = WindowsDevices();

  /// All Linux devices.
  static const linux = LinuxDevices();

  /// All available devices.
  static List<DeviceInfo> get all => [
        ...ios.all,
        ...android.all,
        ...windows.all,
        ...macOS.all,
        ...linux.all,
      ];
}
