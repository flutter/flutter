// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/fuchsia/application_package.dart';
import 'package:flutter_tools/src/fuchsia/amber_ctl.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_dev_finder.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/tiles_ctl.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('fuchsia device', () {
    MemoryFileSystem memoryFileSystem;
    MockFile sshConfig;
    MockProcessUtils mockProcessUtils;
    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      sshConfig = MockFile();
      mockProcessUtils = MockProcessUtils();
      when(sshConfig.absolute).thenReturn(sshConfig);
    });

    testUsingContext('stores the requested id and name', () {
      const String deviceId = 'e80::0000:a00a:f00f:2002/3';
      const String name = 'halfbaked';
      final FuchsiaDevice device = FuchsiaDevice(deviceId, name: name);
      expect(device.id, deviceId);
      expect(device.name, name);
    });

    test('parse dev_finder output', () {
      const String example = '192.168.42.56 paper-pulp-bush-angel';
      final List<FuchsiaDevice> names = parseListDevices(example);

      expect(names.length, 1);
      expect(names.first.name, 'paper-pulp-bush-angel');
      expect(names.first.id, '192.168.42.56');
    });

    test('parse junk dev_finder output', () {
      const String example = 'junk';
      final List<FuchsiaDevice> names = parseListDevices(example);

      expect(names.length, 0);
    });

    testUsingContext('default capabilities', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      fs.directory('fuchsia').createSync(recursive: true);
      fs.file('pubspec.yaml').createSync();

      expect(device.supportsHotReload, true);
      expect(device.supportsHotRestart, false);
      expect(device.supportsFlutterExit, false);
      expect(device.isSupportedForProject(FlutterProject.current()), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('supported for project', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      fs.directory('fuchsia').createSync(recursive: true);
      fs.file('pubspec.yaml').createSync();
      expect(device.isSupportedForProject(FlutterProject.current()), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('not supported for project', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      fs.file('pubspec.yaml').createSync();
      expect(device.isSupportedForProject(FlutterProject.current()), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('targetPlatform arm64 works', () async {
      when(mockProcessUtils.run(any)).thenAnswer((Invocation _) {
        return Future<RunResult>.value(RunResult(ProcessResult(1, 0, 'aarch64', ''), <String>['']));
      });
      final FuchsiaDevice device = FuchsiaDevice('123');
      expect(await device.targetPlatform, TargetPlatform.fuchsia_arm64);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => MockFuchsiaSdk(),
      ProcessUtils: () => mockProcessUtils,
    });

    testUsingContext('targetPlatform x64 works', () async {
      when(mockProcessUtils.run(any)).thenAnswer((Invocation _) {
        return Future<RunResult>.value(RunResult(ProcessResult(1, 0, 'x86_64', ''), <String>['']));
      });
      final FuchsiaDevice device = FuchsiaDevice('123');
      expect(await device.targetPlatform, TargetPlatform.fuchsia_x64);
    }, overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => MockFuchsiaSdk(),
      ProcessUtils: () => mockProcessUtils,
    });
  });

  group('displays friendly error when', () {
    MockProcessManager mockProcessManager;
    MockProcessResult mockProcessResult;
    MockFile mockFile;
    MockProcessManager emptyStdoutProcessManager;
    MockProcessResult emptyStdoutProcessResult;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockProcessResult = MockProcessResult();
      mockFile = MockFile();
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) =>
          Future<ProcessResult>.value(mockProcessResult));
      when(mockProcessResult.exitCode).thenReturn(1);
      when<String>(mockProcessResult.stdout).thenReturn('');
      when<String>(mockProcessResult.stderr).thenReturn('');
      when(mockFile.absolute).thenReturn(mockFile);
      when(mockFile.path).thenReturn('');

      emptyStdoutProcessManager = MockProcessManager();
      emptyStdoutProcessResult = MockProcessResult();
      when(emptyStdoutProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) =>
          Future<ProcessResult>.value(emptyStdoutProcessResult));
      when(emptyStdoutProcessResult.exitCode).thenReturn(0);
      when<String>(emptyStdoutProcessResult.stdout).thenReturn('');
      when<String>(emptyStdoutProcessResult.stderr).thenReturn('');
    });

    testUsingContext('No vmservices found', () async {
      final FuchsiaDevice device = FuchsiaDevice('id');
      ToolExit toolExit;
      try {
        await device.servicePorts();
      } on ToolExit catch (err) {
        toolExit = err;
      }
      expect(
          toolExit.message,
          contains(
              'No Dart Observatories found. Are you running a debug build?'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => emptyStdoutProcessManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(
            sshConfig: mockFile,
            devFinder: mockFile,
          ),
      FuchsiaSdk: () => MockFuchsiaSdk(),
    });

    group('device logs', () {
      const String exampleUtcLogs = '''
[2018-11-09 01:27:45][3][297950920][log] INFO: example_app.cmx(flutter): Error doing thing
[2018-11-09 01:27:58][46257][46269][foo] INFO: Using a thing
[2018-11-09 01:29:58][46257][46269][foo] INFO: Blah blah blah
[2018-11-09 01:29:58][46257][46269][foo] INFO: other_app.cmx(flutter): Do thing
[2018-11-09 01:30:02][41175][41187][bar] INFO: Invoking a bar
[2018-11-09 01:30:12][52580][52983][log] INFO: example_app.cmx(flutter): Did thing this time

  ''';
      MockProcessManager mockProcessManager;
      MockProcess mockProcess;
      Completer<int> exitCode;
      StreamController<List<int>> stdout;
      StreamController<List<int>> stderr;
      MockFile devFinder;
      MockFile sshConfig;

      setUp(() {
        mockProcessManager = MockProcessManager();
        mockProcess = MockProcess();
        stdout = StreamController<List<int>>(sync: true);
        stderr = StreamController<List<int>>(sync: true);
        exitCode = Completer<int>();
        when(mockProcessManager.start(any))
            .thenAnswer((Invocation _) => Future<Process>.value(mockProcess));
        when(mockProcess.exitCode).thenAnswer((Invocation _) => exitCode.future);
        when(mockProcess.stdout).thenAnswer((Invocation _) => stdout.stream);
        when(mockProcess.stderr).thenAnswer((Invocation _) => stderr.stream);
        devFinder = MockFile();
        sshConfig = MockFile();
        when(devFinder.existsSync()).thenReturn(true);
        when(sshConfig.existsSync()).thenReturn(true);
        when(devFinder.absolute).thenReturn(devFinder);
        when(sshConfig.absolute).thenReturn(sshConfig);
      });

      tearDown(() {
        exitCode.complete(0);
      });

      testUsingContext('can be parsed for an app', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(
            app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 2) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
        FuchsiaArtifacts: () =>
            FuchsiaArtifacts(devFinder: devFinder, sshConfig: sshConfig),
      });

      testUsingContext('cuts off prior logs', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader(
            app: FuchsiaModulePackage(name: 'example_app'));
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          lock.complete();
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 29, 45)),
        FuchsiaArtifacts: () =>
            FuchsiaArtifacts(devFinder: devFinder, sshConfig: sshConfig),
      });

      testUsingContext('can be parsed for all apps', () async {
        final FuchsiaDevice device = FuchsiaDevice('id', name: 'tester');
        final DeviceLogReader reader = device.getLogReader();
        final List<String> logLines = <String>[];
        final Completer<void> lock = Completer<void>();
        reader.logLines.listen((String line) {
          logLines.add(line);
          if (logLines.length == 3) {
            lock.complete();
          }
        });
        expect(logLines, isEmpty);

        stdout.add(utf8.encode(exampleUtcLogs));
        await stdout.close();
        await lock.future.timeout(const Duration(seconds: 1));

        expect(logLines, <String>[
          '[2018-11-09 01:27:45.000] Flutter: Error doing thing',
          '[2018-11-09 01:29:58.000] Flutter: Do thing',
          '[2018-11-09 01:30:12.000] Flutter: Did thing this time',
        ]);
      }, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        SystemClock: () => SystemClock.fixed(DateTime(2018, 11, 9, 1, 25, 45)),
        FuchsiaArtifacts: () =>
            FuchsiaArtifacts(devFinder: devFinder, sshConfig: sshConfig),
      });
    });
  });

  group(FuchsiaIsolateDiscoveryProtocol, () {
    MockPortForwarder portForwarder;
    MockVMService vmService;
    MockVM vm;

    setUp(() {
      portForwarder = MockPortForwarder();
      vmService = MockVMService();
      vm = MockVM();

      when(vm.vmService).thenReturn(vmService);
      when(vmService.vm).thenReturn(vm);
    });

    Future<Uri> findUri(List<MockFlutterView> views, String expectedIsolateName) {
      when(vm.views).thenReturn(views);
      for (MockFlutterView view in views) {
        when(view.owner).thenReturn(vm);
      }
      final MockFuchsiaDevice fuchsiaDevice =
          MockFuchsiaDevice('123', portForwarder, false);
      final FuchsiaIsolateDiscoveryProtocol discoveryProtocol =
          FuchsiaIsolateDiscoveryProtocol(
        fuchsiaDevice,
        expectedIsolateName,
        (Uri uri) async => vmService,
        true, // only poll once.
      );
      when(fuchsiaDevice.servicePorts())
          .thenAnswer((Invocation invocation) async => <int>[1]);
      when(portForwarder.forward(1))
          .thenAnswer((Invocation invocation) async => 2);
      when(vmService.getVM())
          .thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(vmService.refreshViews())
          .thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(vmService.httpAddress).thenReturn(Uri.parse('example'));
      return discoveryProtocol.uri;
    }

    testUsingContext('can find flutter view with matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Uri uri = await findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
        MockFlutterView(MockIsolate('wrong name')), // wrong name.
        MockFlutterView(MockIsolate(expectedIsolateName)), // matching name.
      ], expectedIsolateName);
      expect(
          uri.toString(), 'http://${InternetAddress.loopbackIPv4.address}:0/');
    });

    testUsingContext('can handle flutter view without matching isolate name', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
        MockFlutterView(MockIsolate('wrong name')), // wrong name.
      ], expectedIsolateName);
      expect(uri, throwsException);
    });

    testUsingContext('can handle non flutter view', () async {
      const String expectedIsolateName = 'foobar';
      final Future<Uri> uri = findUri(<MockFlutterView>[
        MockFlutterView(null), // no ui isolate.
      ], expectedIsolateName);
      expect(uri, throwsException);
    });
  });

  testUsingContext('Correct flutter runner', () async {
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.debug,
      ),
      contains('flutter_jit_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.profile,
      ),
      contains('flutter_aot_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.release,
      ),
      contains('flutter_aot_product_runner'),
    );
    expect(artifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: TargetPlatform.fuchsia_x64,
        mode: BuildMode.jitRelease,
      ),
      contains('flutter_jit_product_runner'),
    );
  });

  group('Fuchsia app start and stop: ', () {
    MemoryFileSystem memoryFileSystem;
    FakeOperatingSystemUtils osUtils;
    FakeFuchsiaDeviceTools fuchsiaDeviceTools;
    MockFuchsiaSdk fuchsiaSdk;
    MockFuchsiaArtifacts fuchsiaArtifacts;
    MockArtifacts mockArtifacts;

    File compilerSnapshot;
    File platformDill;
    File patchedSdk;
    File runner;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      osUtils = FakeOperatingSystemUtils();
      fuchsiaDeviceTools = FakeFuchsiaDeviceTools();
      fuchsiaSdk = MockFuchsiaSdk();
      fuchsiaArtifacts = MockFuchsiaArtifacts();

      compilerSnapshot = memoryFileSystem.file('kernel_compiler.snapshot')..createSync();
      platformDill = memoryFileSystem.file('platform_strong.dill')..createSync();
      patchedSdk = memoryFileSystem.file('flutter_runner_patched_sdk')..createSync();
      runner = memoryFileSystem.file('flutter_jit_runner')..createSync();

      mockArtifacts = MockArtifacts();
      when(mockArtifacts.getArtifactPath(
        Artifact.fuchsiaKernelCompiler,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
      )).thenReturn(compilerSnapshot.path);
      when(mockArtifacts.getArtifactPath(
        Artifact.platformKernelDill,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
      )).thenReturn(platformDill.path);
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterPatchedSdkPath,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
      )).thenReturn(patchedSdk.path);
      when(mockArtifacts.getArtifactPath(
        Artifact.fuchsiaFlutterRunner,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
      )).thenReturn(runner.path);
    });

    Future<LaunchResult> setupAndStartApp({
      @required bool prebuilt,
      @required BuildMode mode,
    }) async {
      const String appName = 'app_name';
      final FuchsiaDevice device = FuchsiaDeviceWithFakeDiscovery('123');
      fs.directory('fuchsia').createSync(recursive: true);
      final File pubspecFile = fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');

      FuchsiaApp app;
      if (prebuilt) {
        final File far = fs.file('app_name-0.far')..createSync();
        app = FuchsiaApp.fromPrebuiltApp(far);
      } else {
        fs.file(fs.path.join('fuchsia', 'meta', '$appName.cmx'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
        fs.file('.packages').createSync();
        fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
        app = BuildableFuchsiaApp(project: FlutterProject.current().fuchsia);
      }

      final DebuggingOptions debuggingOptions = DebuggingOptions.disabled(BuildInfo(mode, null));
      return await device.startApp(
        app,
        prebuiltApplication: prebuilt,
        debuggingOptions: debuggingOptions,
      );
    }

    testUsingContext('start prebuilt in release mode', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start and stop prebuilt in release mode', () async {
      const String appName = 'app_name';
      final FuchsiaDevice device = FuchsiaDeviceWithFakeDiscovery('123');
      fs.directory('fuchsia').createSync(recursive: true);
      final File pubspecFile = fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');
      final File far = fs.file('app_name-0.far')..createSync();

      final FuchsiaApp app = FuchsiaApp.fromPrebuiltApp(far);
      final DebuggingOptions debuggingOptions =
          DebuggingOptions.disabled(const BuildInfo(BuildMode.release, null));
      final LaunchResult launchResult = await device.startApp(app,
          prebuiltApplication: true,
          debuggingOptions: debuggingOptions);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasObservatory, isFalse);
      expect(await device.stopApp(app), isTrue);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start prebuilt in debug mode', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.debug);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasObservatory, isTrue);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start buildable in release mode', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: false, mode: BuildMode.release);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start buildable in debug mode', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: false, mode: BuildMode.debug);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasObservatory, isTrue);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail with correct LaunchResult when dev_finder fails', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => MockFuchsiaSdk(devFinder: FailingDevFinder()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail with correct LaunchResult when pm fails', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => MockFuchsiaSdk(pm: FailingPM()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail with correct LaunchResult when amber fails', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => FakeFuchsiaDeviceTools(amber: FailingAmberCtl()),
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail with correct LaunchResult when tiles fails', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasObservatory, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaDeviceTools: () => FakeFuchsiaDeviceTools(tiles: FailingTilesCtl()),
      FuchsiaArtifacts: () => fuchsiaArtifacts,
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

  });

  group('sdkNameAndVersion: ', () {
    MockFile sshConfig;
    MockProcessManager mockSuccessProcessManager;
    MockProcessResult mockSuccessProcessResult;
    MockProcessManager mockFailureProcessManager;
    MockProcessResult mockFailureProcessResult;
    MockProcessManager emptyStdoutProcessManager;
    MockProcessResult emptyStdoutProcessResult;

    setUp(() {
      sshConfig = MockFile();
      when(sshConfig.absolute).thenReturn(sshConfig);

      mockSuccessProcessManager = MockProcessManager();
      mockSuccessProcessResult = MockProcessResult();
      when(mockSuccessProcessManager.run(any)).thenAnswer(
          (Invocation invocation) => Future<ProcessResult>.value(mockSuccessProcessResult));
      when(mockSuccessProcessResult.exitCode).thenReturn(0);
      when<String>(mockSuccessProcessResult.stdout).thenReturn('version');
      when<String>(mockSuccessProcessResult.stderr).thenReturn('');

      mockFailureProcessManager = MockProcessManager();
      mockFailureProcessResult = MockProcessResult();
      when(mockFailureProcessManager.run(any)).thenAnswer(
          (Invocation invocation) => Future<ProcessResult>.value(mockFailureProcessResult));
      when(mockFailureProcessResult.exitCode).thenReturn(1);
      when<String>(mockFailureProcessResult.stdout).thenReturn('');
      when<String>(mockFailureProcessResult.stderr).thenReturn('');

      emptyStdoutProcessManager = MockProcessManager();
      emptyStdoutProcessResult = MockProcessResult();
      when(emptyStdoutProcessManager.run(any)).thenAnswer((Invocation invocation) =>
          Future<ProcessResult>.value(emptyStdoutProcessResult));
      when(emptyStdoutProcessResult.exitCode).thenReturn(0);
      when<String>(emptyStdoutProcessResult.stdout).thenReturn('');
      when<String>(emptyStdoutProcessResult.stderr).thenReturn('');
    });

    testUsingContext('returns what we get from the device on success', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      expect(await device.sdkNameAndVersion, equals('Fuchsia version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockSuccessProcessManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => MockFuchsiaSdk(),
    });

    testUsingContext('returns "Fuchsia" when device command fails', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      expect(await device.sdkNameAndVersion, equals('Fuchsia'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockFailureProcessManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => MockFuchsiaSdk(),
    });

    testUsingContext('returns "Fuchsia" when device gives an empty result', () async {
      final FuchsiaDevice device = FuchsiaDevice('123');
      expect(await device.sdkNameAndVersion, equals('Fuchsia'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => emptyStdoutProcessManager,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => MockFuchsiaSdk(),
    });
  });
}

class FuchsiaModulePackage extends ApplicationPackage {
  FuchsiaModulePackage({@required this.name}) : super(id: name);

  @override
  final String name;
}

class MockArtifacts extends Mock implements Artifacts {}

class MockFuchsiaArtifacts extends Mock implements FuchsiaArtifacts {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}

class MockProcessUtils extends Mock implements ProcessUtils {}

class MockFile extends Mock implements File {}

class MockProcess extends Mock implements Process {}

Process _createMockProcess({
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
  bool persistent = false,
}) {
  final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stdout),
  ]);
  final Stream<List<int>> stderrStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stderr),
  ]);
  final Process process = MockProcess();

  when(process.stdout).thenAnswer((_) => stdoutStream);
  when(process.stderr).thenAnswer((_) => stderrStream);

  if (persistent) {
    final Completer<int> exitCodeCompleter = Completer<int>();
    when(process.kill()).thenAnswer((_) {
      exitCodeCompleter.complete(-11);
      return true;
    });
    when(process.exitCode).thenAnswer((_) => exitCodeCompleter.future);
  } else {
    when(process.exitCode).thenAnswer((_) => Future<int>.value(exitCode));
  }
  return process;
}

