// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/device_android.dart';
import 'application_package.dart';
import 'base/logging.dart';
import 'build_configuration.dart';
import 'ios/device_ios.dart';
import 'toolchain.dart';

abstract class Device {
  final String id;
  static Map<String, Device> _deviceCache = {};

  static Device unique(String id, Device constructor(String id)) {
    return _deviceCache.putIfAbsent(id, () => constructor(id));
  }

  static void removeFromCache(String id) {
    _deviceCache.remove(id);
  }

  Device.fromId(this.id);

  String get name;

  /// Install an app package on the current device
  bool installApp(ApplicationPackage app);

  /// Check if the device is currently connected
  bool isConnected();

  /// Check if the current version of the given app is already installed
  bool isAppInstalled(ApplicationPackage app);

  TargetPlatform get platform;

  Future<int> logs({bool clear: false});

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call.
  Future<bool> startApp(
    ApplicationPackage package,
    Toolchain toolchain, {
    String mainPath,
    String route,
    bool checked: true,
    Map<String, dynamic> platformArgs
  });

  /// Stop an app package on the current device.
  Future<bool> stopApp(ApplicationPackage app);

  String toString() => '$runtimeType $id';
}

class DeviceStore {
  final AndroidDevice android;
  final IOSDevice iOS;
  final IOSSimulator iOSSimulator;

  List<Device> get all {
    List<Device> result = <Device>[];
    if (android != null)
      result.add(android);
    if (iOS != null)
      result.add(iOS);
    if (iOSSimulator != null)
      result.add(iOSSimulator);
    return result;
  }

  DeviceStore({
    this.android,
    this.iOS,
    this.iOSSimulator
  });

  static Device _deviceForConfig(BuildConfiguration config, List<Device> devices) {
    Device device = null;

    if (config.deviceId != null) {
      // Step 1: If a device identifier is specified, try to find a device
      // matching that specific identifier
      device = devices.firstWhere(
          (Device dev) => (dev.id == config.deviceId),
          orElse: () => null);
      if (device == null) {
        logging.severe('Warning: Device ID ${config.deviceId} not found');
      }
    } else if (devices.length == 1) {
      // Step 2: If no identifier is specified and there is only one connected
      // device, pick that one.
      device = devices[0];
    } else if (devices.length > 1) {
      // Step 3: D:
      logging.severe('Warning: Multiple devices are connected, but no device ID was specified.');
    }

    return device;
  }

  factory DeviceStore.forConfigs(List<BuildConfiguration> configs) {
    AndroidDevice android;
    IOSDevice iOS;
    IOSSimulator iOSSimulator;

    for (BuildConfiguration config in configs) {
      switch (config.targetPlatform) {
        case TargetPlatform.android:
          assert(android == null);
          android = _deviceForConfig(config, AndroidDevice.getAttachedDevices());
          break;
        case TargetPlatform.iOS:
          assert(iOS == null);
          iOS = _deviceForConfig(config, IOSDevice.getAttachedDevices());
          break;
        case TargetPlatform.iOSSimulator:
          assert(iOSSimulator == null);
          iOSSimulator = _deviceForConfig(config, IOSSimulator.getAttachedDevices());
          if (iOSSimulator == null) {
            // Creates a simulator with the default identifier
            iOSSimulator = new IOSSimulator();
          }
          break;
        case TargetPlatform.mac:
        case TargetPlatform.linux:
          break;
      }
    }

    return new DeviceStore(android: android, iOS: iOS, iOSSimulator: iOSSimulator);
  }
}
