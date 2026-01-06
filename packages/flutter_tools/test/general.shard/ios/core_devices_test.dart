// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/core_devices.dart';
import 'package:flutter_tools/src/ios/lldb.dart';
import 'package:flutter_tools/src/ios/xcode_debug.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

class LocalFileSystemFake extends Fake implements LocalFileSystem {
  MemoryFileSystem memoryFileSystem = MemoryFileSystem.test();

  @override
  Directory get systemTempDirectory => memoryFileSystem.systemTempDirectory;

  @override
  Directory directory(dynamic path) => memoryFileSystem.directory(path);

  @override
  File file(dynamic path) => memoryFileSystem.file(path);

  @override
  Context get path => memoryFileSystem.path;

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  @override
  bool get disposed => _disposed;

  var _disposed = false;
}

final _interactiveModeArgs = <String>['script', '-t', '0', '/dev/null'];

void main() {
  late MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  group('IOSCoreDeviceLauncher', () {
    group('launchAppWithoutDebugger', () {
      testWithoutContext('succeeds', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
          }),
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithoutDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
        );

        expect(result, isTrue);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on install', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(installSuccess: false);

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
        );

        final bool result = await launcher.launchAppWithoutDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
        );

        expect(result, isFalse);
      });

      testWithoutContext('fails on launch', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'failed'},
          }),
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
        );

        final bool result = await launcher.launchAppWithoutDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
        );

        expect(result, isFalse);
      });

      testWithoutContext('fails on null launch result', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl();

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
        );

        final bool result = await launcher.launchAppWithoutDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
        );

        expect(result, isFalse);
      });
    });

    group('launchAppWithLLDBDebugger', () {
      testWithoutContext('succeeds', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{
              'processIdentifier': 123,
              'executable': '/asdf',
            }),
          ],
        );
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isTrue);
        expect(fakeLLDB.attemptedToAttach, isTrue);
      });

      testWithoutContext('fails on install', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{
              'processIdentifier': 123,
              'executable': '/asdf',
            }),
          ],
          installSuccess: false,
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on missing installationURL', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'failure'},
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{
              'processIdentifier': 123,
              'executable': '/asdf',
            }),
          ],
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on launch', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{
              'processIdentifier': 123,
              'executable': '/asdf',
            }),
          ],
          launchSuccess: false,
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on missing launched process', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [],
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on null launched process id', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{'executable': '/asdf'}),
          ],
        );

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isFalse);
      });

      testWithoutContext('fails on lldb attach', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl(
          installResult: IOSCoreDeviceInstallResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'installedApplications': [
                <String, Object?>{'installationURL': '/asdf'},
              ],
            },
          }),
          launchResult: IOSCoreDeviceLaunchResult.fromJson(const <String, Object?>{
            'info': <String, Object?>{'outcome': 'success'},
            'result': <String, Object?>{
              'process': <String, Object?>{'processIdentifier': 123},
            },
          }),
          runningProcesses: [
            IOSCoreDeviceRunningProcess.fromJson(const <String, Object?>{
              'processIdentifier': 123,
              'executable': '/asdf',
            }),
          ],
        );
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB(attachSuccess: false);
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: FakeXcodeDebug(),
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.launchAppWithLLDBDebugger(
          deviceId: 'device-id',
          bundlePath: 'bundle-path',
          bundleId: 'bundle-id',
          launchArguments: <String>[],
          shutdownHooks: FakeShutdownHooks(),
        );

        expect(result, isFalse);
        expect(fakeLLDB.attemptedToAttach, isTrue);
        expect(fakeCoreDeviceControl.terminateProcessCalled, isTrue);
      });
    });

    group('launchAppWithXcodeDebugger', () {
      testWithoutContext('succeeds with PrebuiltIOSApp', () async {
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final IOSApp package = FakePrebuiltIOSApp();
        final fileSystem = MemoryFileSystem.test();
        final fakeXcodeDebug = FakeXcodeDebug(
          tempXcodeProject: fileSystem.systemTempDirectory,
          expectedLaunchArguments: [],
        );

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: FakeIOSCoreDeviceControl(),
          logger: logger,
          xcodeDebug: fakeXcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: FakeLLDB(),
        );
        final bool result = await launcher.launchAppWithXcodeDebugger(
          deviceId: 'device-id',
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          package: package,
          launchArguments: <String>['--enable-checked-mode', '--verify-entry-points'],
          templateRenderer: FakeTemplateRenderer(),
        );

        expect(result, isTrue);
        expect(fakeXcodeDebug.isTemporaryProject, isTrue);
        expect(fakeXcodeDebug.debugStarted, isTrue);
      });

      testWithoutContext('succeeds with BuildableIOSApp', () async {
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeIosProject = FakeIosProject();
        final IOSApp package = FakeBuildableIOSApp(fakeIosProject);
        final fileSystem = MemoryFileSystem.test();
        final fakeXcodeDebug = FakeXcodeDebug(
          tempXcodeProject: fileSystem.systemTempDirectory,
          expectedLaunchArguments: [],
        );

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: FakeIOSCoreDeviceControl(),
          logger: logger,
          xcodeDebug: fakeXcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: FakeLLDB(),
        );
        final bool result = await launcher.launchAppWithXcodeDebugger(
          deviceId: 'device-id',
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          package: package,
          launchArguments: <String>['--enable-checked-mode', '--verify-entry-points'],
          templateRenderer: FakeTemplateRenderer(),
        );

        expect(result, isTrue);
        expect(fakeXcodeDebug.isTemporaryProject, isFalse);
        expect(fakeXcodeDebug.debugStarted, isTrue);
      });

      testWithoutContext('fails with BuildableIOSApp if unable to find workspace', () async {
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeIosProject = FakeIosProject(missingWorkspace: true);
        final IOSApp package = FakeBuildableIOSApp(fakeIosProject);
        final fileSystem = MemoryFileSystem.test();
        final fakeXcodeDebug = FakeXcodeDebug(
          tempXcodeProject: fileSystem.systemTempDirectory,
          expectedLaunchArguments: [],
        );

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: FakeIOSCoreDeviceControl(),
          logger: logger,
          xcodeDebug: fakeXcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: FakeLLDB(),
        );
        final bool result = await launcher.launchAppWithXcodeDebugger(
          deviceId: 'device-id',
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          package: package,
          launchArguments: <String>['--enable-checked-mode', '--verify-entry-points'],
          templateRenderer: FakeTemplateRenderer(),
        );

        expect(result, isFalse);
        expect(fakeXcodeDebug.isTemporaryProject, isFalse);
        expect(fakeXcodeDebug.debugStarted, isFalse);
      });

      testWithoutContext('fails with BuildableIOSApp if unable to find scheme', () async {
        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeIosProject = FakeIosProject(missingScheme: true);
        final IOSApp package = FakeBuildableIOSApp(fakeIosProject);
        final fileSystem = MemoryFileSystem.test();
        final fakeXcodeDebug = FakeXcodeDebug(
          tempXcodeProject: fileSystem.systemTempDirectory,
          expectedLaunchArguments: [],
        );

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: FakeIOSCoreDeviceControl(),
          logger: logger,
          xcodeDebug: fakeXcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: FakeLLDB(),
        );
        final bool result = await launcher.launchAppWithXcodeDebugger(
          deviceId: 'device-id',
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          package: package,
          launchArguments: <String>['--enable-checked-mode', '--verify-entry-points'],
          templateRenderer: FakeTemplateRenderer(),
        );

        expect(result, isFalse);
        expect(fakeXcodeDebug.isTemporaryProject, isFalse);
        expect(fakeXcodeDebug.debugStarted, isFalse);
      });
    });

    group('stopApp', () {
      testWithoutContext('stops with xcode debug', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl();
        final xcodeDebug = FakeXcodeDebug();
        xcodeDebug._debugStarted = true;

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);
        final fakeLLDB = FakeLLDB();
        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: xcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.stopApp(deviceId: 'device-id');

        expect(result, isTrue);
        expect(xcodeDebug.exitCalled, isTrue);
        expect(fakeCoreDeviceControl.terminateProcessCalled, isFalse);
        expect(fakeLLDB.exitCalled, isFalse);
      });

      testWithoutContext('stops with lldb process', () async {
        const processId = 1234;
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl();
        final xcodeDebug = FakeXcodeDebug();
        final fakeLLDB = FakeLLDB();

        fakeLLDB.setIsRunning(true, processId);

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: xcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.stopApp(deviceId: 'device-id');

        expect(result, isTrue);
        expect(xcodeDebug.exitCalled, isFalse);
        expect(fakeCoreDeviceControl.terminateProcessCalled, isTrue);
        expect(fakeCoreDeviceControl.processTerminated, processId);
        expect(fakeLLDB.exitCalled, isTrue);
      });

      testWithoutContext('stops with processId', () async {
        const processId = 1234;
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl();
        final xcodeDebug = FakeXcodeDebug();
        final fakeLLDB = FakeLLDB();

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: xcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.stopApp(deviceId: 'device-id', processId: processId);

        expect(result, isTrue);
        expect(xcodeDebug.exitCalled, isFalse);
        expect(fakeCoreDeviceControl.terminateProcessCalled, isTrue);
        expect(fakeCoreDeviceControl.processTerminated, processId);
        expect(fakeLLDB.exitCalled, isFalse);
      });

      testWithoutContext('no process to stop', () async {
        final fakeCoreDeviceControl = FakeIOSCoreDeviceControl();
        final xcodeDebug = FakeXcodeDebug();
        final fakeLLDB = FakeLLDB();

        final processManager = FakeProcessManager.any();
        final logger = BufferLogger.test();
        final processUtils = ProcessUtils(processManager: processManager, logger: logger);

        final launcher = IOSCoreDeviceLauncher(
          coreDeviceControl: fakeCoreDeviceControl,
          logger: logger,
          xcodeDebug: xcodeDebug,
          fileSystem: MemoryFileSystem.test(),
          processUtils: processUtils,
          lldb: fakeLLDB,
        );

        final bool result = await launcher.stopApp(deviceId: 'device-id');

        expect(result, isFalse);
        expect(xcodeDebug.exitCalled, isFalse);
        expect(fakeCoreDeviceControl.terminateProcessCalled, isFalse);
        expect(fakeLLDB.exitCalled, isFalse);
      });
    });
  });

  group('IOSCoreDeviceLogForwarder', () {
    testWithoutContext('addLog', () async {
      const expectedLog = 'hello world';
      final expectedLogCompleter = Completer<void>();
      final logForwarder = IOSCoreDeviceLogForwarder();
      logForwarder.logLines.listen((String line) {
        expect(line, expectedLog);
        expectedLogCompleter.complete();
      });
      logForwarder.addLog(expectedLog);
      await expectedLogCompleter.future;
    });

    testWithoutContext('exit', () async {
      final exitCompleter = Completer<void>();
      final logForwarder = IOSCoreDeviceLogForwarder();
      final lldbProcess = FakeProcess();
      logForwarder.launchProcess = lldbProcess;
      logForwarder.logLines.listen((String line) => line).onDone(() {
        exitCompleter.complete();
      });
      await logForwarder.exit();
      await exitCompleter.future;
      expect(logForwarder.isRunning, isFalse);
      expect(lldbProcess.signals, contains(io.ProcessSignal.sigterm));
    });

    testWithoutContext('addLog after exit', () async {
      final exitCompleter = Completer<void>();
      final logForwarder = IOSCoreDeviceLogForwarder();
      final lldbProcess = FakeProcess();
      logForwarder.launchProcess = lldbProcess;
      logForwarder.logLines.listen((String line) => line).onDone(() {
        exitCompleter.complete();
      });
      await logForwarder.exit();
      await exitCompleter.future;
      expect(logForwarder.isRunning, isFalse);
      expect(lldbProcess.signals, contains(io.ProcessSignal.sigterm));
      logForwarder.addLog('hello world');
    });
  });

  group('Xcode prior to Core Device Control/Xcode 15', () {
    late BufferLogger logger;
    late FakeProcessManager fakeProcessManager;
    late Xcode xcode;
    late IOSCoreDeviceControl deviceControl;

    setUp(() {
      logger = BufferLogger.test();
      fakeProcessManager = FakeProcessManager.empty();
      final xcodeProjectInterpreter = XcodeProjectInterpreter.test(
        processManager: fakeProcessManager,
        version: Version(14, 0, 0),
      );
      xcode = Xcode.test(
        processManager: fakeProcessManager,
        xcodeProjectInterpreter: xcodeProjectInterpreter,
      );
      deviceControl = IOSCoreDeviceControl(
        logger: logger,
        processManager: fakeProcessManager,
        xcode: xcode,
        fileSystem: fileSystem,
      );
    });

    group('devicectl is not installed', () {
      testWithoutContext('fails to get device list', () async {
        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl is not installed.'));
        expect(devices.isEmpty, isTrue);
      });

      testWithoutContext('fails to install app', () async {
        final (bool status, IOSCoreDeviceInstallResult? result) = await deviceControl.installApp(
          deviceId: 'device-id',
          bundlePath: '/path/to/bundle',
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl is not installed.'));
        expect(status, isFalse);
        expect(result, isNull);
      });

      testWithoutContext('fails to launch app', () async {
        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: 'device-id',
          bundleId: 'com.example.flutterApp',
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl is not installed.'));
        expect(result, isNull);
      });

      testWithoutContext('fails to check if app is installed', () async {
        final bool status = await deviceControl.isAppInstalled(
          deviceId: 'device-id',
          bundleId: 'com.example.flutterApp',
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('devicectl is not installed.'));
        expect(status, isFalse);
      });
    });
  });

  group('Core Device Control', () {
    late BufferLogger logger;
    late FakeProcessManager fakeProcessManager;
    late Xcode xcode;
    late IOSCoreDeviceControl deviceControl;

    setUp(() {
      logger = BufferLogger.test();
      fakeProcessManager = FakeProcessManager.empty();
      // TODO(fujino): re-use fakeProcessManager
      xcode = Xcode.test(processManager: FakeProcessManager.any());
      deviceControl = IOSCoreDeviceControl(
        logger: logger,
        processManager: fakeProcessManager,
        xcode: xcode,
        fileSystem: fileSystem,
      );
    });

    group('install app', () {
      const deviceId = 'device-id';
      const bundlePath = '/path/to/com.example.flutterApp';

      testWithoutContext('Successful install', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "install",
      "app",
      "--device",
      "00001234-0001234A3C03401E",
      "build/ios/iphoneos/Runner.app",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.install.app",
    "environment" : {

    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "installedApplications" : [
      {
        "bundleID" : "com.example.bundle",
        "databaseSequenceNumber" : 1230,
        "databaseUUID" : "1234A567-D890-1B23-BCF4-D5D67A8D901E",
        "installationURL" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
        "launchServicesIdentifier" : "unknown",
        "options" : {

        }
      }
    ]
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('install_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'install',
              'app',
              '--device',
              deviceId,
              bundlePath,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final (bool status, IOSCoreDeviceInstallResult? result) = await deviceControl.installApp(
          deviceId: deviceId,
          bundlePath: bundlePath,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(status, true);
      });

      testWithoutContext('devicectl fails install', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : 1005,
    "domain" : "com.apple.dt.CoreDeviceError",
    "userInfo" : {
      "NSLocalizedDescription" : {
        "string" : "Could not obtain access to one or more requested file system resources because CoreDevice was unable to create bookmark data."
      },
      "NSUnderlyingError" : {
        "error" : {
          "code" : 260,
          "domain" : "NSCocoaErrorDomain",
          "userInfo" : {

          }
        }
      }
    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "install",
      "app",
      "--device",
      "00001234-0001234A3C03401E",
      "/path/to/app",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.install.app",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "failed",
    "version" : "341"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('install_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'install',
              'app',
              '--device',
              deviceId,
              bundlePath,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
            exitCode: 1,
            stderr: '''
ERROR: Could not obtain access to one or more requested file system resources because CoreDevice was unable to create bookmark data. (com.apple.dt.CoreDeviceError error 1005.)
         NSURL = file:///path/to/app
--------------------------------------------------------------------------------
ERROR: The file couldn’t be opened because it doesn’t exist. (NSCocoaErrorDomain error 260.)
''',
          ),
        );

        final (bool status, IOSCoreDeviceInstallResult? result) = await deviceControl.installApp(
          deviceId: deviceId,
          bundlePath: bundlePath,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(
          logger.traceText,
          contains('ERROR: Could not obtain access to one or more requested file system'),
        );
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails install because of unexpected JSON', () async {
        const deviceControlOutput = '''
{
  "valid_unexpected_json": true
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('install_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'install',
              'app',
              '--device',
              deviceId,
              bundlePath,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final (bool status, IOSCoreDeviceInstallResult? result) = await deviceControl.installApp(
          deviceId: deviceId,
          bundlePath: bundlePath,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned unexpected JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails install because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('install_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'install',
              'app',
              '--device',
              deviceId,
              bundlePath,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final (bool status, IOSCoreDeviceInstallResult? result) = await deviceControl.installApp(
          deviceId: deviceId,
          bundlePath: bundlePath,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned non-JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });
    });

    group('uninstall app', () {
      const deviceId = 'device-id';
      const bundleId = 'com.example.flutterApp';

      testWithoutContext('Successful uninstall', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "uninstall",
      "app",
      "--device",
      "00001234-0001234A3C03401E",
      "build/ios/iphoneos/Runner.app",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/uninstall_results.json"
    ],
    "commandType" : "devicectl.device.uninstall.app",
    "environment" : {

    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "uninstalledApplications" : [
      {
        "bundleID" : "com.example.bundle"
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('uninstall_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'uninstall',
              'app',
              '--device',
              deviceId,
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.uninstallApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(status, true);
      });

      testWithoutContext('devicectl fails uninstall', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : 1005,
    "domain" : "com.apple.dt.CoreDeviceError",
    "userInfo" : {
      "NSLocalizedDescription" : {
        "string" : "Could not obtain access to one or more requested file system resources because CoreDevice was unable to create bookmark data."
      },
      "NSUnderlyingError" : {
        "error" : {
          "code" : 260,
          "domain" : "NSCocoaErrorDomain",
          "userInfo" : {

          }
        }
      }
    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "uninstall",
      "app",
      "--device",
      "00001234-0001234A3C03401E",
      "com.example.flutterApp",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/uninstall_results.json"
    ],
    "commandType" : "devicectl.device.uninstall.app",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "failed",
    "version" : "341"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('uninstall_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'uninstall',
              'app',
              '--device',
              deviceId,
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
            exitCode: 1,
            stderr: '''
ERROR: Could not obtain access to one or more requested file system resources because CoreDevice was unable to create bookmark data. (com.apple.dt.CoreDeviceError error 1005.)
         NSURL = file:///path/to/app
--------------------------------------------------------------------------------
ERROR: The file couldn’t be opened because it doesn’t exist. (NSCocoaErrorDomain error 260.)
''',
          ),
        );

        final bool status = await deviceControl.uninstallApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(
          logger.errorText,
          contains('ERROR: Could not obtain access to one or more requested file system'),
        );
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails uninstall because of unexpected JSON', () async {
        const deviceControlOutput = '''
{
  "valid_unexpected_json": true
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('uninstall_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'uninstall',
              'app',
              '--device',
              deviceId,
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.uninstallApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('devicectl returned unexpected JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails uninstall because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('uninstall_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'uninstall',
              'app',
              '--device',
              deviceId,
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.uninstallApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('devicectl returned non-JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });
    });

    group('launchApp', () {
      const deviceId = 'device-id';
      const bundleId = 'com.example.flutterApp';

      testWithoutContext('Successful launch without launch args', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "launch",
      "--device",
      "00001234-0001234A3C03401E",
      "com.example.flutterApp",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.process.launch",
    "environment" : {

    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "launchOptions" : {
      "activatedWhenStarted" : true,
      "arguments" : [

      ],
      "environmentVariables" : {
        "TERM" : "vt100"
      },
      "platformSpecificOptions" : {

      },
      "startStopped" : false,
      "terminateExistingInstances" : false,
      "user" : {
        "active" : true
      }
    },
    "process" : {
      "auditToken" : [
        12345,
        678
      ],
      "executable" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner",
      "processIdentifier" : 1234
    }
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(result, isNotNull);
        expect(result!.outcome, 'success');
      });

      testWithoutContext('Successful launch with launch args', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "launch",
      "--device",
      "00001234-0001234A3C03401E",
      "com.example.flutterApp",
      "--arg1",
      "--arg2",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.process.launch",
    "environment" : {

    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "launchOptions" : {
      "activatedWhenStarted" : true,
      "arguments" : [

      ],
      "environmentVariables" : {
        "TERM" : "vt100"
      },
      "platformSpecificOptions" : {

      },
      "startStopped" : false,
      "terminateExistingInstances" : false,
      "user" : {
        "active" : true
      }
    },
    "process" : {
      "auditToken" : [
        12345,
        678
      ],
      "executable" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner",
      "processIdentifier" : 1234
    }
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
              '--arg1',
              '--arg2',
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
          launchArguments: <String>['--arg1', '--arg2'],
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(result, isNotNull);
        expect(result!.outcome, 'success');
      });

      testWithoutContext('devicectl fails launch with an error', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : -10814,
    "domain" : "NSOSStatusErrorDomain",
    "userInfo" : {
      "_LSFunction" : {
        "string" : "runEvaluator"
      },
      "_LSLine" : {
        "int" : 1608
      }
    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "launch",
      "--device",
      "00001234-0001234A3C03401E",
      "com.example.flutterApp",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.process.launch",
    "environment" : {

    },
    "outcome" : "failed",
    "version" : "341"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
            exitCode: 1,
            stderr: '''
ERROR: The operation couldn?t be completed. (OSStatus error -10814.) (NSOSStatusErrorDomain error -10814.)
    _LSFunction = runEvaluator
    _LSLine = 1608
''',
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('ERROR: The operation couldn?t be completed.'));
        expect(tempFile, isNot(exists));
        expect(result, isNull);
      });

      testWithoutContext('devicectl fails launch without an error', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : -10814,
    "domain" : "NSOSStatusErrorDomain",
    "userInfo" : {
      "_LSFunction" : {
        "string" : "runEvaluator"
      },
      "_LSLine" : {
        "int" : 1608
      }
    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "launch",
      "--device",
      "00001234-0001234A3C03401E",
      "com.example.flutterApp",
      "--json-output",
      "/var/folders/wq/randompath/T/flutter_tools.rand0/core_devices.rand0/install_results.json"
    ],
    "commandType" : "devicectl.device.process.launch",
    "environment" : {

    },
    "outcome" : "failed",
    "version" : "341"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(result, isNotNull);
        expect(result!.outcome, isNot('success'));
      });

      testWithoutContext('fails launch because of unexpected JSON', () async {
        const deviceControlOutput = '''
{
  "valid_unexpected_json": true
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned unexpected JSON response'));
        expect(tempFile, isNot(exists));
        expect(result, isNull);
      });

      testWithoutContext('fails launch because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('launch_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
              bundleId,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final IOSCoreDeviceLaunchResult? result = await deviceControl.launchApp(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned non-JSON response'));
        expect(tempFile, isNot(exists));
        expect(result, isNull);
      });
    });

    group('launchAppAndStreamLogs', () {
      const deviceId = 'device-id';
      const bundleId = 'com.example.flutterApp';

      testWithoutContext('Successful launch without launch args', () async {
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              ..._interactiveModeArgs,
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--start-stopped',
              '--console',
              '--environment-variables',
              '{"OS_ACTIVITY_DT_MODE": "enable"}',
              bundleId,
            ],
            stdout: '''
10:04:12  Acquired tunnel connection to device.
10:04:12  Enabling developer disk image services.
10:04:12  Acquired usage assertion.
Launched application with com.example.my_app bundle identifier.
Waiting for the application to terminate...
''',
          ),
        );

        final shutdownHooks = FakeShutdownHooks();
        final bool result = await deviceControl.launchAppAndStreamLogs(
          deviceId: deviceId,
          bundleId: bundleId,
          coreDeviceLogForwarder: FakeIOSCoreDeviceLogForwarder(),
          startStopped: true,
          shutdownHooks: shutdownHooks,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(shutdownHooks.registeredHooks.length, 1);
        expect(logger.errorText, isEmpty);
        expect(result, isTrue);
      });

      testWithoutContext('Successful launch with launch args', () async {
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              ..._interactiveModeArgs,
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--start-stopped',
              '--console',
              '--environment-variables',
              '{"OS_ACTIVITY_DT_MODE": "enable"}',
              bundleId,
              '--arg1',
              '--arg2',
            ],
            stdout: '''
10:04:12  Acquired tunnel connection to device.
10:04:12  Enabling developer disk image services.
10:04:12  Acquired usage assertion.
Launched application with com.example.my_app bundle identifier.
Waiting for the application to terminate...
''',
          ),
        );
        final shutdownHooks = FakeShutdownHooks();
        final bool result = await deviceControl.launchAppAndStreamLogs(
          deviceId: deviceId,
          bundleId: bundleId,
          coreDeviceLogForwarder: FakeIOSCoreDeviceLogForwarder(),
          startStopped: true,
          launchArguments: ['--arg1', '--arg2'],
          shutdownHooks: shutdownHooks,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(shutdownHooks.registeredHooks.length, 1);
        expect(logger.errorText, isEmpty);
        expect(result, isTrue);
      });

      testWithoutContext('Successful stream logs', () async {
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              ..._interactiveModeArgs,
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--start-stopped',
              '--console',
              '--environment-variables',
              '{"OS_ACTIVITY_DT_MODE": "enable"}',
              bundleId,
            ],
            stdout: '''
10:04:12  Acquired tunnel connection to device.
10:04:12  Enabling developer disk image services.
10:04:12  Acquired usage assertion.
This log happens before the application is launched and should not be sent to FakeIOSCoreDeviceLogForwarder
Launched application with com.example.my_app bundle identifier.
Waiting for the application to terminate...
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] [PreviewsAgentExecutorLibrary] This log happens after the application is launched but matches an ignore pattern and should be skipped
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] This log happens after the application is launched but matches an ignore pattern and should be skipped
This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] flutter: This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] [INFO:flutter/runtime/service_protocol.cc(121)] This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder
''',
          ),
        );
        final logForwarder = FakeIOSCoreDeviceLogForwarder();
        final shutdownHooks = FakeShutdownHooks();
        final bool result = await deviceControl.launchAppAndStreamLogs(
          deviceId: deviceId,
          bundleId: bundleId,
          coreDeviceLogForwarder: logForwarder,
          startStopped: true,
          shutdownHooks: shutdownHooks,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(shutdownHooks.registeredHooks.length, 1);
        expect(logger.errorText, isEmpty);
        expect(logForwarder.logs.length, 3);
        expect(
          logForwarder.logs,
          containsAll([
            'This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder',
            '2025-09-16 12:15:47.939171-0500 Runner[1230:133819] flutter: This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder',
            '2025-09-16 12:15:47.939171-0500 Runner[1230:133819] [INFO:flutter/runtime/service_protocol.cc(121)] This log happens after the application is launched and should be sent to FakeIOSCoreDeviceLogForwarder',
          ]),
        );
        expect(
          logger.traceText,
          contains('''
10:04:12  Acquired tunnel connection to device.
10:04:12  Enabling developer disk image services.
10:04:12  Acquired usage assertion.
This log happens before the application is launched and should not be sent to FakeIOSCoreDeviceLogForwarder
Launched application with com.example.my_app bundle identifier.
Waiting for the application to terminate...
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] [PreviewsAgentExecutorLibrary] This log happens after the application is launched but matches an ignore pattern and should be skipped
2025-09-16 12:15:47.939171-0500 Runner[1230:133819] This log happens after the application is launched but matches an ignore pattern and should be skipped
'''),
        );
        expect(result, isTrue);
      });

      testWithoutContext('devicectl fails launch with an error', () async {
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              ..._interactiveModeArgs,
              'xcrun',
              'devicectl',
              'device',
              'process',
              'launch',
              '--device',
              deviceId,
              '--start-stopped',
              '--console',
              '--environment-variables',
              '{"OS_ACTIVITY_DT_MODE": "enable"}',
              bundleId,
            ],
            exitCode: 1,
            stderr: '''
ERROR: The operation couldn?t be completed. (OSStatus error -10814.) (NSOSStatusErrorDomain error -10814.)
    _LSFunction = runEvaluator
    _LSLine = 1608
''',
          ),
        );
        final shutdownHooks = FakeShutdownHooks();
        final bool result = await deviceControl.launchAppAndStreamLogs(
          deviceId: deviceId,
          bundleId: bundleId,
          coreDeviceLogForwarder: FakeIOSCoreDeviceLogForwarder(),
          startStopped: true,
          shutdownHooks: shutdownHooks,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(shutdownHooks.registeredHooks.length, 1);
        expect(logger.errorText, isEmpty);
        expect(result, isFalse);
      });
    });

    group('terminate app', () {
      const deviceId = 'device-id';
      const processId = 1234;

      testWithoutContext('Successful terminate app', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "terminate",
      "--device",
      "00001234-0001234A3C03401E",
      "--pid",
      "1234",
      "--json-output",
      "./temp.txt"
    ],
    "commandType" : "devicectl.device.process.terminate",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "jsonVersion" : 2,
    "outcome" : "success",
    "version" : "477.29"
  },
  "result" : {
    "deviceIdentifier" : "95F6A339-849B-50D6-B27A-4DB39527E070",
    "deviceTimestamp" : "2025-08-07T16:13:35.220Z",
    "process" : {
      "executable" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner",
      "processIdentifier" : 1234
    },
    "signal" : {
      "name" : "SIGTERM",
      "value" : 15
    }
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('terminate_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'terminate',
              '--device',
              deviceId,
              '--pid',
              processId.toString(),
              '--kill',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.terminateProcess(
          deviceId: deviceId,
          processId: processId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(status, true);
      });

      testWithoutContext('devicectl fails terminate with an error', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : 3,
    "domain" : "NSPOSIXErrorDomain",
    "userInfo" : {

    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "terminate",
      "--device",
      "00001234-0001234A3C03401E",
      "--pid",
      "1234",
      "--json-output",
      "./temp.txt"
    ],
    "commandType" : "devicectl.device.process.terminate",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "jsonVersion" : 2,
    "outcome" : "failed",
    "version" : "477.29"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('terminate_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'terminate',
              '--device',
              deviceId,
              '--pid',
              processId.toString(),
              '--kill',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
            exitCode: 1,
            stderr: '''
ERROR: The operation couldn?t be completed. (OSStatus error -10814.) (NSOSStatusErrorDomain error -10814.)
    _LSFunction = runEvaluator
    _LSLine = 1608
''',
          ),
        );

        final bool status = await deviceControl.terminateProcess(
          deviceId: deviceId,
          processId: processId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('ERROR: The operation couldn?t be completed.'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('devicectl fails terminate without an error', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "process",
      "terminate",
      "--device",
      "00001234-0001234A3C03401E",
      "--pid",
      "1234",
      "--json-output",
      "./temp.txt"
    ],
    "commandType" : "devicectl.device.process.terminate",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "jsonVersion" : 2,
    "outcome" : "failed",
    "version" : "477.29"
  },
  "result" : {
    "deviceIdentifier" : "95F6A339-849B-50D6-B27A-4DB39527E070",
    "deviceTimestamp" : "2025-08-07T16:13:35.220Z",
    "process" : {
      "executable" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner",
      "processIdentifier" : 1234
    },
    "signal" : {
      "name" : "SIGTERM",
      "value" : 15
    }
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('terminate_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'terminate',
              '--device',
              deviceId,
              '--pid',
              processId.toString(),
              '--kill',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.terminateProcess(
          deviceId: deviceId,
          processId: processId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails launch because of unexpected JSON', () async {
        const deviceControlOutput = '''
{
  "valid_unexpected_json": true
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('terminate_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'terminate',
              '--device',
              deviceId,
              '--pid',
              processId.toString(),
              '--kill',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.terminateProcess(
          deviceId: deviceId,
          processId: processId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned unexpected JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails launch because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('terminate_results.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'process',
              'terminate',
              '--device',
              deviceId,
              '--pid',
              processId.toString(),
              '--kill',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.terminateProcess(
          deviceId: deviceId,
          processId: processId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('devicectl returned non-JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });
    });

    group('list apps', () {
      const deviceId = 'device-id';
      const bundleId = 'com.example.flutterApp';

      testWithoutContext('Successfully parses apps', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "info",
      "apps",
      "--device",
      "00001234-0001234A3C03401E",
      "--bundle-id",
      "com.example.flutterApp",
      "--json-output",
      "apps.txt"
    ],
    "commandType" : "devicectl.device.info.apps",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "apps" : [
      {
        "appClip" : false,
        "builtByDeveloper" : true,
        "bundleIdentifier" : "com.example.flutterApp",
        "bundleVersion" : "1",
        "defaultApp" : false,
        "hidden" : false,
        "internalApp" : false,
        "name" : "Bundle",
        "removable" : true,
        "url" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
        "version" : "1.0.0"
      },
      {
        "appClip" : true,
        "builtByDeveloper" : false,
        "bundleIdentifier" : "com.example.flutterApp2",
        "bundleVersion" : "2",
        "defaultApp" : true,
        "hidden" : true,
        "internalApp" : true,
        "name" : "Bundle 2",
        "removable" : false,
        "url" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
        "version" : "1.0.0"
      }
    ],
    "defaultAppsIncluded" : false,
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "hiddenAppsIncluded" : false,
    "internalAppsIncluded" : false,
    "matchingBundleIdentifier" : "com.example.flutterApp",
    "removableAppsIncluded" : true
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDeviceInstalledApp> apps = await deviceControl.getInstalledApps(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(apps.length, 2);

        expect(apps[0].appClip, isFalse);
        expect(apps[0].builtByDeveloper, isTrue);
        expect(apps[0].bundleIdentifier, 'com.example.flutterApp');
        expect(apps[0].bundleVersion, '1');
        expect(apps[0].defaultApp, isFalse);
        expect(apps[0].hidden, isFalse);
        expect(apps[0].internalApp, isFalse);
        expect(apps[0].name, 'Bundle');
        expect(apps[0].removable, isTrue);
        expect(
          apps[0].url,
          'file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/',
        );
        expect(apps[0].version, '1.0.0');

        expect(apps[1].appClip, isTrue);
        expect(apps[1].builtByDeveloper, isFalse);
        expect(apps[1].bundleIdentifier, 'com.example.flutterApp2');
        expect(apps[1].bundleVersion, '2');
        expect(apps[1].defaultApp, isTrue);
        expect(apps[1].hidden, isTrue);
        expect(apps[1].internalApp, isTrue);
        expect(apps[1].name, 'Bundle 2');
        expect(apps[1].removable, isFalse);
        expect(
          apps[1].url,
          'file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/',
        );
        expect(apps[1].version, '1.0.0');
      });

      testWithoutContext('Successfully find installed app', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "info",
      "apps",
      "--device",
      "00001234-0001234A3C03401E",
      "--bundle-id",
      "com.example.flutterApp",
      "--json-output",
      "apps.txt"
    ],
    "commandType" : "devicectl.device.info.apps",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "apps" : [
      {
        "appClip" : false,
        "builtByDeveloper" : true,
        "bundleIdentifier" : "com.example.flutterApp",
        "bundleVersion" : "1",
        "defaultApp" : false,
        "hidden" : false,
        "internalApp" : false,
        "name" : "Bundle",
        "removable" : true,
        "url" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
        "version" : "1.0.0"
      }
    ],
    "defaultAppsIncluded" : false,
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "hiddenAppsIncluded" : false,
    "internalAppsIncluded" : false,
    "matchingBundleIdentifier" : "com.example.flutterApp",
    "removableAppsIncluded" : true
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.isAppInstalled(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(status, true);
      });

      testWithoutContext('Succeeds but does not find app', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "info",
      "apps",
      "--device",
      "00001234-0001234A3C03401E",
      "--bundle-id",
      "com.example.flutterApp",
      "--json-output",
      "apps.txt"
    ],
    "commandType" : "devicectl.device.info.apps",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "341"
  },
  "result" : {
    "apps" : [
    ],
    "defaultAppsIncluded" : false,
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "hiddenAppsIncluded" : false,
    "internalAppsIncluded" : false,
    "matchingBundleIdentifier" : "com.example.flutterApp",
    "removableAppsIncluded" : true
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.isAppInstalled(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, isEmpty);
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('devicectl fails to get apps', () async {
        const deviceControlOutput = '''
{
  "error" : {
    "code" : 1000,
    "domain" : "com.apple.dt.CoreDeviceError",
    "userInfo" : {
      "NSLocalizedDescription" : {
        "string" : "The specified device was not found."
      }
    }
  },
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "info",
      "apps",
      "--device",
      "00001234-0001234A3C03401E",
      "--bundle-id",
      "com.example.flutterApp",
      "--json-output",
      "apps.txt"
    ],
    "commandType" : "devicectl.device.info.apps",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "failed",
    "version" : "341"
  }
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
            exitCode: 1,
            stderr: '''
ERROR: The specified device was not found. (com.apple.dt.CoreDeviceError error 1000.)
''',
          ),
        );

        final bool status = await deviceControl.isAppInstalled(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('ERROR: The specified device was not found.'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails launch because of unexpected JSON', () async {
        const deviceControlOutput = '''
{
  "valid_unexpected_json": true
}
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.isAppInstalled(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('devicectl returned unexpected JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });

      testWithoutContext('fails launch because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_app_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'apps',
              '--device',
              deviceId,
              '--bundle-id',
              bundleId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final bool status = await deviceControl.isAppInstalled(
          deviceId: deviceId,
          bundleId: bundleId,
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('devicectl returned non-JSON response'));
        expect(tempFile, isNot(exists));
        expect(status, false);
      });
    });

    group('list devices', () {
      testWithoutContext('Handles FileSystemException deleting temp directory', () async {
        final Directory tempDir = fileSystem.systemTempDirectory.childDirectory(
          'core_devices.rand0',
        );
        final File tempFile = tempDir.childFile('core_device_list.json');
        final args = <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ];
        fakeProcessManager.addCommand(
          FakeCommand(
            command: args,
            onRun: (_) {
              // Simulate that this command ran, but the OS simultaneously
              // deleted the temp directory before it could exit.
              expect(tempFile, exists);
              tempDir.deleteSync(recursive: true);
              expect(tempFile, isNot(exists));
              throw ProcessException(args.first, args.sublist(1));
            },
          ),
        );

        await expectLater(deviceControl.getCoreDevices(), completion(isEmpty));
        expect(logger.traceText, contains('Error executing devicectl: ProcessException'));
        expect(fakeProcessManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Handles json file mysteriously disappearing', () async {
        final Directory tempDir = fileSystem.systemTempDirectory.childDirectory(
          'core_devices.rand0',
        );
        final File tempFile = tempDir.childFile('core_device_list.json');
        final args = <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ];
        fakeProcessManager.addCommand(
          FakeCommand(
            command: args,
            onRun: (_) {
              // Simulate that this command deleted tempFile, did not create a
              // new one, and exited successfully
              expect(tempFile, exists);
              tempFile.deleteSync();
              expect(tempFile, isNot(exists));
            },
          ),
        );

        await expectLater(
          () => deviceControl.getCoreDevices(),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('Expected the file ${tempFile.path} to exist but it did not'),
            ),
          ),
        );
        expect(
          logger.traceText,
          contains(
            'After running the command xcrun devicectl list devices '
            '--timeout 5 --json-output ${tempFile.path} the file\n'
            '${tempFile.path} was expected to exist, but it did not',
          ),
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Handles file system disposal', () async {
        final LocalFileSystem localFs = LocalFileSystemFake();
        final fs = ErrorHandlingFileSystem(delegate: localFs, platform: FakePlatform());
        deviceControl = IOSCoreDeviceControl(
          logger: logger,
          processManager: fakeProcessManager,
          xcode: xcode,
          fileSystem: fs,
        );
        final Directory tempDir = localFs.systemTempDirectory.childDirectory('core_devices.rand0');
        final File tempFile = tempDir.childFile('core_device_list.json');
        final args = <String>[
          'xcrun',
          'devicectl',
          'list',
          'devices',
          '--timeout',
          '5',
          '--json-output',
          tempFile.path,
        ];
        fakeProcessManager.addCommand(
          FakeCommand(
            command: args,
            onRun: (_) {
              // Simulate that the tool started shutting down and disposed the
              // file system, causing the temp directory to be deleted before
              // this program invocation returns a result.
              localFs.dispose();
              expect(localFs.disposed, true);
            },
          ),
        );

        final List<IOSCoreDevice> coreDevices = await deviceControl.getCoreDevices();
        expect(coreDevices, isEmpty);
        expect(
          logger.errorText,
          isNot(
            contains(
              'After running the command xcrun devicectl list devices '
              '--timeout 5 --json-output ${tempFile.path} the file\n'
              '${tempFile.path} was expected to exist, but it did not',
            ),
          ),
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
      });

      testWithoutContext('No devices', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [

    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(devices.isEmpty, isTrue);
      });

      testWithoutContext('All sections parsed', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "capabilities" : [
        ],
        "connectionProperties" : {
        },
        "deviceProperties" : {
        },
        "hardwareProperties" : {
        },
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.length, 1);
        expect(devices[0].capabilities, isNotNull);
        expect(devices[0].connectionProperties, isNotNull);
        expect(devices[0].deviceProperties, isNotNull);
        expect(devices[0].hardwareProperties, isNotNull);
        expect(devices[0].coreDeviceIdentifier, '123456BB5-AEDE-7A22-B890-1234567890DD');
        expect(devices[0].visibilityClass, 'default');
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('All sections parsed, device missing sections', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.length, 1);
        expect(devices[0].capabilities, isEmpty);
        expect(devices[0].connectionProperties, isNull);
        expect(devices[0].deviceProperties, isNull);
        expect(devices[0].hardwareProperties, isNull);
        expect(devices[0].coreDeviceIdentifier, '123456BB5-AEDE-7A22-B890-1234567890DD');
        expect(devices[0].visibilityClass, 'default');
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('capabilities parsed', () async {
        const deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "capabilities" : [
          {
            "featureIdentifier" : "com.apple.coredevice.feature.spawnexecutable",
            "name" : "Spawn Executable"
          },
          {
            "featureIdentifier" : "com.apple.coredevice.feature.launchapplication",
            "name" : "Launch Application"
          }
        ]
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();

        expect(devices.length, 1);

        expect(devices[0].capabilities.length, 2);
        expect(
          devices[0].capabilities[0].featureIdentifier,
          'com.apple.coredevice.feature.spawnexecutable',
        );
        expect(devices[0].capabilities[0].name, 'Spawn Executable');
        expect(
          devices[0].capabilities[1].featureIdentifier,
          'com.apple.coredevice.feature.launchapplication',
        );
        expect(devices[0].capabilities[1].name, 'Launch Application');

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('connectionProperties parsed', () async {
        const deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "connectionProperties" : {
          "authenticationType" : "manualPairing",
          "isMobileDeviceOnly" : false,
          "lastConnectionDate" : "2023-06-15T15:29:00.082Z",
          "localHostnames" : [
            "Victorias-iPad.coredevice.local",
            "00001234-0001234A3C03401E.coredevice.local",
            "123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local"
          ],
          "pairingState" : "paired",
          "potentialHostnames" : [
            "00001234-0001234A3C03401E.coredevice.local",
            "123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local"
          ],
          "transportType" : "wired",
          "tunnelIPAddress" : "fdf1:23c4:cd56::1",
          "tunnelState" : "connected",
          "tunnelTransportProtocol" : "tcp"
        }
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.length, 1);
        expect(devices[0].connectionProperties?.authenticationType, 'manualPairing');
        expect(devices[0].connectionProperties?.isMobileDeviceOnly, false);
        expect(devices[0].connectionProperties?.lastConnectionDate, '2023-06-15T15:29:00.082Z');
        expect(devices[0].connectionProperties?.localHostnames, <String>[
          'Victorias-iPad.coredevice.local',
          '00001234-0001234A3C03401E.coredevice.local',
          '123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local',
        ]);
        expect(devices[0].connectionProperties?.pairingState, 'paired');
        expect(devices[0].connectionProperties?.potentialHostnames, <String>[
          '00001234-0001234A3C03401E.coredevice.local',
          '123456BB5-AEDE-7A22-B890-1234567890DD.coredevice.local',
        ]);
        expect(devices[0].connectionProperties?.transportType, 'wired');
        expect(devices[0].connectionProperties?.tunnelIPAddress, 'fdf1:23c4:cd56::1');
        expect(devices[0].connectionProperties?.tunnelState, 'connected');
        expect(devices[0].connectionProperties?.tunnelTransportProtocol, 'tcp');
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('deviceProperties parsed', () async {
        const deviceControlOutput = '''
{
  "result" : {
    "devices" : [
      {
        "deviceProperties" : {
          "bootedFromSnapshot" : true,
          "bootedSnapshotName" : "com.apple.os.update-123456",
          "bootState" : "booted",
          "ddiServicesAvailable" : true,
          "developerModeStatus" : "enabled",
          "hasInternalOSBuild" : false,
          "name" : "iPadName",
          "osBuildUpdate" : "21A5248v",
          "osVersionNumber" : "17.0",
          "rootFileSystemIsWritable" : false,
          "screenViewingURL" : "coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD"
        }
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.length, 1);
        expect(devices[0].deviceProperties?.bootedFromSnapshot, true);
        expect(devices[0].deviceProperties?.bootedSnapshotName, 'com.apple.os.update-123456');
        expect(devices[0].deviceProperties?.bootState, 'booted');
        expect(devices[0].deviceProperties?.ddiServicesAvailable, true);
        expect(devices[0].deviceProperties?.developerModeStatus, 'enabled');
        expect(devices[0].deviceProperties?.hasInternalOSBuild, false);
        expect(devices[0].deviceProperties?.name, 'iPadName');
        expect(devices[0].deviceProperties?.osBuildUpdate, '21A5248v');
        expect(devices[0].deviceProperties?.osVersionNumber, '17.0');
        expect(devices[0].deviceProperties?.rootFileSystemIsWritable, false);
        expect(
          devices[0].deviceProperties?.screenViewingURL,
          'coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD',
        );
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('hardwareProperties parsed', () async {
        const deviceControlOutput = r'''
{
  "result" : {
    "devices" : [
      {
        "hardwareProperties" : {
          "cpuType" : {
            "name" : "arm64e",
            "subType" : 2,
            "type" : 16777228
          },
          "deviceType" : "iPad",
          "ecid" : 12345678903408542,
          "hardwareModel" : "J617AP",
          "internalStorageCapacity" : 128000000000,
          "marketingName" : "iPad Pro (11-inch) (4th generation)\"",
          "platform" : "iOS",
          "productType" : "iPad14,3",
          "serialNumber" : "HC123DHCQV",
          "supportedCPUTypes" : [
            {
              "name" : "arm64e",
              "subType" : 2,
              "type" : 16777228
            },
            {
              "name" : "arm64",
              "subType" : 0,
              "type" : 16777228
            }
          ],
          "supportedDeviceFamilies" : [
            1,
            2
          ],
          "thinningProductType" : "iPad14,3-A",
          "udid" : "00001234-0001234A3C03401E"
        }
      }
    ]
  }
}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'list',
              'devices',
              '--timeout',
              '5',
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
        expect(devices.length, 1);
        expect(devices[0].hardwareProperties?.cpuType, isNotNull);
        expect(devices[0].hardwareProperties?.cpuType?.name, 'arm64e');
        expect(devices[0].hardwareProperties?.cpuType?.subType, 2);
        expect(devices[0].hardwareProperties?.cpuType?.cpuType, 16777228);
        expect(devices[0].hardwareProperties?.deviceType, 'iPad');
        expect(devices[0].hardwareProperties?.ecid, 12345678903408542);
        expect(devices[0].hardwareProperties?.hardwareModel, 'J617AP');
        expect(devices[0].hardwareProperties?.internalStorageCapacity, 128000000000);
        expect(
          devices[0].hardwareProperties?.marketingName,
          'iPad Pro (11-inch) (4th generation)"',
        );
        expect(devices[0].hardwareProperties?.platform, 'iOS');
        expect(devices[0].hardwareProperties?.productType, 'iPad14,3');
        expect(devices[0].hardwareProperties?.serialNumber, 'HC123DHCQV');
        expect(devices[0].hardwareProperties?.supportedCPUTypes, isNotNull);
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].name, 'arm64e');
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].subType, 2);
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[0].cpuType, 16777228);
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].name, 'arm64');
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].subType, 0);
        expect(devices[0].hardwareProperties?.supportedCPUTypes?[1].cpuType, 16777228);
        expect(devices[0].hardwareProperties?.supportedDeviceFamilies, <int>[1, 2]);
        expect(devices[0].hardwareProperties?.thinningProductType, 'iPad14,3-A');
        expect(devices[0].hardwareProperties?.udid, '00001234-0001234A3C03401E');
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      group('Handles errors', () {
        testWithoutContext('invalid json', () async {
          const deviceControlOutput = '''Invalid JSON''';

          final File tempFile = fileSystem.systemTempDirectory
              .childDirectory('core_devices.rand0')
              .childFile('core_device_list.json');
          fakeProcessManager.addCommand(
            FakeCommand(
              command: <String>[
                'xcrun',
                'devicectl',
                'list',
                'devices',
                '--timeout',
                '5',
                '--json-output',
                tempFile.path,
              ],
              onRun: (_) {
                expect(tempFile, exists);
                tempFile.writeAsStringSync(deviceControlOutput);
              },
            ),
          );

          final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
          expect(devices.isEmpty, isTrue);
          expect(fakeProcessManager, hasNoRemainingExpectations);
          expect(logger.traceText, contains('devicectl returned non-JSON response.'));
          expect(tempFile, isNot(exists));
        });

        testWithoutContext('unexpected json', () async {
          const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : [

  ]
}
''';

          final File tempFile = fileSystem.systemTempDirectory
              .childDirectory('core_devices.rand0')
              .childFile('core_device_list.json');
          fakeProcessManager.addCommand(
            FakeCommand(
              command: <String>[
                'xcrun',
                'devicectl',
                'list',
                'devices',
                '--timeout',
                '5',
                '--json-output',
                tempFile.path,
              ],
              onRun: (_) {
                expect(tempFile, exists);
                tempFile.writeAsStringSync(deviceControlOutput);
              },
            ),
          );

          final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices();
          expect(devices.isEmpty, isTrue);
          expect(fakeProcessManager, hasNoRemainingExpectations);
          expect(logger.traceText, contains('devicectl returned unexpected JSON response:'));
          expect(tempFile, isNot(exists));
        });

        testWithoutContext('Cancels operation when cancelCompleter completes', () async {
          final cancelCompleter = Completer<void>();
          final Directory tempDir = fileSystem.systemTempDirectory.childDirectory(
            'core_devices.rand0',
          );
          final File tempFile = tempDir.childFile('core_device_list.json');
          final processCompleter = Completer<void>();
          final fakeProcess = FakeProcess();

          fakeProcessManager.addCommand(
            FakeCommand(
              command: <String>[
                'xcrun',
                'devicectl',
                'list',
                'devices',
                '--timeout',
                '5',
                '--json-output',
                tempFile.path,
              ],
              onRun: (_) async {
                expect(tempFile, exists);
                await processCompleter.future;
              },
              process: fakeProcess,
            ),
          );

          final Future<List<IOSCoreDevice>> devicesFuture = deviceControl.getCoreDevices(
            cancelCompleter: cancelCompleter,
          );

          cancelCompleter.complete();

          final List<IOSCoreDevice> devices = await devicesFuture;
          expect(devices, isEmpty);
          expect(fakeProcessManager, hasNoRemainingExpectations);
          expect(tempFile, isNot(exists));
          expect(fakeProcess.signals, contains(io.ProcessSignal.sigterm));

          processCompleter.complete();
        });

        testWithoutContext('When timeout is below minimum, default to minimum', () async {
          const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "list",
      "devices",
      "--json-output",
      "core_device_list.json"
    ],
    "commandType" : "devicectl.list.devices",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "outcome" : "success",
    "version" : "325.3"
  },
  "result" : {
    "devices" : [
      {
        "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
        "visibilityClass" : "default"
      }
    ]
  }
}
''';

          final File tempFile = fileSystem.systemTempDirectory
              .childDirectory('core_devices.rand0')
              .childFile('core_device_list.json');
          fakeProcessManager.addCommand(
            FakeCommand(
              command: <String>[
                'xcrun',
                'devicectl',
                'list',
                'devices',
                '--timeout',
                '5',
                '--json-output',
                tempFile.path,
              ],
              onRun: (_) {
                expect(tempFile, exists);
                tempFile.writeAsStringSync(deviceControlOutput);
              },
            ),
          );
          final List<IOSCoreDevice> devices = await deviceControl.getCoreDevices(
            timeout: const Duration(seconds: 2),
          );
          expect(devices.isNotEmpty, isTrue);
          expect(fakeProcessManager, hasNoRemainingExpectations);
          expect(
            logger.warningText,
            contains(
              'Timeout of 2 seconds is below the minimum timeout value '
              'for devicectl. Changing the timeout to the minimum value of 5.',
            ),
          );
        });
      });
    });

    group('list running processes', () {
      const deviceId = 'device-id';

      testWithoutContext('All sections parsed', () async {
        const deviceControlOutput = '''
{
  "info" : {
    "arguments" : [
      "devicectl",
      "device",
      "info",
      "processes",
      "--device",
      "00008112-0006112A3C03401E",
      "--json-output",
      "./process.json"
    ],
    "commandType" : "devicectl.device.info.processes",
    "environment" : {
      "TERM" : "xterm-256color"
    },
    "jsonVersion" : 2,
    "outcome" : "success",
    "version" : "477.29"
  },
  "result" : {
    "deviceIdentifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
    "runningProcesses" : [
      {
        "executable" : "file:///sbin/launchd",
        "processIdentifier" : 1
      },
      {
        "processIdentifier" : 961
      },
      {
        "executable" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner",
        "processIdentifier" : 1050
      }
    ]
  }
}

''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_process_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'processes',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDeviceRunningProcess> processes = await deviceControl.getRunningProcesses(
          deviceId: deviceId,
        );
        expect(processes.length, 3);

        expect(processes[0].processIdentifier, isNotNull);
        expect(processes[0].executable, isNotNull);
        expect(processes[1].processIdentifier, isNotNull);
        expect(processes[1].executable, isNull);
        expect(processes[2].processIdentifier, 1050);
        expect(
          processes[2].executable,
          'file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/Runner',
        );

        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
      });

      testWithoutContext('fails because of unexpected JSON', () async {
        const deviceControlOutput = '''
{"valid": "but wrong"}
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_process_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'processes',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDeviceRunningProcess> processes = await deviceControl.getRunningProcesses(
          deviceId: deviceId,
        );
        expect(processes.length, 0);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(logger.traceText, contains('devicectl returned unexpected JSON response'));
      });

      testWithoutContext('fails because of invalid JSON', () async {
        const deviceControlOutput = '''
invalid JSON
''';

        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_process_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'processes',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              expect(tempFile, exists);
              tempFile.writeAsStringSync(deviceControlOutput);
            },
          ),
        );

        final List<IOSCoreDeviceRunningProcess> processes = await deviceControl.getRunningProcesses(
          deviceId: deviceId,
        );
        expect(processes.length, 0);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(logger.traceText, contains('devicectl returned non-JSON response'));
      });

      testWithoutContext('fails when devicectl fails', () async {
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_process_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'processes',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
            ],
            stderr: 'something went wrong',
            exitCode: 1,
          ),
        );

        final List<IOSCoreDeviceRunningProcess> processes = await deviceControl.getRunningProcesses(
          deviceId: deviceId,
        );
        expect(processes.length, 0);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(logger.traceText, contains('something went wrong'));
      });

      testWithoutContext('fails when missing output', () async {
        final File tempFile = fileSystem.systemTempDirectory
            .childDirectory('core_devices.rand0')
            .childFile('core_device_process_list.json');
        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'devicectl',
              'device',
              'info',
              'processes',
              '--device',
              deviceId,
              '--json-output',
              tempFile.path,
            ],
            onRun: (_) {
              tempFile.deleteSync();
            },
          ),
        );

        final List<IOSCoreDeviceRunningProcess> processes = await deviceControl.getRunningProcesses(
          deviceId: deviceId,
        );
        expect(processes.length, 0);
        expect(fakeProcessManager, hasNoRemainingExpectations);
        expect(tempFile, isNot(exists));
        expect(logger.traceText, contains('Error reading output file'));
      });
    });
  });
}

