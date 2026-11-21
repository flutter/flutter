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
  isA<Exception>()
      .having((Exception e) => e.toString(), 'code', contains('$_invalidParamsErrorCode'))
      .having((Exception e) => e.toString(), 'message', contains(message)),
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

      final project = ExtensionFlutterProject(
        appName: 'test_app',
        buildDirectory: tempDir.uri.resolve('build/'),
        directory: Uri.directory(tempDir.path),
      );
      final service = LinuxDeviceService();

      expect(
        await service.isSupportedForProject(
          deviceId: LinuxDeviceService.customLinuxDeviceId,
          project: project,
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
                  ExtensionFlutterProject.directoryKey: tempDir.uri.toString(),
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
                  ExtensionFlutterProject.directoryKey: tempDir.uri.toString(),
                },
              },
              'Invalid "${ExtensionFlutterProject.buildDirectoryKey}": expected trailing-slash-terminated absolute file: URI.',
            ),
            (
              <String, Object?>{
                DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
                DeviceService.projectParam: <String, Object?>{
                  ExtensionFlutterProject.appNameKey: 'test_app',
                  ExtensionFlutterProject.buildDirectoryKey: tempDir.uri
                      .resolve('build/')
                      .toString(),
                  ExtensionFlutterProject.directoryKey: tempDir.uri.toString(),
                  ExtensionFlutterProject.isModuleKey: 'not_a_bool',
                },
              },
              'Invalid "${ExtensionFlutterProject.isModuleKey}": expected bool, got String.',
            ),
          ]) {
        await expectLater(
          isSupportedHandler(invalidParams),
          throwsA(
            isA<Exception>()
                .having((Exception e) => e.toString(), 'code', contains('-32602'))
                .having((Exception e) => e.toString(), 'message', contains(expectedMessage)),
          ),
        );
      }

      final ExtensionRpcHandler launchAppHandler = handlers['launchApp']!;
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: 'test_app',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: 'unknown_device',
          DeviceService.executableUriParam: 'file:///nonexistent/app',
          DeviceService.prebuiltApplicationParam: true,
        }),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            contains('Unknown device "unknown_device".'),
          ),
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'file:///nonexistent/app',
        }),
        _throwsInvalidParams('Missing required "${DeviceService.appIdParam}" (expected String).'),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: '',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'file:///nonexistent/app',
        }),
        _throwsInvalidParams('Parameter "${DeviceService.appIdParam}" must not be empty.'),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: 'test_app',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'file:///nonexistent/app',
          DeviceService.prebuiltApplicationParam: 'not_a_bool',
        }),
        _throwsInvalidParams(
          'Invalid "${DeviceService.prebuiltApplicationParam}": expected bool, got String.',
        ),
      );

      await expectLater(
        launchAppHandler(<String, Object?>{}),
        _throwsInvalidParams(
          'Missing required "${DeviceService.deviceIdParam}" (expected String).',
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: 'test_app',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'relative/path/app',
        }),
        _throwsInvalidParams(
          'Invalid "${DeviceService.executableUriParam}" parameter for ${DeviceService.launchAppMethod}',
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: 'test_app',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'debug',
            'debuggingEnabled': true,
          },
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
          DeviceService.executableUriParam: 'file:///',
        }),
        _throwsInvalidParams(
          'Invalid "${DeviceService.executableUriParam}" parameter for ${DeviceService.launchAppMethod}',
        ),
      );
      await expectLater(
        launchAppHandler(<String, Object?>{
          DeviceService.appIdParam: 'test_app',
          DeviceService.debuggingOptionsParam: <String, Object?>{
            'buildMode': 'invalid_mode',
            'debuggingEnabled': true,
          },
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
        isNull,
      );
      await expectLater(
        stopAppHandler(<String, Object?>{
          DeviceService.appIdParam: '',
          DeviceService.deviceIdParam: LinuxDeviceService.customLinuxDeviceId,
        }),
        _throwsInvalidParams('Parameter "${DeviceService.appIdParam}" must not be empty.'),
      );
      await expectLater(
        stopAppHandler(<String, Object?>{DeviceService.deviceIdParam: 'unknown_device'}),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            contains('Unknown device "unknown_device".'),
          ),
        ),
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
      final envCaptureFile = File('${tempDir.path}/captured_env.txt');
      scriptFile.writeAsStringSync('''
#!/bin/sh
echo "ARGS=\$*" > "${envCaptureFile.path}"
echo "SWITCHES=\$FLUTTER_ENGINE_SWITCHES" >> "${envCaptureFile.path}"
echo "SWITCH_1=\$FLUTTER_ENGINE_SWITCH_1" >> "${envCaptureFile.path}"
echo "SWITCH_2=\$FLUTTER_ENGINE_SWITCH_2" >> "${envCaptureFile.path}"
echo "The Dart VM service is listening on http://127.0.0.1:41187/wXxrm1n2GUI=/"
exec sleep 30
''');
      await Process.run('chmod', <String>['+x', scriptFile.path]);

      final service = LinuxDeviceService();
      addTearDown(service.shutdown);

      await service.launchApp(
        appId: 'fake_app.sh',
        debuggingOptions: const ExtensionDebuggingOptions(
          buildMode: .debug,
          dartEntrypointArgs: <String>['--entry-arg', 'value'],
          debuggingEnabled: true,
          engineSwitches: <String>['enable-dart-profiling=true', 'start-paused=true'],
        ),
        deviceId: LinuxDeviceService.customLinuxDeviceId,
        executableUri: scriptFile.absolute.uri,
        prebuiltApplication: true,
      );

      final Uri? vmServiceUri = await service.getVmServiceUri(
        deviceId: LinuxDeviceService.customLinuxDeviceId,
      );
      expect(vmServiceUri, Uri.parse('http://127.0.0.1:41187/wXxrm1n2GUI=/'));
      final String capturedEnv = envCaptureFile.readAsStringSync();
      expect(capturedEnv, contains('ARGS=--entry-arg value'));
      expect(capturedEnv, contains('SWITCHES=2'));
      expect(capturedEnv, contains('SWITCH_1=enable-dart-profiling=true'));
      expect(capturedEnv, contains('SWITCH_2=start-paused=true'));

      // Stopping a different appId leaves the active process running.
      await service.stopApp(appId: 'other_app', deviceId: LinuxDeviceService.customLinuxDeviceId);
      expect(
        await service.getVmServiceUri(deviceId: LinuxDeviceService.customLinuxDeviceId),
        Uri.parse('http://127.0.0.1:41187/wXxrm1n2GUI=/'),
      );

      await service.stopApp(appId: 'fake_app.sh', deviceId: LinuxDeviceService.customLinuxDeviceId);
      expect(
        await service.getVmServiceUri(deviceId: LinuxDeviceService.customLinuxDeviceId),
        isNull,
      );

      // Also supports launching from a directory bundle URI (`bundle/<appId>`).
      final bundleDir = Directory('${tempDir.path}/bundle')..createSync();
      final bundledExecutable = File('${bundleDir.path}/my_bundled_app')
        ..writeAsStringSync('''
#!/bin/sh
echo "The Dart VM service is listening on http://[::1]:51234/"
exec sleep 30
''');
      await Process.run('chmod', <String>['+x', bundledExecutable.path]);

      await service.launchApp(
        appId: 'my_bundled_app',
        debuggingOptions: const ExtensionDebuggingOptions(
          buildMode: .debug,
          debuggingEnabled: true,
        ),
        deviceId: LinuxDeviceService.customLinuxDeviceId,
        executableUri: bundleDir.absolute.uri,
      );
      expect(
        await service.getVmServiceUri(deviceId: LinuxDeviceService.customLinuxDeviceId),
        Uri.parse('http://[::1]:51234/'),
      );
    }, skip: !Platform.isLinux && !Platform.isMacOS); // [intended] Uses POSIX shell script.
  });
}
