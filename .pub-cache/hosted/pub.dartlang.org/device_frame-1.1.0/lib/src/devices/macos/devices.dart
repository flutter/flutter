import 'package:device_frame/src/info/info.dart';
import 'package:flutter/widgets.dart';
import 'package:device_frame/src/devices/macos/macbook_pro/device.dart'
    as i_macbook_pro;

/// A set of macOS devices.
class MacOSDevices {
  const MacOSDevices();

  DeviceInfo get macBookPro => i_macbook_pro.info;
  DeviceInfo get wideMonitor => _wideMonitor;
  static final _wideMonitor = DeviceInfo.genericDesktopMonitor(
    platform: TargetPlatform.macOS,
    name: 'Large',
    id: 'large',
    screenSize: const Size(1920, 1080),
    windowPosition: Rect.fromCenter(
      center: const Offset(
        1920 * 0.5,
        1080 * 0.5,
      ),
      width: 1620,
      height: 780,
    ),
  );

  /// All available devices.
  List<DeviceInfo> get all => [
        macBookPro,
        wideMonitor,
      ];
}