class FakeIOSCoreDeviceControl extends Fake implements IOSCoreDeviceControl {
  FakeIOSCoreDeviceControl({
    this.installSuccess = true,
    this.installResult,
    this.launchSuccess = true,
    this.launchResult,
    this.terminateSuccess = true,
    this.runningProcesses = const <IOSCoreDeviceRunningProcess>[],
  });

  bool installSuccess;
  IOSCoreDeviceLaunchResult? launchResult;
  bool launchSuccess;
  IOSCoreDeviceInstallResult? installResult;
  bool terminateSuccess;
  int? processTerminated;
  List<IOSCoreDeviceRunningProcess> runningProcesses;
  bool get terminateProcessCalled => processTerminated != null;

  @override
  Future<List<IOSCoreDevice>> getCoreDevices({
    Duration timeout = const Duration(seconds: 5),
    Completer<void>? cancelCompleter,
  }) async {
    return <IOSCoreDevice>[];
  }

  @override
  Future<(bool, IOSCoreDeviceInstallResult?)> installApp({
    required String deviceId,
    required String bundlePath,
  }) async {
    if (installResult != null) {
      return (installSuccess, installResult);
    }
    final result = IOSCoreDeviceInstallResult.fromJson(<String, Object?>{
      'info': <String, Object?>{'outcome': installSuccess ? 'success' : 'failure'},
    });
    return (installSuccess, result);
  }

