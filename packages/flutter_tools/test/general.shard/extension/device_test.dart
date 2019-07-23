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

  test('Device.deviceName must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: 'tester',
      deviceName: null,
      deviceCapabilities: const DeviceCapabilities(),
      deviceId: '2',
      targetArchitecture: TargetArchitecture.arm64,
      targetPlatform: TargetPlatform.iOS,
    ), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Device.deviceId must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: 'tester',
      deviceName: 'non-null',
      deviceCapabilities: const DeviceCapabilities(),
      deviceId: null,
      targetArchitecture: TargetArchitecture.arm64,
      targetPlatform: TargetPlatform.iOS,
    ), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Device.deviceCapabilities must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: 'tester',
      deviceName: '23',
      deviceCapabilities: null,
      deviceId: '2',
      targetArchitecture: TargetArchitecture.arm64,
      targetPlatform: TargetPlatform.iOS,
    ), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Device.targetPlatform must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: 'tester',
      deviceName: 'test',
      deviceCapabilities: const DeviceCapabilities(),
      deviceId: '2',
      targetArchitecture: TargetArchitecture.arm64,
      targetPlatform: null,
    ), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Device.targetArchitecture must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: 'tester',
      deviceName: 'tester',
      deviceCapabilities: const DeviceCapabilities(),
      deviceId: '2',
      targetArchitecture: null,
      targetPlatform: TargetPlatform.iOS,
    ), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Device.sdkNameAndVersion must be non-null', () {
    expect(() => Device(
      sdkNameAndVersion: null,
      deviceName: 'tester',
      deviceCapabilities: const DeviceCapabilities(),
      deviceId: '2',
      targetArchitecture: TargetArchitecture.arm64,
      targetPlatform: TargetPlatform.iOS,
    ), throwsA(isInstanceOf<AssertionError>()));
  });
  
  test('Category can be serialized to json', () {
    expect(Category.web.toJson(), 0);
    expect(Category.desktop.toJson(), 1);
    expect(Category.mobile.toJson(), 2);
  });

  test('Category can be deserialized from json', () {
    expect(Category.fromJson(0), Category.web);
    expect(Category.fromJson(1), Category.desktop);
    expect(Category.fromJson(2), Category.mobile);
    expect(() => Category.fromJson(4), throwsA(isInstanceOf<ArgumentError>()));
  });

  test('TargetPlatform can be serialized to json', () {
    expect(TargetPlatform.android.toJson(), 0);
    expect(TargetPlatform.iOS.toJson(), 1);
    expect(TargetPlatform.windows.toJson(), 2);
    expect(TargetPlatform.linux.toJson(), 3);
    expect(TargetPlatform.macOS.toJson(), 4);
    expect(TargetPlatform.fuchsia.toJson(), 5);
    expect(TargetPlatform.web.toJson(), 6);
  });

  test('TargetPlatform can be deserialized from json', () {
    expect(TargetPlatform.fromJson(0), TargetPlatform.android);
    expect(TargetPlatform.fromJson(1), TargetPlatform.iOS);
    expect(TargetPlatform.fromJson(2), TargetPlatform.windows);
    expect(TargetPlatform.fromJson(3), TargetPlatform.linux);
    expect(TargetPlatform.fromJson(4), TargetPlatform.macOS);
    expect(TargetPlatform.fromJson(5), TargetPlatform.fuchsia);
    expect(TargetPlatform.fromJson(6), TargetPlatform.web);
    expect(() => TargetPlatform.fromJson(7), throwsA(isInstanceOf<ArgumentError>()));
  });

  test('TargetArchitecture can be serialized to json', () {
    expect(TargetArchitecture.armv7.toJson(), 0);
    expect(TargetArchitecture.arm64.toJson(), 1);
    expect(TargetArchitecture.armeabi_v7a.toJson(), 2);
    expect(TargetArchitecture.arm64_v8a.toJson(), 3);
    expect(TargetArchitecture.x86.toJson(), 4);
    expect(TargetArchitecture.x86_64.toJson(), 5);
    expect(TargetArchitecture.javascript.toJson(), 6);
  });

  test('TargetArchitecture can be deserialized from json', () {
    expect(TargetArchitecture.fromJson(0), TargetArchitecture.armv7);
    expect(TargetArchitecture.fromJson(1), TargetArchitecture.arm64);
    expect(TargetArchitecture.fromJson(2), TargetArchitecture.armeabi_v7a);
    expect(TargetArchitecture.fromJson(3), TargetArchitecture.arm64_v8a);
    expect(TargetArchitecture.fromJson(4), TargetArchitecture.x86);
    expect(TargetArchitecture.fromJson(5), TargetArchitecture.x86_64);
    expect(TargetArchitecture.fromJson(6), TargetArchitecture.javascript);
    expect(() => TargetArchitecture.fromJson(7), throwsA(isInstanceOf<ArgumentError>()));
  });

  test('DeviceList can be serialized to json', () {
    expect(const DeviceList(devices: <Device>[]).toJson(), <String, Object>{
      'devices': <Object>[],
    });
  });

  test('DeviceList.devices must not be null', () {
    expect(() => DeviceList(devices: null), throwsA(isInstanceOf<AssertionError>()));
  });
}