// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:test/test.dart';

const int _invalidParamsErrorCode = -32602;

Matcher _throwsInvalidParams(String message) => throwsA(
  isA<RpcException>()
      .having((RpcException e) => e.code, 'code', _invalidParamsErrorCode)
      .having((RpcException e) => e.message, 'message', contains(message)),
);

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
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: 'unknown_device',
          DeviceService.executableUriParam: 'file:///nonexistent/app',
        }),
        isFalse,
      );
      await expectLater(
        launchAppHandler(<String, Object?>{}),
        _throwsInvalidParams(
          'Missing required "${DeviceService.deviceIdParam}" (expected String).',
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.debuggingOptionsParam: <String, Object?>{'buildMode': 'debug'},
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'relative/path/app',
        }),
        _throwsInvalidParams(
          'Invalid "${DeviceService.executableUriParam}" parameter for ${DeviceService.launchAppMethod}',
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.debuggingOptionsParam: <String, Object?>{'buildMode': 'invalid_mode'},
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'file:///nonexistent/app',
        }),
        _throwsInvalidParams(
          'Invalid "${DeviceService.debuggingOptionsParam}" parameter for ${DeviceService.launchAppMethod}',
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
        _throwsInvalidParams(
          'Missing required "${DeviceService.deviceIdParam}" (expected String).',
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
        _throwsInvalidParams(
          'Missing required "${DeviceService.deviceIdParam}" (expected String).',
        ),
      );
    });

    test('launchApp, getVmServiceUri, and stopApp manage process lifecycle and parse VM Service URI with base64url padding', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_device_launch_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final scriptFile = File('${tempDir.path}/fake_app.sh');
      scriptFile.writeAsStringSync('''
#!/bin/sh
echo "The Dart VM service is listening on http://127.0.0.1:41187/wXxrm1n2GUI=/"
sleep 30
''');
      await Process.run('chmod', <String>['+x', scriptFile.path]);

      final service = LinuxDeviceService();
      addTearDown(service.shutdown);

      final bool launched = await service.launchApp(
        debuggingOptions: const ExtensionDebuggingOptions(
          buildMode: .debug,
          debuggingEnabled: true,
        ),
        deviceId: LinuxDeviceService.customLinuxDeviceId,
        executableUri: scriptFile.absolute.uri,
      );
      expect(launched, isTrue);

      final Uri? vmServiceUri = await service.getVmServiceUri(
        deviceId: LinuxDeviceService.customLinuxDeviceId,
      );
      expect(vmServiceUri, Uri.parse('http://127.0.0.1:41187/wXxrm1n2GUI=/'));

      final bool stopped = await service.stopApp(deviceId: LinuxDeviceService.customLinuxDeviceId);
      expect(stopped, isTrue);
      expect(
        await service.getVmServiceUri(deviceId: LinuxDeviceService.customLinuxDeviceId),
        isNull,
      );
    }, skip: !Platform.isLinux && !Platform.isMacOS); // [intended] Uses POSIX shell script.
  });
}
