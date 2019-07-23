// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tool extensions for interfacing with a flutter capable device.
library device;

import 'package:meta/meta.dart';

import 'extension.dart';

/// A description of the kind of workflow the device supports.
///
/// This information provides hints to IDEs and edtiors that
/// integrate with the flutter tool.
class Category implements Serializable {
  const Category._(this._value);

  /// Create a new [Category] from a json object.
  ///
  /// Throws [ArgumentError] if provided with an invalid value.
  factory Category.fromJson(int value) {
    switch (value) {
      case 0:
        return web;
      case 1:
        return desktop;
      case 2:
        return mobile;
    }
    throw ArgumentError.value(value);
  }

  /// A category of devices with a web workflow.
  static const Category web = Category._(0);

  /// A category of devices with a desktop workflow.
  static const Category desktop = Category._(1);

  /// A category of devices with a mobile workflow.
  static const Category mobile = Category._(2);

  final int _value;

  @override
  Object toJson() {
    return _value;
  }
}

/// A description of the platform Rlutter will run on.
class TargetPlatform implements Serializable {
  const TargetPlatform._(this._value);

  /// Create a new [TargetPlatform] from a json encoded value.
  ///
  /// Throws [ArgumentError] if an invalid value is provided.
  factory TargetPlatform.fromJson(int value) {
    switch (value){
      case 0:
        return android;
      case 1:
        return iOS;
      case 2:
        return windows;
      case 3:
        return linux;
      case 4:
        return macOS;
      case 5:
        return fuchsia;
      case 6:
        return web;
    }
    throw ArgumentError.value(value);
  }

  /// An Android device or emulator.
  static const TargetPlatform android = TargetPlatform._(0);

  /// An iOS device or simulator.
  static const TargetPlatform iOS = TargetPlatform._(1);

  /// A Windows desktop device.
  static const TargetPlatform windows = TargetPlatform._(2);

  /// A Linux desktop device.
  static const TargetPlatform linux = TargetPlatform._(3);

  /// A macOS desktop device.
  static const TargetPlatform macOS = TargetPlatform._(4);

  /// A Fuchsia device.
  static const TargetPlatform fuchsia = TargetPlatform._(5);

  /// A web browser.
  static const TargetPlatform web = TargetPlatform._(6);

  final int _value;

  @override
  Object toJson() {
    return _value;
  }
}

/// A description of the targeted device architecture.
class TargetArchitecture implements Serializable  {
  const TargetArchitecture._(this._value);

  /// Create a new [TargetArchitecture] from a json encuded value.
  factory TargetArchitecture.fromJson(int value) {
    switch (value) {
      case 0:
        return armv7;
      case 1:
        return arm64;
      case 2:
        return armeabi_v7a;
      case 3:
        return arm64_v8a;
      case 4:
        return x86;
      case 5:
        return x86_64;
      case 6:
        return javascript;
    }
    throw ArgumentError.value(value);
  }

  /// An armv7 architecture specifically for iOS.
  static const TargetArchitecture armv7 = TargetArchitecture._(0);

  /// An arm64 architecture specifically for iOS.
  static const TargetArchitecture arm64 = TargetArchitecture._(1);

  /// An armebi_v7a architecture.
  static const TargetArchitecture armeabi_v7a = TargetArchitecture._(2);

  // An arm64_v8a architecture.
  static const TargetArchitecture arm64_v8a = TargetArchitecture._(3);

  /// An x86 architecture.
  static const TargetArchitecture x86 = TargetArchitecture._(4);

  /// An x86-64 architecture.
  static const TargetArchitecture x86_64 = TargetArchitecture._(5);

  /// A JavaScript-compiled application.
  static const TargetArchitecture javascript = TargetArchitecture._(6);

  final int _value;

  @override
  String toString() => _value.toString();

  @override
  Object toJson() {
    return _value;
  }
}