  @override
  Future<IOSCoreDeviceLaunchResult?> launchApp({
    required String deviceId,
    required String bundleId,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
  }) async {
    return launchResult;
  }

  @override
  Future<bool> launchAppAndStreamLogs({
    required IOSCoreDeviceLogForwarder coreDeviceLogForwarder,
    required String deviceId,
    required String bundleId,
    required ShutdownHooks shutdownHooks,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
  }) async {
    return launchSuccess;
  }

  @override
  Future<bool> terminateProcess({required String deviceId, required int processId}) async {
    processTerminated = processId;
    return terminateSuccess;
  }

  @override
  Future<List<IOSCoreDeviceRunningProcess>> getRunningProcesses({required String deviceId}) async {
    return runningProcesses;
  }
}

class FakeXcodeDebug extends Fake implements XcodeDebug {
  FakeXcodeDebug({this.tempXcodeProject, this.expectedProject, this.expectedLaunchArguments});
  bool exitSuccess = true;
  var _debugStarted = false;
  bool exitCalled = false;
  bool isTemporaryProject = false;
  Directory? tempXcodeProject;
  XcodeDebugProject? expectedProject;
  List<String>? expectedLaunchArguments;

  @override
  bool get debugStarted => _debugStarted;

  @override
  Future<XcodeDebugProject> createXcodeProjectWithCustomBundle(
    String deviceBundlePath, {
    required TemplateRenderer templateRenderer,
    Directory? projectDestination,
    bool verboseLogging = false,
  }) async {
    isTemporaryProject = true;
    return XcodeDebugProject(
      scheme: 'Runner',
      hostAppProjectName: 'Runner',
      xcodeProject: tempXcodeProject!.childDirectory('Runner.xcodeproj'),
      xcodeWorkspace: tempXcodeProject!.childDirectory('Runner.xcworkspace'),
      isTemporaryProject: true,
      verboseLogging: verboseLogging,
    );
  }

