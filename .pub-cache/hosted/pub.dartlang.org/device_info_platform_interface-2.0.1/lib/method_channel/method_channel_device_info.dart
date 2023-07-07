// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:device_info_platform_interface/device_info_platform_interface.dart';

/// An implementation of [DeviceInfoPlatform] that uses method channels.
class MethodChannelDeviceInfo extends DeviceInfoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  MethodChannel channel = MethodChannel('plugins.flutter.io/device_info');

  // Method channel for Android devices
  Future<AndroidDeviceInfo> androidInfo() async {
    return AndroidDeviceInfo.fromMap((await channel
            .invokeMapMethod<String, dynamic>('getAndroidDeviceInfo')) ??
        <String, dynamic>{});
  }

  // Method channel for iOS devices
  Future<IosDeviceInfo> iosInfo() async {
    return IosDeviceInfo.fromMap(
        (await channel.invokeMapMethod<String, dynamic>('getIosDeviceInfo')) ??
            <String, dynamic>{});
  }
}