/// The configuration for a particular device type.
class Device implements Serializable {
  /// Create a new [Device].
  ///
  /// All fields except for [ephemeral] and [category] are required to be
  /// non-null.
  const Device({
    @required this.deviceName,
    @required this.deviceId,
    @required this.deviceCapabilities,
    @required this.targetPlatform,
    @required this.targetArchitecture,
    @required this.sdkNameAndVersion,
    this.ephemeral,
    this.category,
  }) : assert(deviceName != null),
       assert(deviceId != null),
       assert(deviceCapabilities != null),
       assert(targetPlatform != null),
       assert(targetArchitecture != null),
       assert(sdkNameAndVersion != null);

  /// The name of this device.
  ///
  /// For example: 'Google Pixel 2'.
  final String deviceName;

  /// An identifier for this device.
  ///
  /// For mobile devices this identifier is often exposed via platform
  /// specific tooling such as adb. For non-ephemeral devices, this may
  /// be somewhat arbitrary. For example, 'macos' for a macOS desktop
  /// device.
  ///
  /// This identifier is expected to be unique among the devices returned from
  /// a particular tool extension, but otherwise global uniqueness is
  /// guaranteed via name-spacing.
  final String deviceId;

  /// The capabilities of this device.
  final DeviceCapabilities deviceCapabilities;

  /// The target platform this device type represents.
  final TargetPlatform targetPlatform;

  /// The target architecture required by this device type.
  final TargetArchitecture targetArchitecture;

  /// Whether this device represents something that can be connected or
  /// disconnected.
  ///
  /// For example, an Android or iOS device would be ephemeral. The browser
  /// used by web applications would not.
  final bool ephemeral;

  /// The kind of workflow the device provides.
  ///
  /// This information is used to give hints to editors and IDEs about the
  /// device type. If not provided, defaults to null.
  final Category category;

  /// The name and version of this device.
  ///
  /// For example: 'Mac OS X 10.14.5 18F132'. If not provided, defaults to
  /// null.
  final String sdkNameAndVersion;

  @override
  Object toJson() {
    return <String, Object>{
      'deviceName': deviceName,
      'deviceId': deviceId,
      'deviceCapabilities': deviceCapabilities.toJson(),
      'targetPlatform': targetPlatform.toJson(),
      'targetArchitecture': targetArchitecture.toJson(),
      'ephemeral': ephemeral,
      'category': category.toJson(),
      'sdkNameAndVersion': sdkNameAndVersion,
    };
  }
}

/// A list of device configurations.
class DeviceList implements Serializable {
  const DeviceList({ @required this.devices })
    : assert(devices != null);

  /// Zero or more supported device configurations.
  final List<Device> devices;

  @override
  Object toJson() {
    return <String, Object>{
      'devices': <Object>[
        for (Device device in devices) device.toJson()
      ],
    };
  }

}

/// The capabilities of a particular device type.
class DeviceCapabilities implements Serializable {
  /// Create a new [DeviceCapabilties].
  const DeviceCapabilities({
    this.supportsHotReload = true,
    this.supportsHotRestart = true,
    this.supportsScreenshot = true,
    this.supportsStartPaused = true,
  });

  /// Whether applications running on this device can be hot reloaded.
  ///
  /// If not provided, defaults to true.
  final bool supportsHotReload;

  /// Whether applications running on this device can be hot restarted.
  ///
  /// If not provided, defaults to true.
  final bool supportsHotRestart;

  /// Whether the device supports taking a screenshot.
  ///
  /// If not provided, defaults to true.
  final bool supportsScreenshot;

  /// Whether the device can be stated with the main isolate paused.
  ///
  /// If not provided, defaults to true.
  final bool supportsStartPaused;

  @override
  Object toJson() {
    return <String, Object>{
      'supportsHotReload': supportsHotReload,
      'supportsHotRestart': supportsHotRestart,
      'supportsScreenshot': supportsScreenshot,
      'supportsStartPaused': supportsStartPaused,
    };
  }
}

/// Functionality related to configuring and launching devices.
abstract class DeviceDomain extends Domain {

  /// The tool is requesting that any supported devices are listed.
  Future<DeviceList> listDevices();
}
