// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/generic_extension_protocol.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart' as src_platform;
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/devices.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/device.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/extension.dart';
import 'package:flutter_tools/src/flutter_tools_core/device.dart' show LocalDeviceLaunchHelper;
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:test/test.dart';

import '../src/context.dart';
import '../src/fake_process_manager.dart';

void main() {
  group('Linux Device Extension Prototype', () {
    late ToolExtensionManager manager;

    setUp(() {
      manager = ToolExtensionManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('discover, install, launch and stream logs from Linux target', () async {
      // 1. Spawn the Linux device extension
      final ToolExtension extension = await manager.startExtension(linuxDeviceExtensionEntryPoint);

      // 2. Query capabilities
      final ToolExtensionCapabilities capabilities = await extension.getCapabilities();
      expect(capabilities.services, const <String>[
        'device',
        'diagnostics',
        'config',
        'build',
        'artifacts',
        'template',
      ]);

      // 3. Discover devices
      final Object? devicesResult = await extension.callMethod('device.discoverDevices');
      expect(devicesResult, isA<List<Object?>>());
      final devices = devicesResult! as List<Object?>;
      expect(devices, hasLength(1));

      final Map<String, Object?> device = (devices[0]! as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(device['id'], 'linux-proto-1');
      expect(device['name'], 'Linux Desktop Target');
      expect(device['category'], 'desktop');

      // 4. Install app
      final logLines = <String>[];
      final logCompleter = Completer<void>();

      final StreamSubscription<Notification> sub = manager.notifications.listen((Notification n) {
        if (n.method == 'device.log') {
          final message = n.params!['message']! as String;
          logLines.add(message);
          if (logLines.length >= 5) {
            if (!logCompleter.isCompleted) {
              logCompleter.complete();
            }
          }
        }
      });
      addTearDown(sub.cancel);

      final Directory tempDir = Directory.systemTemp.createTempSync(
        'flutter_extension_device_test_',
      );
      addTearDown(() {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Ignore failures to delete temp directory if process is still exiting.
        }
      });

      final mockAppFile = File('${tempDir.path}/mock_app${Platform.isWindows ? ".bat" : ""}');
      if (Platform.isWindows) {
        mockAppFile.writeAsStringSync(
          '@echo off\r\n'
          'echo stdout log line #1 from application.\r\n'
          'echo stdout log line #2 from application.\r\n'
          'echo stdout log line #3 from application.\r\n'
          'echo The Dart VM service is listening on http://127.0.0.1:9090/auth-token-123/\r\n'
          'echo stdout log line #4 from application.\r\n'
          ':loop\r\n'
          'ping -n 2 127.0.0.1 >nul\r\n'
          'goto loop\r\n',
        );
      } else {
        mockAppFile.writeAsStringSync(
          '#!/bin/sh\n'
          'echo "stdout log line #1 from application."\n'
          'echo "stdout log line #2 from application."\n'
          'echo "stdout log line #3 from application."\n'
          'echo "The Dart VM service is listening on http://127.0.0.1:9090/auth-token-123/"\n'
          'echo "stdout log line #4 from application."\n'
          'while true; do\n'
          '  sleep 1\n'
          'done\n',
        );
        Process.runSync('chmod', <String>['+x', mockAppFile.path]);
      }

      final String appPath = mockAppFile.path;

      await extension.callMethod(
        'device.installApp',
        params: <String, Object?>{'deviceId': 'linux-proto-1', 'appBundlePath': appPath},
      );

      // 5. Launch app
      await extension.callMethod(
        'device.launchApp',
        params: <String, Object?>{'deviceId': 'linux-proto-1', 'appBundlePath': appPath},
      );

      // Wait for app logs to be streamed back
      await logCompleter.future.timeout(const Duration(seconds: 3));

      expect(logLines, contains('Installing app bundle $appPath...'));
      expect(logLines, contains('Launching app bundle $appPath with args: []...'));
      expect(logLines, contains('stdout log line #1 from application.'));
      expect(logLines, contains('stdout log line #2 from application.'));
      expect(logLines, contains('stdout log line #3 from application.'));

      // 6. Query VM Service URI
      final Object? vmServiceUri = await extension.callMethod(
        'device.getVmServiceUri',
        params: <String, Object?>{'deviceId': 'linux-proto-1'},
      );
      expect(vmServiceUri, 'http://127.0.0.1:9090/auth-token-123/');
    });

    test('LinuxDevice launchApp with physical binary via FakeProcessManager', () async {
      final fs = MemoryFileSystem.test();
      const appPath = '/build/linux/x64/debug/bundle';
      fs.file(appPath).createSync(recursive: true);

      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[appPath, '--foo'],
          stdout:
              'Some stdout line\nThe Dart VM service is listening on http://127.0.0.1:8181/auth-token-xyz/\nAnother stdout line\n',
          stderr: 'Some stderr line\n',
        ),
      ]);

      final logLines = <String>[];
      final deviceService = LinuxDeviceService(
        fileSystem: fs,
        processManager: fakeProcessManager,
        onNotification: (String method, Map<String, Object?> params) {
          if (method == 'device.log') {
            logLines.add(params['message']! as String);
          }
        },
      );
      addTearDown(deviceService.shutdown);

      // Initialize the RPC handlers inside extension by calling initialize()
      final Map<String, Function> rpcHandlers = await deviceService.initialize();
      final discoverDevices =
          rpcHandlers['discoverDevices']! as Future<List<Object?>> Function(Map<String, Object?>);
      final launchApp = rpcHandlers['launchApp']! as Future<void> Function(Map<String, Object?>);
      final getVmServiceUri =
          rpcHandlers['getVmServiceUri']! as Future<String> Function(Map<String, Object?>);

      // Discover devices via the RPC handler to populate _devices
      final List<Object?> devicesResult = await discoverDevices(<String, Object?>{});
      expect(devicesResult, isA<List<Object?>>());
      final devices = devicesResult;
      expect(devices, hasLength(1));

      final Map<String, Object?> device = (devices[0]! as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(device['id'], 'linux-proto-1');

      // Call launchApp
      await launchApp(<String, Object?>{
        'deviceId': 'linux-proto-1',
        'appBundlePath': appPath,
        'args': const <String>['--foo'],
      });

      // Get VM Service URI
      final String vmServiceUriString = await getVmServiceUri(<String, Object?>{
        'deviceId': 'linux-proto-1',
      });
      expect(vmServiceUriString, 'http://127.0.0.1:8181/auth-token-xyz/');

      // Wait for asynchronously forwarded stream events to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify logs
      expect(logLines, contains('Launching app bundle $appPath with args: [--foo]...'));
      expect(logLines, contains('Some stdout line'));
      expect(
        logLines,
        contains('The Dart VM service is listening on http://127.0.0.1:8181/auth-token-xyz/'),
      );
      expect(logLines, contains('Another stdout line'));
      expect(logLines, contains('ERROR: Some stderr line'));

      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('LinuxDevice launchApp fails if process exits early', () async {
      final fs = MemoryFileSystem.test();
      const appPath = '/build/linux/x64/debug/bundle';
      fs.file(appPath).createSync(recursive: true);

      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[appPath, '--foo'],
          exitCode: 1,
          stdout: 'Starting process...\n',
        ),
      ]);

      final deviceService = LinuxDeviceService(
        fileSystem: fs,
        processManager: fakeProcessManager,
        onNotification: (String method, Map<String, Object?> params) {},
      );
      addTearDown(deviceService.shutdown);

      final Map<String, Function> rpcHandlers = await deviceService.initialize();
      final discoverDevices =
          rpcHandlers['discoverDevices']! as Future<List<Object?>> Function(Map<String, Object?>);
      final launchApp = rpcHandlers['launchApp']! as Future<void> Function(Map<String, Object?>);
      final getVmServiceUri =
          rpcHandlers['getVmServiceUri']! as Future<String> Function(Map<String, Object?>);

      // Discover devices via the RPC handler to populate _devices
      await discoverDevices(<String, Object?>{});

      await launchApp(<String, Object?>{
        'deviceId': 'linux-proto-1',
        'appBundlePath': appPath,
        'args': const <String>['--foo'],
      });

      // Querying VM service URI should throw because the process exited early.
      expect(
        () => getVmServiceUri(<String, Object?>{'deviceId': 'linux-proto-1'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
              'The process exited early with exit code 1 before VM Service URI was printed.',
            ),
          ),
        ),
      );

      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext(
      'ExtensionDeviceDiscovery discoverDevices respects DeviceDiscoveryFilter connectionInterface',
      () async {
        await manager.startExtension(linuxDeviceExtensionEntryPoint);

        final discovery = ExtensionDeviceDiscovery(
          manager,
          logger: BufferLogger.test(),
          cache: globals.cache,
          fileSystem: globals.fs,
          platform: globals.platform,
        );

        final List<Device> wirelessDevices = await discovery.discoverDevices(
          filter: DeviceDiscoveryFilter(
            deviceConnectionInterface: DeviceConnectionInterface.wireless,
          ),
        );
        expect(wirelessDevices, isEmpty);

        final List<Device> attachedDevices = await discovery.discoverDevices(
          filter: DeviceDiscoveryFilter(
            deviceConnectionInterface: DeviceConnectionInterface.attached,
          ),
        );
        expect(attachedDevices, hasLength(1));
        expect(attachedDevices.first.id, 'linux-proto-1');
        expect(attachedDevices.first.connectionInterface, DeviceConnectionInterface.attached);
      },
      overrides: <Type, Generator>{
        src_platform.Platform: () => src_platform.FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
        ),
      },
    );

    test(
      'LinuxDevice and LocalDeviceLaunchHelper expose built-in alignment and URI parsing',
      () async {
        final fs = MemoryFileSystem.test();
        final device = LinuxDevice(
          fileSystem: fs,
          id: 'linux-proto-1',
          name: 'Linux Desktop Target',
          processManager: FakeProcessManager.any(),
        );

        expect(await device.isSupported(), isTrue);
        expect(device.isRunnable(), isTrue);
        expect(device.isSupportedForProject(Uri.parse('file:///project')), isFalse);

        final Uri? parsedUri = LocalDeviceLaunchHelper.parseVmServiceUri(
          'The Dart VM service is listening on http://127.0.0.1:8181/auth-token/',
        );
        expect(parsedUri, isNotNull);
        expect(parsedUri.toString(), 'http://127.0.0.1:8181/auth-token/');

        expect(
          LocalDeviceLaunchHelper.parseVmServiceUri('Some regular log line without VM service'),
          isNull,
        );
      },
    );
  });
}
