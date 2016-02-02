// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/device_android.dart';
import 'application_package.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'build_configuration.dart';
import 'ios/device_ios.dart';
import 'toolchain.dart';

/// A class to get all available devices.
class DeviceManager {
  DeviceManager() {
    // Init the known discoverers.
    _deviceDiscoverers.add(new AndroidDeviceDiscovery());
    _deviceDiscoverers.add(new IOSDeviceDiscovery());
    _deviceDiscoverers.add(new IOSSimulatorDiscovery());

    Future.forEach(_deviceDiscoverers, (DeviceDiscovery discoverer) {
      if (!discoverer.supportsPlatform)
        return null;
      return discoverer.init();
    }).then((_) {
      _initedCompleter.complete();
    }).catchError((error, stackTrace) {
      _initedCompleter.completeError(error, stackTrace);
    });
  }

  List<DeviceDiscovery> _deviceDiscoverers = <DeviceDiscovery>[];

  Completer _initedCompleter = new Completer();

  /// Return the device with the matching ID; else, complete the Future with
  /// `null`.
  ///
  /// This does a case insentitive compare with `deviceId`.
  Future<Device> getDeviceById(String deviceId) async {
    deviceId = deviceId.toLowerCase();
    List<Device> devices = await getDevices();
    return devices.firstWhere(
      (Device device) => device.id.toLowerCase() == deviceId,
      orElse: () => null
    );
  }

  Future<List<Device>> getDevices() async {
    await _initedCompleter.future;

    return _deviceDiscoverers
      .where((DeviceDiscovery discoverer) => discoverer.supportsPlatform)
      .expand((DeviceDiscovery discoverer) => discoverer.devices)
      .toList();
  }
}

/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;
  Future init();
  List<Device> get devices;
}

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

  DeviceLogReader createLogReader();

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
    bool clearLogs: false,
    bool startPaused: false,
    int debugPort: observatoryDefaultPort,
    Map<String, dynamic> platformArgs
  });

  /// Stop an app package on the current device.
  Future<bool> stopApp(ApplicationPackage app);

  String toString() => '$runtimeType $id';
}

/// Read the log for a particular device. Subclasses must implement `hashCode`
/// and `operator ==` so that log readers that read from the same location can be
/// de-duped. For example, two Android devices will both try and log using
/// `adb logcat`; we don't want to display two identical log streams.
abstract class DeviceLogReader {
  String get name;

  Future<int> logs({ bool clear: false });

  int get hashCode;
  bool operator ==(dynamic other);

  String toString() => name;
}

// TODO(devoncarew): Unify this with [DeviceManager].
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
    } else if (devices.length == 1) {
      // Step 2: If no identifier is specified and there is only one connected
      // device, pick that one.
      device = devices[0];
    } else if (devices.length > 1) {
      // Step 3: D:
      printStatus('Multiple devices are connected, but no device ID was specified.');
      printStatus('Attempting to launch on all connected devices.');
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
          android = _deviceForConfig(config, getAdbDevices());
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