class MockFuchsiaDevice extends Mock implements FuchsiaDevice {
  MockFuchsiaDevice(this.id, this.portForwarder, this._ipv6);

  final bool _ipv6;

  @override
  Future<bool> get ipv6 async => _ipv6;

  @override
  final String id;

  @override
  final DevicePortForwarder portForwarder;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia_arm64;
}

class MockPortForwarder extends Mock implements DevicePortForwarder {}

class MockVMService extends Mock implements VMService {}

class MockVM extends Mock implements VM {}

class MockFlutterView extends Mock implements FlutterView {
  MockFlutterView(this.uiIsolate);

  @override
  final Isolate uiIsolate;
}

class MockIsolate extends Mock implements Isolate {
  MockIsolate(this.name);

  @override
  final String name;
}

class FuchsiaDeviceWithFakeDiscovery extends FuchsiaDevice {
  FuchsiaDeviceWithFakeDiscovery(String id, {String name}) : super(id, name: name);

  @override
  FuchsiaIsolateDiscoveryProtocol getIsolateDiscoveryProtocol(String isolateName) {
    return FakeFuchsiaIsolateDiscoveryProtocol();
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.fuchsia_arm64;
}

class FakeFuchsiaIsolateDiscoveryProtocol implements FuchsiaIsolateDiscoveryProtocol {
  @override
  FutureOr<Uri> get uri => Uri.parse('http://[::1]:37');

