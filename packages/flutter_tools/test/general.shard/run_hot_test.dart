// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import 'hot_shared.dart';

void main() {
  testWithoutContext('defaultReloadSourcesHelper() handles empty DeviceReloadReports)', () {
    defaultReloadSourcesHelper(
      _FakeHotRunner(),
      <FlutterDevice?>[_FakeFlutterDevice()],
      false,
      const <String, dynamic>{},
      'android',
      'flutter-sdk',
      false,
      'test-reason',
      const NoOpAnalytics(),
    );
  });

  group('signal handling', () {
    late _FakeHotCompatibleFlutterDevice flutterDevice;
    late MemoryFileSystem fileSystem;

    setUp(() {
      flutterDevice = _FakeHotCompatibleFlutterDevice(FakeDevice());
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'kills the test device',
      () async {
        final runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.run();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, true);
        expect((flutterDevice.device.dds as FakeDartDevelopmentService).wasShutdown, true);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );

    testUsingContext(
      'kill with a detach keeps the test device running',
      () async {
        final runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.run();
        await runner.detach();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );

    testUsingContext(
      'kill on an attached device keeps the test device running',
      () async {
        final runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.attach();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );
  });

  group('multiple target devices', () {
    late List<_FakeHotCompatibleFlutterDevice> flutterDevices;
    late MemoryFileSystem fileSystem;

    setUp(() {
      flutterDevices = [
        _FakeHotCompatibleFlutterDevice(FakeDevice()),
        _FakeHotCompatibleFlutterDevice(FakeDevice()),
      ];
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'regression test for https://github.com/flutter/flutter/issues/179857',
      () async {
        final runner = HotRunner(
          flutterDevices,
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.run();
        await runner.cleanupAfterSignal();

        // Providing multiple Flutter devices should result in the target platform being set to
        // 'multiple', which we use to report analytics.
        expect(runner.targetPlatformName, 'multiple');
        for (final flutterDevice in flutterDevices) {
          expect(flutterDevice.wasExited, true);
          expect((flutterDevice.device.dds as FakeDartDevelopmentService).wasShutdown, true);
        }
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );
  });

  group('app flavor auto-detection', () {
    testUsingContext('detects and applies flavor when cli flavor is null', () async {
      final fakeCompiler = _FakeResidentCompiler();
      final fakeVmService = _FakeFlutterVmService(flavor: 'dev');
      final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: BuildInfo.debug,
        generator: fakeCompiler,
        vmService: fakeVmService,
      );
      final debuggingOptions = DebuggingOptions.enabled(BuildInfo.debug);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDevice],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeFlutterDevice.buildInfo.flavor, 'dev');
      expect(fakeFlutterDevice.buildInfo.dartDefines, contains('$kAppFlavor=dev'));
      expect(debuggingOptions.buildInfo.flavor, 'dev');
      expect(debuggingOptions.buildInfo.dartDefines, contains('$kAppFlavor=dev'));
      expect(fakeCompiler.dartDefines, contains('$kAppFlavor=dev'));
      expect(testLogger.statusText, contains('Automatically detected app flavor: "dev".'));
    });

    testUsingContext('preserves existing dartDefines when applying detected flavor', () async {
      final fakeCompiler = _FakeResidentCompiler(dartDefines: <String>['EXISTING_DEF=true']);
      final fakeVmService = _FakeFlutterVmService(flavor: 'dev');
      final BuildInfo initialBuildInfo = BuildInfo.debug.copyWith(
        dartDefines: <String>['EXISTING_DEF=true'],
      );
      final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: initialBuildInfo,
        generator: fakeCompiler,
        vmService: fakeVmService,
      );
      final debuggingOptions = DebuggingOptions.enabled(initialBuildInfo);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDevice],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeFlutterDevice.buildInfo.flavor, 'dev');
      expect(fakeFlutterDevice.buildInfo.dartDefines, contains('EXISTING_DEF=true'));
      expect(fakeFlutterDevice.buildInfo.dartDefines, contains('$kAppFlavor=dev'));
      expect(fakeCompiler.dartDefines, contains('EXISTING_DEF=true'));
      expect(fakeCompiler.dartDefines, contains('$kAppFlavor=dev'));
    });

    testUsingContext('works when compiler dartDefines was unmodifiable', () async {
      final fakeCompiler = _FakeResidentCompiler(dartDefines: const <String>[]);
      final fakeVmService = _FakeFlutterVmService(flavor: 'dev');
      final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: BuildInfo.debug,
        generator: fakeCompiler,
        vmService: fakeVmService,
      );
      final debuggingOptions = DebuggingOptions.enabled(BuildInfo.debug);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDevice],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeCompiler.dartDefines, contains('$kAppFlavor=dev'));
    });

    testUsingContext('handles null vmService or generator gracefully', () async {
      final fakeFlutterDeviceWithoutVmService = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: BuildInfo.debug,
      );
      final debuggingOptions = DebuggingOptions.enabled(BuildInfo.debug);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDeviceWithoutVmService],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeFlutterDeviceWithoutVmService.buildInfo.flavor, isNull);
    });

    testUsingContext('warns when cli flavor does not match detected flavor', () async {
      final fakeCompiler = _FakeResidentCompiler();
      final fakeVmService = _FakeFlutterVmService(flavor: 'dev');
      final BuildInfo cliBuildInfo = BuildInfo.debug.copyWith(
        flavor: 'prod',
        dartDefines: <String>['$kAppFlavor=prod'],
      );
      final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: cliBuildInfo,
        generator: fakeCompiler,
        vmService: fakeVmService,
      );
      final debuggingOptions = DebuggingOptions.enabled(cliBuildInfo);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDevice],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeFlutterDevice.buildInfo.flavor, 'prod');
      expect(
        testLogger.warningText,
        contains(
          'Warning: The app on the device was built with flavor "dev", but --flavor was set to "prod".',
        ),
      );
    });

    testUsingContext('does not warn or modify when cli flavor matches detected flavor', () async {
      final fakeCompiler = _FakeResidentCompiler();
      final fakeVmService = _FakeFlutterVmService(flavor: 'prod');
      final BuildInfo cliBuildInfo = BuildInfo.debug.copyWith(
        flavor: 'prod',
        dartDefines: <String>['$kAppFlavor=prod'],
      );
      final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
        FakeDevice(),
        buildInfo: cliBuildInfo,
        generator: fakeCompiler,
        vmService: fakeVmService,
      );
      final debuggingOptions = DebuggingOptions.enabled(cliBuildInfo);
      final runner = HotRunner(
        <FlutterDevice>[fakeFlutterDevice],
        target: 'main.dart',
        debuggingOptions: debuggingOptions,
        analytics: _FakeAnalytics(),
      );

      await runner.detectAndApplyAppFlavor();

      expect(fakeFlutterDevice.buildInfo.flavor, 'prod');
      expect(testLogger.warningText, isEmpty);
      expect(testLogger.statusText, isNot(contains('Automatically detected app flavor')));
    });

    testUsingContext(
      'does not warn or modify when both cli flavor and detected flavor are null',
      () async {
        final fakeCompiler = _FakeResidentCompiler();
        final fakeVmService = _FakeFlutterVmService();
        final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
          FakeDevice(),
          buildInfo: BuildInfo.debug,
          generator: fakeCompiler,
          vmService: fakeVmService,
        );
        final debuggingOptions = DebuggingOptions.enabled(BuildInfo.debug);
        final runner = HotRunner(
          <FlutterDevice>[fakeFlutterDevice],
          target: 'main.dart',
          debuggingOptions: debuggingOptions,
          analytics: _FakeAnalytics(),
        );

        await runner.detectAndApplyAppFlavor();

        expect(fakeFlutterDevice.buildInfo.flavor, isNull);
        expect(testLogger.warningText, isEmpty);
        expect(testLogger.statusText, isNot(contains('Automatically detected app flavor')));
      },
    );

    testUsingContext(
      'does not modify when cli flavor is set but detected flavor is null',
      () async {
        final fakeCompiler = _FakeResidentCompiler();
        final fakeVmService = _FakeFlutterVmService();
        final BuildInfo cliBuildInfo = BuildInfo.debug.copyWith(
          flavor: 'prod',
          dartDefines: <String>['$kAppFlavor=prod'],
        );
        final fakeFlutterDevice = _FakeHotCompatibleFlutterDevice(
          FakeDevice(),
          buildInfo: cliBuildInfo,
          generator: fakeCompiler,
          vmService: fakeVmService,
        );
        final debuggingOptions = DebuggingOptions.enabled(cliBuildInfo);
        final runner = HotRunner(
          <FlutterDevice>[fakeFlutterDevice],
          target: 'main.dart',
          debuggingOptions: debuggingOptions,
          analytics: _FakeAnalytics(),
        );

        await runner.detectAndApplyAppFlavor();

        expect(fakeFlutterDevice.buildInfo.flavor, 'prod');
        expect(testLogger.warningText, isEmpty);
        expect(testLogger.statusText, isNot(contains('Automatically detected app flavor')));
      },
    );
  });
}