  @override
  Future<bool> debugApp({
    required XcodeDebugProject project,
    required String deviceId,
    required List<String> launchArguments,
  }) async {
    if (expectedProject != null) {
      expect(expectedProject, project);
      expect(expectedLaunchArguments, launchArguments);
    }
    _debugStarted = true;
    return true;
  }

  @override
  Future<bool> exit({bool force = false, bool skipDelay = false}) async {
    exitCalled = true;
    return exitSuccess;
  }

  @override
  void ensureXcodeDebuggerLaunchAction(File schemeFile) {}

  @override
  Future<void> updateConfigurationBuildDir({
    required FlutterProject project,
    required BuildInfo buildInfo,
    String? mainPath,
    required String configurationBuildDir,
  }) async {}
}

class FakeLLDB extends Fake implements LLDB {
  FakeLLDB({this.attachSuccess = true});
  bool attachSuccess;

  bool attemptedToAttach = false;

  var _isRunning = false;
  int? _processId;
  bool exitCalled = false;

  @override
  bool get isRunning => _isRunning;

  @override
  int? get appProcessId => _processId;

  void setIsRunning(bool running, int? processId) {
    _isRunning = running;
    _processId = processId;
  }

  @override
  Future<bool> attachAndStart({
    required String deviceId,
    required int appProcessId,
    required LLDBLogForwarder lldbLogForwarder,
  }) async {
    attemptedToAttach = true;
    return attachSuccess;
  }

