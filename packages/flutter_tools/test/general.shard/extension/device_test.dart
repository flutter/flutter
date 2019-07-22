// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension/device.dart';

import '../../src/common.dart';

void main() {
  test('Device can be serialized to json' , () {
    const Device device = Device(
      deviceName: 'test_device',
      deviceId: '1234',
      deviceCapabilities: DeviceCapabilities(
        supportsHotReload: false,
        supportsHotRestart: false,
        supportsScreenshot: false,
        supportsStartPaused: false,
      ),
      targetPlatform: TargetPlatform.linux,
      targetArchitecture: TargetArchitecture.x86,
      ephemeral: true,
      category: Category.desktop,
      sdkNameAndVersion: 'testy',
    );

    expect(device.toJson(), <String, Object>{
      'deviceName': 'test_device',
      'deviceId': '1234',
      'targetPlatform':  3,
      'targetArchitecture': 4,
      'ephemeral': true,
      'category': 1,
      'sdkNameAndVersion': 'testy',
      'deviceCapabilities': <String, Object>{
        'supportsHotReload': false,
        'supportsHotRestart': false,
        'supportsScreenshot': false,
        'supportsStartPaused': false,
      }
    });
  });
}