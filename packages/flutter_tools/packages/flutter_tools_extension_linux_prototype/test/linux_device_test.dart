// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:test/test.dart';

void main() {
  const invalidParamsErrorCode = -32602;

  group('LinuxDeviceService', () {
    test('getDevices returns prototype custom linux device', () async {
      final ExtensionDependencies dependencies = createTestDependencies();
      final service = LinuxDeviceService(dependencies: dependencies);
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
      final ExtensionDependencies dependencies = createTestDependencies();
      final ExtensionDirectory projectDir = dependencies.fileSystem.directory(
        Uri.parse('file:///project/'),
      )..createSync(recursive: true);

      final project = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: projectDir.childDirectory('build').uri,
        directory: projectDir.uri,
      );
      final service = LinuxDeviceService(dependencies: dependencies);

      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: project,
        ),
        isFalse,
      );

      projectDir.childDirectory('linux').createSync();
      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: project,
        ),
        isTrue,
      );

      expect(
        await service.isSupportedForProject(deviceId: 'unknown_device', project: project),
        isFalse,
      );
    });

    test('initialize registers RPC handlers and validates parameters', () async {
      final ExtensionDependencies dependencies = createTestDependencies();
      final ExtensionDirectory projectDir = dependencies.fileSystem.directory(
        Uri.parse('file:///project/'),
      )..createSync(recursive: true);
      projectDir.childDirectory('linux').createSync();

      final service = LinuxDeviceService(dependencies: dependencies);
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      final ExtensionRpcHandler isSupportedHandler = handlers['isSupportedForProject']!;

      final project = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: projectDir.childDirectory('build').uri,
        directory: projectDir.uri,
      );
      expect(
        await isSupportedHandler(<String, Object?>{
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.projectParam: project.toMap(),
        }),
        isTrue,
      );

      for (final (Map<String, Object?> invalidParams, String expectedMessage)
          in <(Map<String, Object?>, String)>[
            (
              const <String, Object?>{},
              'Missing required "${DeviceService.deviceIdParam}" (expected String).',
            ),
            (
              <String, Object?>{
                DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
                DeviceService.projectParam: const <String, Object?>{},
              },
              'Missing required "${ExtensionFlutterProject.appNameKey}" (expected String).',
            ),
            (
              <String, Object?>{
                DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
                DeviceService.projectParam: <String, Object?>{
                  ExtensionFlutterProject.appNameKey: 'test_app',
                  ExtensionFlutterProject.buildDirectoryKey: 'relative/build/',
                  ExtensionFlutterProject.directoryKey: projectDir.uri.toString(),
                },
              },
              'Invalid "${ExtensionFlutterProject.buildDirectoryKey}": expected trailing-slash-terminated absolute file: URI.',
            ),
            (
              <String, Object?>{
                DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
                DeviceService.projectParam: <String, Object?>{
                  ExtensionFlutterProject.appNameKey: 'test_app',
                  ExtensionFlutterProject.buildDirectoryKey: 'https://example.com/build/',
                  ExtensionFlutterProject.directoryKey: projectDir.uri.toString(),
                },
              },
              'Invalid "${ExtensionFlutterProject.buildDirectoryKey}": expected trailing-slash-terminated absolute file: URI.',
            ),
            (
              <String, Object?>{
                DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
                DeviceService.projectParam: <String, Object?>{
                  ExtensionFlutterProject.appNameKey: 'test_app',
                  ExtensionFlutterProject.buildDirectoryKey: projectDir
                      .childDirectory('build')
                      .uri
                      .toString(),
                  ExtensionFlutterProject.directoryKey: projectDir.uri.toString(),
                  ExtensionFlutterProject.isModuleKey: 'not_a_bool',
                },
              },
              'Invalid "${ExtensionFlutterProject.isModuleKey}": expected bool, got String.',
            ),
          ]) {
        await expectLater(
          isSupportedHandler(invalidParams),
          throwsA(
            isA<RpcException>()
                .having((RpcException e) => e.code, 'code', invalidParamsErrorCode)
                .having((RpcException e) => e.message, 'message', contains(expectedMessage)),
          ),
        );
      }
    });
  });
}
