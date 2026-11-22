// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import '../src/test_build_system.dart';
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
          applicationPackageFactory: FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: FakePlistParser.new,
            templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
            toolContext: FakeToolContext(fs: fileSystem),
          ),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: AssetBundleFactory.defaultInstance(
            fileSystem: fileSystem,
            flutterRoot: getFlutterRoot(),
            logger: BufferLogger.test(),
            platform: FakePlatform(),
          ),
          buildTargets: const BuildTargetsImpl(),
          featureFlags: TestFeatureFlags(),
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          toolContext: FakeToolContext(fs: fileSystem),
          xcode: null,
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
          applicationPackageFactory: FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: FakePlistParser.new,
            templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
            toolContext: FakeToolContext(fs: fileSystem),
          ),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: AssetBundleFactory.defaultInstance(
            fileSystem: fileSystem,
            flutterRoot: getFlutterRoot(),
            logger: BufferLogger.test(),
            platform: FakePlatform(),
          ),
          buildTargets: const BuildTargetsImpl(),
          featureFlags: TestFeatureFlags(),
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          toolContext: FakeToolContext(fs: fileSystem),
          xcode: null,
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
          applicationPackageFactory: FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: FakePlistParser.new,
            templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
            toolContext: FakeToolContext(fs: fileSystem),
          ),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: AssetBundleFactory.defaultInstance(
            fileSystem: fileSystem,
            flutterRoot: getFlutterRoot(),
            logger: BufferLogger.test(),
            platform: FakePlatform(),
          ),
          buildTargets: const BuildTargetsImpl(),
          featureFlags: TestFeatureFlags(),
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          toolContext: FakeToolContext(fs: fileSystem),
          xcode: null,
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

    testWithoutContext('exit() on an attached device terminates the app', () async {
      final runner = HotRunner(
        <FlutterDevice>[flutterDevice],
        applicationPackageFactory: FlutterApplicationPackageFactory(
          androidSdkBuilder: () => null,
          plistParserBuilder: FakePlistParser.new,
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          toolContext: FakeToolContext(fs: fileSystem),
        ),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: AssetBundleFactory.defaultInstance(
          fileSystem: fileSystem,
          flutterRoot: getFlutterRoot(),
          logger: BufferLogger.test(),
          platform: FakePlatform(),
        ),
        buildTargets: const BuildTargetsImpl(),
        featureFlags: TestFeatureFlags(),
        target: 'main.dart',
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        toolContext: FakeToolContext(fs: fileSystem),
        xcode: null,
        analytics: _FakeAnalytics(),
      );

      await runner.attach();
      await runner.exit();
      expect(flutterDevice.wasExited, true);
    });
  });

  group('updateDevFS manifestPath', () {
    for (final (String description, String? projectRootPath, String expectedManifestPath)
        in <(String, String?, String)>[
          ('defaults to pubspec.yaml when projectRootPath matches cwd', null, 'pubspec.yaml'),
          (
            'resolves pubspec.yaml relative to custom projectRootPath',
            '/workspace/subproject',
            '/workspace/subproject/pubspec.yaml',
          ),
        ]) {
      testWithoutContext(description, () async {
        final fileSystem = MemoryFileSystem.test();
        final Directory rootDir = projectRootPath == null
            ? fileSystem.currentDirectory
            : (fileSystem.directory(projectRootPath)..createSync(recursive: true));
        rootDir.childFile('main.dart').createSync();

        final assetBundle = _RecordingAssetBundle();
        final flutterDevice = _FakeHotCompatibleFlutterDevice(FakeDevice());
        final runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          applicationPackageFactory: FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: FakePlistParser.new,
            templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
            toolContext: FakeToolContext(fs: fileSystem),
          ),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FixedAssetBundleFactory(assetBundle),
          buildTargets: const BuildTargetsImpl(),
          featureFlags: TestFeatureFlags(),
          projectFileInvalidator: _NoOpProjectFileInvalidator(
            fileSystem: fileSystem,
            logger: BufferLogger.test(),
            platform: FakePlatform(),
          ),
          projectRootPath: projectRootPath,
          target: rootDir.childFile('main.dart').path,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          toolContext: FakeToolContext(fs: fileSystem),
          xcode: null,
          analytics: _FakeAnalytics(),
        );

        final UpdateFSReport report = await runner.updateDevFS();

        expect(report.success, isTrue);
        expect(assetBundle.needsBuildManifestPaths, <String>[expectedManifestPath]);
        expect(assetBundle.buildManifestPaths, <String>[expectedManifestPath]);
      });
    }
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
          applicationPackageFactory: FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: FakePlistParser.new,
            templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
            toolContext: FakeToolContext(fs: fileSystem),
          ),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: AssetBundleFactory.defaultInstance(
            fileSystem: fileSystem,
            flutterRoot: getFlutterRoot(),
            logger: BufferLogger.test(),
            platform: FakePlatform(),
          ),
          buildTargets: const BuildTargetsImpl(),
          featureFlags: TestFeatureFlags(),
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          toolContext: FakeToolContext(fs: fileSystem),
          xcode: null,
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
  DateTime? lastCompiled;

  @override
  List<Uri> sources = <Uri>[];

  @override
  PackageConfig? lastPackageConfig;

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

  @override
  Future<List<Future<vm_service.ReloadReport>>?> reloadDeviceSources(
    String entryPath, {
    bool? pause = false,
  }) async {
    final deviceEntryUri = '${devFS!.baseUri!.resolve(entryPath)}';
    final vm_service.VM vm = await vmService!.service.getVM();
    return <Future<vm_service.ReloadReport>>[
      for (final vm_service.IsolateRef isolateRef in vm.isolates!)
        vmService!.service.reloadSources(isolateRef.id!, pause: pause, rootLibUri: deviceEntryUri),
    ];
  }
}