  @override
  void dispose() {}
}

class FakeFuchsiaAmberCtl implements FuchsiaAmberCtl {
  @override
  Future<bool> addSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }

  @override
  Future<bool> rmSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }

  @override
  Future<bool> getUp(FuchsiaDevice device, String packageName) async {
    return true;
  }

  @override
  Future<bool> addRepoCfg(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }

  @override
  Future<bool> pkgCtlResolve(FuchsiaDevice device, FuchsiaPackageServer server, String packageName) async {
    return true;
  }

  @override
  Future<bool> pkgCtlRepoRemove(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }
}

class FailingAmberCtl implements FuchsiaAmberCtl {
  @override
  Future<bool> addSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }

  @override
  Future<bool> rmSrc(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }

  @override
  Future<bool> getUp(FuchsiaDevice device, String packageName) async {
    return false;
  }

  @override
  Future<bool> addRepoCfg(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }

  @override
  Future<bool> pkgCtlResolve(FuchsiaDevice device, FuchsiaPackageServer server, String packageName) async {
    return false;
  }

  @override
  Future<bool> pkgCtlRepoRemove(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }
}

class FakeFuchsiaTilesCtl implements FuchsiaTilesCtl {
  final Map<int, String> _runningApps = <int, String>{};
  bool _started = false;
  int _nextAppId = 1;

