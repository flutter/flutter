// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Information derived from `UIDevice`.
///
/// See: https://developer.apple.com/documentation/uikit/uidevice
class IosDeviceInfo {
  /// IOS device info class.
  IosDeviceInfo({
    required this.name,
    required this.systemName,
    required this.systemVersion,
    required this.model,
    required this.localizedModel,
    required this.identifierForVendor,
    required this.isPhysicalDevice,
    required this.utsname,
  });

  /// Device name.
  ///
  /// The value is an empty String if it is not available.
  final String name;

  /// The name of the current operating system.
  ///
  /// The value is an empty String if it is not available.
  final String systemName;

  /// The current operating system version.
  ///
  /// The value is an empty String if it is not available.
  final String systemVersion;

  /// Device model.
  ///
  /// The value is an empty String if it is not available.
  final String model;

  /// Localized name of the device model.
  ///
  /// The value is an empty String if it is not available.
  final String localizedModel;

  /// Unique UUID value identifying the current device.
  ///
  /// The value is an empty String if it is not available.
  final String identifierForVendor;

  /// The value is `true` if the application is running on a physical device.
  ///
  /// The value is `false` when the application is running on a simulator, or the value is unavailable.
  final bool isPhysicalDevice;

  /// Operating system information derived from `sys/utsname.h`.
  ///
  /// The value is an empty String if it is not available.
  final IosUtsname utsname;

  /// Deserializes from the map message received from [_kChannel].
  static IosDeviceInfo fromMap(Map<String, dynamic> map) {
    return IosDeviceInfo(
      name: map['name'] ?? '',
      systemName: map['systemName'] ?? '',
      systemVersion: map['systemVersion'] ?? '',
      model: map['model'] ?? '',
      localizedModel: map['localizedModel'] ?? '',
      identifierForVendor: map['identifierForVendor'] ?? '',
      isPhysicalDevice: map['isPhysicalDevice'] != null
          ? map['isPhysicalDevice'] == 'true'
          : false,
      utsname: IosUtsname._fromMap(map['utsname'] != null
          ? map['utsname'].cast<String, dynamic>()
          : <String, dynamic>{}),
    );
  }
}

/// Information derived from `utsname`.
/// See http://pubs.opengroup.org/onlinepubs/7908799/xsh/sysutsname.h.html for details.
class IosUtsname {
  IosUtsname._({
    required this.sysname,
    required this.nodename,
    required this.release,
    required this.version,
    required this.machine,
  });

  /// Operating system name.
  ///
  /// The value is an empty String if it is not available.
  final String sysname;

  /// Network node name.
  ///
  /// The value is an empty String if it is not available.
  final String nodename;

  /// Release level.
  ///
  /// The value is an empty String if it is not available.
  final String release;

  /// Version level.
  ///
  /// The value is an empty String if it is not available.
  final String version;

  /// Hardware type (e.g. 'iPhone7,1' for iPhone 6 Plus).
  ///
  /// The value is an empty String if it is not available.
  final String machine;

  /// Deserializes from the map message received from [_kChannel].
  static IosUtsname _fromMap(Map<String, dynamic> map) {
    return IosUtsname._(
      sysname: map['sysname'] ?? '',
      nodename: map['nodename'] ?? '',
      release: map['release'] ?? '',
      version: map['version'] ?? '',
      machine: map['machine'] ?? '',
    );
  }
}
