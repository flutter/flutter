// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxDeviceService', () {
    test('getDevices returns prototype custom linux device', () async {
      final service = LinuxDeviceService();
      final List<TargetDevice> devices = await service.getDevices();

      expect(devices, hasLength(1));
      final TargetDevice device = devices.first;
      expect(device.id, LinuxDeviceService.customLinuxDeviceId);
      expect(device.name, 'Linux Custom Extension Prototype Device');
      expect(device.category, Category.desktop);
      expect(device.buildTarget, LinuxBuildService.customLinuxBuildTargetName);
      expect(device.targetPlatform, 'linux-x64');
      expect(device.sdkNameAndVersion, 'Custom Linux 1.0.0');
      expect(device.ephemeral, isFalse);
      expect(device.isSupported, isTrue);
    });

    test('isSupportedForProject checks for linux/ directory and matching deviceId', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_device_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final service = LinuxDeviceService();

      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          projectRoot: tempDir.uri,
        ),
        isFalse,
      );

      Directory.fromUri(tempDir.uri.resolve('linux')).createSync();
      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          projectRoot: tempDir.uri,
        ),
        isTrue,
      );

      expect(
        await service.isSupportedForProject(deviceId: 'unknown_device', projectRoot: tempDir.uri),
        isFalse,
      );
    });

    test('initialize registers RPC handlers and validates parameters', () async {
      final service = LinuxDeviceService();
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();

      final ExtensionRpcHandler launchAppHandler = handlers['launchApp']!;
      expect(
        await launchAppHandler(<String, Object?>{
          DeviceService.deviceIdParam: 'unknown_device',
          DeviceService.executablePathParam: '/nonexistent/app',
        }),
        isFalse,
      );
      await expectLater(
        launchAppHandler(<String, Object?>{}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Invalid or missing parameters for ${DeviceService.launchAppMethod}.'),
          ),
        ),
      );

      final ExtensionRpcHandler getVmServiceUriHandler = handlers['getVmServiceUri']!;
      expect(
        await getVmServiceUriHandler(<String, Object?>{
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
        }),
        equals(<String, Object?>{DeviceService.vmServiceUriKey: null}),
      );
      await expectLater(
        getVmServiceUriHandler(<String, Object?>{}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Invalid or missing parameters for ${DeviceService.getVmServiceUriMethod}.'),
          ),
        ),
      );

      final ExtensionRpcHandler stopAppHandler = handlers['stopApp']!;
      expect(
        await stopAppHandler(<String, Object?>{
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
        }),
        isFalse,
      );
      await expectLater(
        stopAppHandler(<String, Object?>{}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Invalid or missing parameters for ${DeviceService.stopAppMethod}.'),
          ),
        ),
      );
    });
  });
}
