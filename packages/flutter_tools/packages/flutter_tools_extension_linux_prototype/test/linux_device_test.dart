// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
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
      expect(device.targetPlatform, 'linux-x64');
      expect(device.sdkNameAndVersion, 'Custom Linux 1.0.0');
      expect(device.ephemeral, isFalse);
      expect(device.isSupported, isTrue);
    });

    test('isSupportedForProject checks for linux/ directory and matching deviceId', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_device_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final project = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: tempDir.uri.resolve('build/'),
        directory: Uri.directory(tempDir.path),
      );
      final projectWithoutTrailingSlash = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: tempDir.uri.resolve('build/'),
        directory: Uri.file(tempDir.path, windows: false),
      );
      final service = LinuxDeviceService();

      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: project,
        ),
        isFalse,
      );
      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: projectWithoutTrailingSlash,
        ),
        isFalse,
      );

      Directory.fromUri(tempDir.uri.resolve('linux')).createSync();
      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: project,
        ),
        isTrue,
      );
      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: projectWithoutTrailingSlash,
        ),
        isTrue,
      );

      expect(
        await service.isSupportedForProject(deviceId: 'unknown_device', project: project),
        isFalse,
      );
    });

    test('initialize registers RPC handlers and validates parameters', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_device_rpc_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      Directory.fromUri(tempDir.uri.resolve('linux')).createSync();

      final service = LinuxDeviceService();
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      final ExtensionRpcHandler isSupportedHandler = handlers['isSupportedForProject']!;

      final project = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: tempDir.uri.resolve('build/'),
        directory: tempDir.uri,
      );
      expect(
        await isSupportedHandler(<String, Object?>{
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.projectParam: project.toMap(),
        }),
        isTrue,
      );

      await expectLater(
        isSupportedHandler(<String, Object?>{}),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.message,
            'message',
            contains(
              'Invalid or missing parameters for ${DeviceService.isSupportedForProjectMethod}.',
            ),
          ),
        ),
      );
    });
  });
}
