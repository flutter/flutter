// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxDeviceService', () {
    test('getDevices returns prototype custom linux device', () async {
      final service = LinuxDeviceService();
      final List<TargetDevice> devices = await service.getDevices();

      expect(devices, hasLength(1));
      final TargetDevice device = devices.first;
      expect(device.id, 'custom_linux_device');
      expect(device.name, 'Linux Custom Extension Prototype Device');
      expect(device.category, Category.desktop);
      expect(device.targetPlatform, 'linux-x64');
      expect(device.sdkNameAndVersion, 'Custom Linux 1.0.0');
      expect(device.ephemeral, isFalse);
      expect(device.isSupported, isTrue);
      expect(device.isSupportedForProject, isTrue);
    });

    test('getDevices sets isSupportedForProject based on linux/ directory', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_device_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final service = LinuxDeviceService();

      final List<TargetDevice> unsupportedDevices = await service.getDevices(
        projectRoot: tempDir.uri,
      );
      expect(unsupportedDevices.single.isSupportedForProject, isFalse);

      Directory.fromUri(tempDir.uri.resolve('linux')).createSync();
      final List<TargetDevice> supportedDevices = await service.getDevices(
        projectRoot: tempDir.uri,
      );
      expect(supportedDevices.single.isSupportedForProject, isTrue);
    });
  });
}