  @override
  Future<bool> start(FuchsiaDevice device) async {
    _started = true;
    return true;
  }

  @override
  Future<Map<int, String>> list(FuchsiaDevice device) async {
    if (!_started) {
      return null;
    }
    return _runningApps;
  }

  @override
  Future<bool> add(FuchsiaDevice device, String url, List<String> args) async {
    if (!_started) {
      return false;
    }
    _runningApps[_nextAppId] = url;
    _nextAppId++;
    return true;
  }

  @override
  Future<bool> remove(FuchsiaDevice device, int key) async {
    if (!_started) {
      return false;
    }
    _runningApps.remove(key);
    return true;
  }

  @override
  Future<bool> quit(FuchsiaDevice device) async {
    if (!_started) {
      return false;
    }
    _started = false;
    return true;
  }
}

class FailingTilesCtl implements FuchsiaTilesCtl {
  @override
  Future<bool> start(FuchsiaDevice device) async {
    return false;
  }

  @override
  Future<Map<int, String>> list(FuchsiaDevice device) async {
    return null;
  }

  @override
  Future<bool> add(FuchsiaDevice device, String url, List<String> args) async {
    return false;
  }

  @override
  Future<bool> remove(FuchsiaDevice device, int key) async {
    return false;
  }

  @override
  Future<bool> quit(FuchsiaDevice device) async {
    return false;
  }
}

