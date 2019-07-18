// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show ProcessSignal;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' hide MockProcessManager;
import '../../src/mocks.dart' as mocks show MockProcessManager;

class MockIOSApp extends Mock implements IOSApp {}
class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockDirectory extends Mock implements Directory {}
class MockFileSystem extends Mock implements FileSystem {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockProcess extends Mock implements Process {}
class MockApplicationPackage extends Mock implements ApplicationPackage {}

void main() {
  final FakePlatform macPlatform = FakePlatform.fromPlatform(const LocalPlatform());
  macPlatform.operatingSystem = 'macos';

  group('Process calls', () {
    MockIOSApp mockApp;
    MockArtifacts mockArtifacts;
    MockCache mockCache;
    MockFileSystem mockFileSystem;
    MockProcessManager mockProcessManager;
    const String installerPath = '/path/to/ideviceinstaller';
    const String appId = '789';
    const MapEntry<String, String> libraryEntry = MapEntry<String, String>(
      'DYLD_LIBRARY_PATH',
      '/path/to/libraries'
    );
    final Map<String, String> env = Map<String, String>.fromEntries(
      <MapEntry<String, String>>[libraryEntry]
    );

    setUp(() {
      mockApp = MockIOSApp();
      mockArtifacts = MockArtifacts();
      mockCache = MockCache();
      when(mockCache.dyLdLibEntry).thenReturn(libraryEntry);
      mockFileSystem = MockFileSystem();
      mockProcessManager = MockProcessManager();
      when(
        mockArtifacts.getArtifactPath(
          Artifact.ideviceinstaller,
          platform: anyNamed('platform'),
        )
      ).thenReturn(installerPath);
    });

    testUsingContext('installApp() invokes process with correct environment', () async {
      final IOSDevice device = IOSDevice('123');
      const String bundlePath = '/path/to/bundle';
      final List<String> args = <String>[installerPath, '-i', bundlePath];
      when(mockApp.deviceBundlePath).thenReturn(bundlePath);
      final MockDirectory directory = MockDirectory();
      when(mockFileSystem.directory(bundlePath)).thenReturn(directory);
      when(directory.existsSync()).thenReturn(true);
      when(mockProcessManager.run(args, environment: env))
        .thenAnswer(
          (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
        );
      await device.installApp(mockApp);
      verify(mockProcessManager.run(args, environment: env));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      Cache: () => mockCache,
      FileSystem: () => mockFileSystem,
      Platform: () => macPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isAppInstalled() invokes process with correct environment', () async {
      final IOSDevice device = IOSDevice('123');
      final List<String> args = <String>[installerPath, '--list-apps'];
      when(mockProcessManager.run(args, environment: env))
        .thenAnswer(
          (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
        );
      when(mockApp.id).thenReturn(appId);
      await device.isAppInstalled(mockApp);
      verify(mockProcessManager.run(args, environment: env));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      Cache: () => mockCache,
      Platform: () => macPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('uninstallApp() invokes process with correct environment', () async {
      final IOSDevice device = IOSDevice('123');
      final List<String> args = <String>[installerPath, '-U', appId];
      when(mockApp.id).thenReturn(appId);
      when(mockProcessManager.run(args, environment: env))
        .thenAnswer(
          (_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', ''))
        );
      await device.uninstallApp(mockApp);
      verify(mockProcessManager.run(args, environment: env));
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      Cache: () => mockCache,
      Platform: () => macPlatform,
      ProcessManager: () => mockProcessManager,
    });
  });

  group('getAttachedDevices', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
    });

    testUsingContext('return no devices if Xcode is not installed', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(false);
      expect(await IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value(''));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('10.3.2'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('Puits sans fond'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'ProductVersion'))
          .thenAnswer((_) => Future<String>.value('11.0'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices and ignores devices that cannot be found by ideviceinfo', () async {
      when(iMobileDevice.isInstalled).thenReturn(true);
      when(iMobileDevice.getAvailableDeviceIDs())
          .thenAnswer((Invocation invocation) => Future<String>.value('''
98206e7a4afd4aedaff06e687594e089dede3c44
f577a7903cc54959be2e34bc4f7f80b7009efcf4
'''));
      when(iMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenAnswer((_) => Future<String>.value('La tele me regarde'));
      when(iMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenThrow(IOSDeviceNotFoundError('Device not found'));
      final List<IOSDevice> devices = await IOSDevice.getAttachedDevices();
      expect(devices, hasLength(1));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });

  group('decodeSyslog', () {
    test('decodes a syslog-encoded line', () {
      final String decoded = decodeSyslog(r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog \M-B\M-/\134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');
      expect(decoded, r'I ❤️ syslog ¯\_(ツ)_/¯ 솠!');
    });

    test('passes through un-decodeable lines as-is', () {
      final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');
      expect(decoded, r'I \M-b\M^O syslog!');
    });
  });
  group('logging', () {
    MockIMobileDevice mockIMobileDevice;
    MockIosProject mockIosProject;

    setUp(() {
      mockIMobileDevice = MockIMobileDevice();
      mockIosProject = MockIosProject();
    });

    testUsingContext('suppresses non-Flutter lines from output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: A is for ari
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
  Runner(Flutter)[297] <Notice>: I is for ichigo
  Runner(UIKit)[297] <Notice>: E is for enpitsu"
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('includes multi-line Flutter logs in the output', () async {
      when(mockIMobileDevice.startLogger('123456')).thenAnswer((Invocation invocation) {
        final Process mockProcess = MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            Stream<List<int>>.fromIterable(<List<int>>['''
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
  Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
  Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
  '''.codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
        return Future<Process>.value(mockProcess);
      });

      final IOSDevice device = IOSDevice('123456');
      final DeviceLogReader logReader = device.getLogReader(
        app: BuildableIOSApp(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
      expect(device.category, Category.mobile);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });

  testUsingContext('IOSDevice.isSupportedForProject is true on module project', () async {
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });

  testUsingContext('IOSDevice.isSupportedForProject is true with editable host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('ios').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });

  testUsingContext('IOSDevice.isSupportedForProject is false with no host app and no module', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSDevice('test').isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });

  group('IOSDeploy.runApp', () {
    mocks.MockProcessManager mockProcessManager;
    MemoryFileSystem fileSystem;
    const Utf8Encoder utf8 = Utf8Encoder();
    const String packageName = 'com.example.test';

    final MockApplicationPackage package = MockApplicationPackage();
    when(package.id).thenReturn(packageName);

    setUp(() {
      mockProcessManager = mocks.MockProcessManager();
      fileSystem = MemoryFileSystem();
      fileSystem.directory('/tmp').createSync();
    });

    // Detached, completes before exit:
    //   - start ios-deploy
    //   - autoexit -> detach
    //   - ios-deploy terminates
    //
    // Check:
    //   - no temp files leftover
    testUsingContext('Detached, completes before exit', () async {
      final Process iosDeploy = FakeProcess(
        exitCode: Future<int>.value(0),
        stdout: Stream<List<int>>.fromIterable(
          <String>['(lldb) autoexit\n'].map(utf8.convert)),
        stderr: const Stream<List<int>>.empty());

      mockProcessManager.processFactory = (_) => iosDeploy;
      await fs.directory('/tmp').create();

      final Completer<void> iosDeployTerminated = Completer<void>();
      await const IOSDeploy().runApp(
        package: package,
        deviceId: 'test',
        bundlePath: 'test',
        launchArguments: <String>[],
        onExit: () => iosDeployTerminated.complete()
      );

      await iosDeployTerminated.future;

      expect(fs.directory('/tmp').listSync().length, 0);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    // Detached, suspended after exit:
    //   - start ios-deploy
    //   - autoexit -> detach
    //
    //   - start ios-fdeploy (again)
    //   - once the old pid is killed, ios-deploy continues
    //   - detaches
    //
    // Check:
    //   - second launch doesn't hang
    testUsingContext('Detached, suspended after exit', () async {
      // Doesn't terminate.
      final Process firstIosDeploy = FakeProcess(
        exitCode: Completer<int>().future,
        stdout: Stream<List<int>>.fromIterable(
          <String>['(lldb) autoexit\n'].map(utf8.convert)),
        stderr: const Stream<List<int>>.empty(),
        pid: 101);

      mockProcessManager.processFactory = (_) => firstIosDeploy;

      await const IOSDeploy().runApp(
        package: package,
        deviceId: 'test',
        bundlePath: 'test',
        launchArguments: <String>[],
      );

      final Completer<void> oldIosKilled = Completer<void>();
      mockProcessManager.killHandler = (int pid, io.ProcessSignal signal) {
        if (!oldIosKilled.isCompleted && pid == 101 && signal == io.ProcessSignal.sigterm) {
          oldIosKilled.complete();
          return true;
        }
        return false;
      };

      // Also doesn't terminate, but doesn't even detach until the first one is killed.
      final StreamController<String> secondIosStdout = StreamController<String>();
      final Process secondIosDeploy = FakeProcess(
        exitCode: Completer<int>().future,
        stdout: secondIosStdout.stream.map((String line) => utf8.convert(line + '\n')),
        stderr: const Stream<List<int>>.empty(),
        pid: 102);

      // The second `ios-deploy` can only continue once the first one has been killed.
      unawaited(oldIosKilled.future.then((_) => secondIosStdout.add('(lldb) autoexit')));

      mockProcessManager.processFactory = (_) => secondIosDeploy;
      mockProcessManager.processRunHandler = (_) {
        // Fake 'ps -p ...' results which show a running `ios-deploy` process.
        return ProcessResult(0, 0, 'ios-deploy', '');
      };

      await const IOSDeploy().runApp(
        package: package,
        deviceId: 'test',
        bundlePath: 'test',
        launchArguments: <String>[],
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    // Detached, killed after exit:
    //   - start ios-deploy
    //   - autoexit -> detach
    //   - (we exit)
    //
    //   - ios-deploy process is killed (system rebooted, most likely)
    //
    //   - start ios-deploy
    //
    // Check:
    //   - no processes are killed
    testUsingContext('Detached, killed after exit', () async {
      // Doesn't terminate.
      final Process firstIosDeploy = FakeProcess(
        exitCode: Completer<int>().future,
        stdout: Stream<List<int>>.fromIterable(
          <String>['(lldb) autoexit\n'].map(utf8.convert)),
        stderr: const Stream<List<int>>.empty(),
        pid: 101);

      mockProcessManager.processFactory = (_) => firstIosDeploy;

      await const IOSDeploy().runApp(
        package: package,
        deviceId: 'test',
        bundlePath: 'test',
        launchArguments: <String>[],
      );

      // The first `ios-deploy` process was "killed" somehow. To push the circumstances,
      // we supposed that Chrome is now running with the same PID. It should definitely *not* be killed!
      mockProcessManager.processRunHandler = (_) {
        return ProcessResult(0, 0, 'Google Chrome Helper', '');
      };

      mockProcessManager.killHandler = (int pid, io.ProcessSignal signal) {
        assert(false);
        return false;
      };

      final Process secondIosDeploy = FakeProcess(
        exitCode: Future<int>.value(0),
        stdout: Stream<List<int>>.fromIterable(<String>['(lldb) autoexit\n'].map(utf8.convert)),
        stderr: const Stream<List<int>>.empty(),
        pid: 102);

      mockProcessManager.processFactory = (_) => secondIosDeploy;

      await const IOSDeploy().runApp(
        package: package,
        deviceId: 'test',
        bundlePath: 'test',
        launchArguments: <String>[],
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });
  });
}
