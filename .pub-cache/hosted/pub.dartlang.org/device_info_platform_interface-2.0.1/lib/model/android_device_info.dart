// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Information derived from `android.os.Build`.
///
/// See: https://developer.android.com/reference/android/os/Build.html
class AndroidDeviceInfo {
  /// Android device Info class.
  AndroidDeviceInfo({
    required this.version,
    required this.board,
    required this.bootloader,
    required this.brand,
    required this.device,
    required this.display,
    required this.fingerprint,
    required this.hardware,
    required this.host,
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.product,
    required List<String> supported32BitAbis,
    required List<String> supported64BitAbis,
    required List<String> supportedAbis,
    required this.tags,
    required this.type,
    required this.isPhysicalDevice,
    required this.androidId,
    required List<String> systemFeatures,
  })   : supported32BitAbis = List<String>.unmodifiable(supported32BitAbis),
        supported64BitAbis = List<String>.unmodifiable(supported64BitAbis),
        supportedAbis = List<String>.unmodifiable(supportedAbis),
        systemFeatures = List<String>.unmodifiable(systemFeatures);

  /// Android operating system version values derived from `android.os.Build.VERSION`.
  final AndroidBuildVersion version;

  /// The name of the underlying board, like "goldfish".
  ///
  /// The value is an empty String if it is not available.
  final String board;

  /// The system bootloader version number.
  ///
  /// The value is an empty String if it is not available.
  final String bootloader;

  /// The consumer-visible brand with which the product/hardware will be associated, if any.
  ///
  /// The value is an empty String if it is not available.
  final String brand;

  /// The name of the industrial design.
  ///
  /// The value is an empty String if it is not available.
  final String device;

  /// A build ID string meant for displaying to the user.
  ///
  /// The value is an empty String if it is not available.
  final String display;

  /// A string that uniquely identifies this build.
  ///
  /// The value is an empty String if it is not available.
  final String fingerprint;

  /// The name of the hardware (from the kernel command line or /proc).
  ///
  /// The value is an empty String if it is not available.
  final String hardware;

  /// Hostname.
  ///
  /// The value is an empty String if it is not available.
  final String host;

  /// Either a changelist number, or a label like "M4-rc20".
  ///
  /// The value is an empty String if it is not available.
  final String id;

  /// The manufacturer of the product/hardware.
  ///
  /// The value is an empty String if it is not available.
  final String manufacturer;

  /// The end-user-visible name for the end product.
  ///
  /// The value is an empty String if it is not available.
  final String model;

  /// The name of the overall product.
  ///
  /// The value is an empty String if it is not available.
  final String product;

  /// An ordered list of 32 bit ABIs supported by this device.
  final List<String> supported32BitAbis;

  /// An ordered list of 64 bit ABIs supported by this device.
  final List<String> supported64BitAbis;

  /// An ordered list of ABIs supported by this device.
  final List<String> supportedAbis;

  /// Comma-separated tags describing the build, like "unsigned,debug".
  ///
  /// The value is an empty String if it is not available.
  final String tags;

  /// The type of build, like "user" or "eng".
  ///
  /// The value is an empty String if it is not available.
  final String type;

  /// The value is `true` if the application is running on a physical device.
  ///
  /// The value is `false` when the application is running on a emulator, or the value is unavailable.
  final bool isPhysicalDevice;

  /// The Android hardware device ID that is unique between the device + user and app signing.
  ///
  /// The value is an empty String if it is not available.
  final String androidId;

  /// Describes what features are available on the current device.
  ///
  /// This can be used to check if the device has, for example, a front-facing
  /// camera, or a touchscreen. However, in many cases this is not the best
  /// API to use. For example, if you are interested in bluetooth, this API
  /// can tell you if the device has a bluetooth radio, but it cannot tell you
  /// if bluetooth is currently enabled, or if you have been granted the
  /// necessary permissions to use it. Please *only* use this if there is no
  /// other way to determine if a feature is supported.
  ///
  /// This data comes from Android's PackageManager.getSystemAvailableFeatures,
  /// and many of the common feature strings to look for are available in
  /// PackageManager's public documentation:
  /// https://developer.android.com/reference/android/content/pm/PackageManager
  final List<String> systemFeatures;

  /// Deserializes from the message received from [_kChannel].
  static AndroidDeviceInfo fromMap(Map<String, dynamic> map) {
    return AndroidDeviceInfo(
      version: AndroidBuildVersion._fromMap(map['version'] != null
          ? map['version'].cast<String, dynamic>()
          : <String, dynamic>{}),
      board: map['board'] ?? '',
      bootloader: map['bootloader'] ?? '',
      brand: map['brand'] ?? '',
      device: map['device'] ?? '',
      display: map['display'] ?? '',
      fingerprint: map['fingerprint'] ?? '',
      hardware: map['hardware'] ?? '',
      host: map['host'] ?? '',
      id: map['id'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'] ?? '',
      product: map['product'] ?? '',
      supported32BitAbis: _fromList(map['supported32BitAbis']),
      supported64BitAbis: _fromList(map['supported64BitAbis']),
      supportedAbis: _fromList(map['supportedAbis']),
      tags: map['tags'] ?? '',
      type: map['type'] ?? '',
      isPhysicalDevice: map['isPhysicalDevice'] ?? false,
      androidId: map['androidId'] ?? '',
      systemFeatures: _fromList(map['systemFeatures']),
    );
  }

  /// Deserializes message as List<String>
  static List<String> _fromList(dynamic message) {
    if (message == null) {
      return <String>[];
    }
    assert(message is List<dynamic>);
    final List<dynamic> list = List<dynamic>.from(message)
      ..removeWhere((value) => value == null);
    return list.cast<String>();
  }
}

/// Version values of the current Android operating system build derived from
/// `android.os.Build.VERSION`.
///
/// See: https://developer.android.com/reference/android/os/Build.VERSION.html
class AndroidBuildVersion {
  AndroidBuildVersion._({
    this.baseOS,
    this.previewSdkInt,
    this.securityPatch,
    required this.codename,
    required this.incremental,
    required this.release,
    required this.sdkInt,
  });

  /// The base OS build the product is based on.
  /// This is only available on Android 6.0 or above.
  String? baseOS;

  /// The developer preview revision of a prerelease SDK.
  /// This is only available on Android 6.0 or above.
  int? previewSdkInt;

  /// The user-visible security patch level.
  /// This is only available on Android 6.0 or above.
  final String? securityPatch;

  /// The current development codename, or the string "REL" if this is a release build.
  ///
  /// The value is an empty String if it is not available.
  final String codename;

  /// The internal value used by the underlying source control to represent this build.
  ///
  /// The value is an empty String if it is not available.
  final String incremental;

  /// The user-visible version string.
  ///
  /// The value is an empty String if it is not available.
  final String release;

  /// The user-visible SDK version of the framework.
  ///
  /// Possible values are defined in: https://developer.android.com/reference/android/os/Build.VERSION_CODES.html
  ///
  /// The value is -1 if it is unavailable.
  final int sdkInt;

  /// Deserializes from the map message received from [_kChannel].
  static AndroidBuildVersion _fromMap(Map<String, dynamic> map) {
    return AndroidBuildVersion._(
      baseOS: map['baseOS'],
      previewSdkInt: map['previewSdkInt'],
      securityPatch: map['securityPatch'],
      codename: map['codename'] ?? '',
      incremental: map['incremental'] ?? '',
      release: map['release'] ?? '',
      sdkInt: map['sdkInt'] ?? -1,
    );
  }
}