class FakeFuchsiaDeviceTools implements FuchsiaDeviceTools {
  FakeFuchsiaDeviceTools({
    FuchsiaAmberCtl amber,
    FuchsiaTilesCtl tiles,
  }) : amberCtl = amber ?? FakeFuchsiaAmberCtl(),
       tilesCtl = tiles ?? FakeFuchsiaTilesCtl();

  @override
  final FuchsiaAmberCtl amberCtl;

  @override
  final FuchsiaTilesCtl tilesCtl;
}

class FakeFuchsiaPM implements FuchsiaPM {
  String _appName;

  @override
  Future<bool> init(String buildPath, String appName) async {
    if (!fs.directory(buildPath).existsSync()) {
      return false;
    }
    fs
        .file(fs.path.join(buildPath, 'meta', 'package'))
        .createSync(recursive: true);
    _appName = appName;
    return true;
  }

  @override
  Future<bool> genkey(String buildPath, String outKeyPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync()) {
      return false;
    }
    fs.file(outKeyPath).createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> build(String buildPath, String keyPath, String manifestPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fs.file(keyPath).existsSync() ||
        !fs.file(manifestPath).existsSync()) {
      return false;
    }
    fs.file(fs.path.join(buildPath, 'meta.far')).createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> archive(String buildPath, String keyPath, String manifestPath) async {
    if (!fs.file(fs.path.join(buildPath, 'meta', 'package')).existsSync() ||
        !fs.file(keyPath).existsSync() ||
        !fs.file(manifestPath).existsSync()) {
      return false;
    }
    if (_appName == null) {
      return false;
    }
    fs
        .file(fs.path.join(buildPath, '$_appName-0.far'))
        .createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> newrepo(String repoPath) async {
    if (!fs.directory(repoPath).existsSync()) {
      return false;
    }
    return true;
  }

  @override
  Future<Process> serve(String repoPath, String host, int port) async {
    return _createMockProcess(persistent: true);
  }

  @override
  Future<bool> publish(String repoPath, String packagePath) async {
    if (!fs.directory(repoPath).existsSync()) {
      return false;
    }
    if (!fs.file(packagePath).existsSync()) {
      return false;
    }
    return true;
  }
}

class FailingPM implements FuchsiaPM {
  @override
  Future<bool> init(String buildPath, String appName) async {
    return false;
  }

