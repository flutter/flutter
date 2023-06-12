// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel/method_channel_device_info.dart';
import 'model/android_device_info.dart';
import 'model/ios_device_info.dart';
export 'model/android_device_info.dart';
export 'model/ios_device_info.dart';

/// The interface that implementations of device_info must implement.
///
/// Platform implementations should extend this class rather than implement it as `device_info`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [DeviceInfoPlatform] methods.
abstract class DeviceInfoPlatform extends PlatformInterface {
  /// Constructs a DeviceInfoPlatform.
  DeviceInfoPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceInfoPlatform _instance = MethodChannelDeviceInfo();

  /// The default instance of [DeviceInfoPlatform] to use.
  ///
  /// Defaults to [MethodChannelDeviceInfo].
  static DeviceInfoPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [DeviceInfoPlatform] when they register themselves.
  static set instance(DeviceInfoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the Android device information.
  Future<AndroidDeviceInfo> androidInfo() {
    throw UnimplementedError('androidInfo() has not been implemented.');
  }

  /// Gets the iOS device information.
  Future<IosDeviceInfo> iosInfo() {
    throw UnimplementedError('iosInfo() has not been implemented.');
  }
}