class _FakeAnalytics extends Fake implements Analytics {
  @override
  void send(Event event) {}
}

class _FakeHotRunner extends Fake implements HotRunner {}

class _FakeDevFS extends Fake implements DevFS {
  @override
  final Uri? baseUri = Uri();

  @override
  Future<void> destroy() async {}

  @override
  void resetLastCompiled() {}
}

class _FakeFlutterDevice extends Fake implements FlutterDevice {
  @override
  final DevFS? devFS = _FakeDevFS();

  @override
  final FlutterVmService? vmService = _FakeFlutterVmService();
}

class _FakeResidentCompiler extends Fake implements ResidentCompiler {
  _FakeResidentCompiler({List<String>? dartDefines}) : dartDefines = dartDefines ?? <String>[];

  @override
  List<String> dartDefines;
}

class _FakeHotCompatibleFlutterDevice extends Fake implements FlutterDevice {
  _FakeHotCompatibleFlutterDevice(
    this.device, {
    BuildInfo? buildInfo,
    this.generator,
    this.vmService,
  }) : buildInfo = buildInfo ?? BuildInfo.debug;

  @override
  final Device device;

  @override
  BuildInfo buildInfo;

  @override
  DevFS? devFS = _FakeDevFS();

  @override
  final ResidentCompiler? generator;

  @override
  final FlutterVmService? vmService;

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    return 0;
  }

  @override
  Future<void> stopEchoingDeviceLog() async {}

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {
    wasExited = true;
  }

  bool wasExited = false;
}

class _FakeFlutterVmService extends Fake implements FlutterVmService {
  _FakeFlutterVmService({this.flavor});

  final String? flavor;

  @override
  Future<String?> getAppFlavor() async => flavor;

  @override
  final vm_service.VmService service = _FakeVmService();
}

class _FakeVmService extends Fake implements vm_service.VmService {
  @override
  Future<_FakeVm> getVM() async => _FakeVm();
}

class _FakeVm extends Fake implements vm_service.VM {
  final _isolates = <vm_service.IsolateRef>[];

  @override
  List<vm_service.IsolateRef>? get isolates => _isolates;
}