  @override
  Future<bool> genkey(String buildPath, String outKeyPath) async {
    return false;
  }

  @override
  Future<bool> build(String buildPath, String keyPath, String manifestPath) async {
    return false;
  }

  @override
  Future<bool> archive(String buildPath, String keyPath, String manifestPath) async {
    return false;
  }

  @override
  Future<bool> newrepo(String repoPath) async {
    return false;
  }

  @override
  Future<Process> serve(String repoPath, String host, int port) async {
    return _createMockProcess(exitCode: 6);
  }

  @override
  Future<bool> publish(String repoPath, String packagePath) async {
    return false;
  }
}

class FakeFuchsiaKernelCompiler implements FuchsiaKernelCompiler {
  @override
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String manifestPath = fs.path.join(outDir, '$appName.dilpmanifest');
    fs.file(manifestPath).createSync(recursive: true);
  }
}

class FailingKernelCompiler implements FuchsiaKernelCompiler {
  @override
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    throwToolExit('Build process failed');
  }
}

class FakeFuchsiaDevFinder implements FuchsiaDevFinder {
  @override
  Future<List<String>> list() async {
    return <String>['192.168.42.172 scare-cable-skip-joy'];
  }

  @override
  Future<String> resolve(String deviceName, {bool local = false}) async {
    return '192.168.42.10';
  }
}

class FailingDevFinder implements FuchsiaDevFinder {
  @override
  Future<List<String>> list() async {
    return null;
  }

  @override
  Future<String> resolve(String deviceName, {bool local = false}) async {
    return null;
  }
}

class MockFuchsiaSdk extends Mock implements FuchsiaSdk {
  MockFuchsiaSdk({
    FuchsiaPM pm,
    FuchsiaKernelCompiler compiler,
    FuchsiaDevFinder devFinder,
  }) : fuchsiaPM = pm ?? FakeFuchsiaPM(),
       fuchsiaKernelCompiler = compiler ?? FakeFuchsiaKernelCompiler(),
       fuchsiaDevFinder = devFinder ?? FakeFuchsiaDevFinder();

  @override
  final FuchsiaPM fuchsiaPM;

  @override
  final FuchsiaKernelCompiler fuchsiaKernelCompiler;

  @override
  final FuchsiaDevFinder fuchsiaDevFinder;
}