class _FakeHotCompatibleFlutterDevice extends Fake implements FlutterDevice {
  _FakeHotCompatibleFlutterDevice(this.device);

  @override
  final Device device;

  @override
  TargetPlatform get targetPlatform => TargetPlatform.tester;

  @override
  bool get defersServiceProtocolConnection => false;

  @override
  bool get alwaysReloadSources => false;

  @override
  String get hotRestartTimingVariableName => 'restart';

  @override
  DevFS? devFS = _FakeDevFS();

  @override
  ResidentCompiler? get generator => null;

  @override
  void onDetach() {}

  @override
  Future<bool?> performHotRestart() async => null;

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    return 0;
  }

  @override
  Future<UpdateFSReport> updateDevFS({
    required Uri mainUri,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    required String pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) async => UpdateFSReport(success: true);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> stopEchoingDeviceLog() async {}

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {
    wasExited = true;
  }

  bool wasExited = false;
}

class _FixedAssetBundleFactory implements AssetBundleFactory {
  const _FixedAssetBundleFactory(this._bundle);

  final AssetBundle _bundle;

  @override
  AssetBundle createBundle() => _bundle;
}

class _RecordingAssetBundle extends Fake implements AssetBundle {
  final needsBuildManifestPaths = <String>[];
  final buildManifestPaths = <String>[];

  @override
  bool wasBuiltOnce() => false;

  @override
  bool needsBuild({String manifestPath = defaultManifestPath}) {
    needsBuildManifestPaths.add(manifestPath);
    return true;
  }

  @override
  Future<int> build({
    FlutterHookResult? flutterHookResult,
    String manifestPath = defaultManifestPath,
    required String packageConfigPath,
    bool deferredComponentsEnabled = false,
    required TargetPlatform targetPlatform,
    String? flavor,
    bool includeAssetsFromDevDependencies = false,
  }) async {
    buildManifestPaths.add(manifestPath);
    return 0;
  }
}

class _NoOpProjectFileInvalidator extends ProjectFileInvalidator {
  _NoOpProjectFileInvalidator({
    required super.fileSystem,
    required super.logger,
    required super.platform,
  });

  @override
  Future<InvalidationResult> findInvalidated({
    required DateTime? lastCompiled,
    required List<Uri> urisToMonitor,
    required String packagesPath,
    required PackageConfig packageConfig,
    bool asyncScanning = false,
  }) async => const InvalidationResult(uris: <Uri>[], packageConfig: PackageConfig.empty);
}

class _FakeFlutterVmService extends Fake implements FlutterVmService {
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
