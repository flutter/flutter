// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/generic_extension_protocol.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/device.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/extension.dart';
import 'package:test/test.dart';

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
      expect(capabilities.services, const <String>['device']);

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

      await extension.callMethod(
        'device.installApp',
        params: <String, Object?>{
          'deviceId': 'linux-proto-1',
          'appBundlePath': '/build/linux/x64/debug/bundle',
        },
      );

      // 5. Launch app
      await extension.callMethod(
        'device.launchApp',
        params: <String, Object?>{
          'deviceId': 'linux-proto-1',
          'appBundlePath': '/build/linux/x64/debug/bundle',
        },
      );

      // Wait for app logs to be streamed back
      await logCompleter.future.timeout(const Duration(seconds: 3));

      expect(logLines, contains('Installing app bundle /build/linux/x64/debug/bundle...'));
      expect(logLines, contains('Launching app bundle /build/linux/x64/debug/bundle...'));
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

      // Initialize the RPC handlers inside GEP by calling initialize()
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
  });
}