  @override
  bool exit() {
    exitCalled = true;
    return true;
  }
}

class FakePrebuiltIOSApp extends Fake implements PrebuiltIOSApp {
  @override
  String get deviceBundlePath => '/path/to/prebuilt/app';
}

class FakeBuildableIOSApp extends Fake implements BuildableIOSApp {
  FakeBuildableIOSApp(this.project);

  @override
  String get deviceBundlePath => '/path/to/buildable/app';

  @override
  final IosProject project;
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject(this.ios);

  @override
  final IosProject ios;
}

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({this.missingWorkspace = false, this.missingScheme = false});

  late final _flutterProject = FakeFlutterProject(this);

  bool missingWorkspace;
  bool missingScheme;

  @override
  late FlutterProject parent = _flutterProject;

  @override
  Directory? get xcodeWorkspace {
    if (missingWorkspace) {
      return null;
    }
    return MemoryFileSystem.test().directory('Runner.xcworkspace');
  }

  @override
  Future<String?> schemeForBuildInfo(BuildInfo buildInfo, {Logger? logger}) async {
    if (missingScheme) {
      return null;
    }
    return 'Runner';
  }

  @override
  File xcodeProjectSchemeFile({String? scheme}) {
    final String schemeName = scheme ?? 'Runner';
    return xcodeProject
        .childDirectory('xcshareddata')
        .childDirectory('xcschemes')
        .childFile('$schemeName.xcscheme');
  }

  @override
  Directory get xcodeProject => MemoryFileSystem.test().directory('Runner.xcodeproj');

  @override
  String get hostAppProjectName => 'Runner';
}

class FakeTemplateRenderer extends Fake implements TemplateRenderer {}

class FakeIOSCoreDeviceLogForwarder extends Fake implements IOSCoreDeviceLogForwarder {
  List<String> logs = [];
  @override
  Process? launchProcess;

  @override
  bool get isRunning => false;
  @override
  Future<bool> exit() async {
    return true;
  }

  @override
  void addLog(String log) {
    logs.add(log);
  }
}

/// A [ShutdownHooks] implementation that does not actually execute any hooks.
class FakeShutdownHooks extends Fake implements ShutdownHooks {
  @override
  bool get isShuttingDown => _isShuttingDown;
  var _isShuttingDown = false;

  @override
  final registeredHooks = <ShutdownHook>[];

  @override
  void addShutdownHook(ShutdownHook shutdownHook) {
    registeredHooks.add(shutdownHook);
  }

  @override
  Future<void> runShutdownHooks(Logger logger) async {
    _isShuttingDown = true;
  }
}
