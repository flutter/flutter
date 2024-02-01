// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide BuildMode, Target;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    as native_assets_cli;
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import 'fake_native_assets_build_runner.dart';

void main() {
  group('native assets', () {
    late TestHotRunnerConfig testingConfig;
    late FileSystem fileSystem;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      testingConfig = TestHotRunnerConfig(
        successfulHotRestartSetup: true,
      );
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });
    testUsingContext('native assets restart', () async {
      final FakeDevice device = FakeDevice();
      final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
      final List<FlutterDevice> devices = <FlutterDevice>[
        fakeFlutterDevice,
      ];

      fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
        success: true,
        invalidatedSourcesCount: 6,
        syncedBytes: 8,
        scannedSourcesCount: 16,
        compileDuration: const Duration(seconds: 16),
        transferDuration: const Duration(seconds: 32),
      );

      (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

      final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', fileSystem.currentDirectory.uri),
        ],
        dryRunResult: FakeNativeAssetsBuilderResult(
          assets: <Asset>[
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSArm64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        buildRunner: buildRunner,
        analytics: fakeAnalytics,
      );
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      expect(result.isOk, true);
      // Hot restart does not require rerunning anything for native assets.
      // The previous native assets mapping should be used.
      expect(buildRunner.buildInvocations, 0);
      expect(buildRunner.dryRunInvocations, 0);
      expect(buildRunner.hasPackageConfigInvocations, 0);
      expect(buildRunner.packagesWithNativeAssetsInvocations, 0);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => testingConfig,
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.empty(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    });

    testUsingContext('native assets run unsupported', () async {
      final FakeDevice device = FakeDevice(targetPlatform: TargetPlatform.fuchsia_arm64);
      final FakeFlutterDevice fakeFlutterDevice = FakeFlutterDevice(device);
      final List<FlutterDevice> devices = <FlutterDevice>[
        fakeFlutterDevice,
      ];

      fakeFlutterDevice.updateDevFSReportCallback = () async => UpdateFSReport(
        success: true,
        invalidatedSourcesCount: 6,
        syncedBytes: 8,
        scannedSourcesCount: 16,
        compileDuration: const Duration(seconds: 16),
        transferDuration: const Duration(seconds: 32),
      );

      (fakeFlutterDevice.devFS! as FakeDevFs).baseUri = Uri.parse('file:///base_uri');

      final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner(
        packagesWithNativeAssetsResult: <Package>[
          Package('bar', fileSystem.currentDirectory.uri),
        ],
        dryRunResult: FakeNativeAssetsBuilderResult(
          assets: <Asset>[
            Asset(
              id: 'package:bar/bar.dart',
              linkMode: LinkMode.dynamic,
              target: native_assets_cli.Target.macOSArm64,
              path: AssetAbsolutePath(Uri.file('bar.dylib')),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        buildRunner: buildRunner,
        analytics: fakeAnalytics,
      );
      expect(
        () => hotRunner.run(),
        throwsToolExit( message:
          'Package(s) bar require the native assets feature. '
          'This feature has not yet been implemented for `TargetPlatform.fuchsia_arm64`. '
          'For more info see https://github.com/flutter/flutter/issues/129757.',
        )
      );

    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => testingConfig,
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.empty(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    });
  });
}

class FakeDevFs extends Fake implements DevFS {
  @override
  Future<void> destroy() async { }

  @override
  List<Uri> sources = <Uri>[];

  @override
  DateTime? lastCompiled;

  @override
  PackageConfig? lastPackageConfig;

  @override
  Set<String> assetPathsToEvict = <String>{};

  @override
  Set<String> shaderPathsToEvict= <String>{};

  @override
  Set<String> scenePathsToEvict= <String>{};

  @override
  Uri? baseUri;
}

class FakeDevice extends Fake implements Device {
  FakeDevice({
    TargetPlatform targetPlatform = TargetPlatform.tester,
  }) : _targetPlatform = targetPlatform;

  final TargetPlatform _targetPlatform;

  bool disposed = false;

  @override
  bool isSupported() => true;

  @override
  bool supportsHotReload = true;

  @override
  bool supportsHotRestart = true;

  @override
  bool supportsFlutterExit = true;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  Future<String> get sdkNameAndVersion async => 'Tester';

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  String get name => 'Fake Device';

  @override
  Future<bool> stopApp(
    ApplicationPackage? app, {
    String? userIdentifier,
  }) async {
    return true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeFlutterDevice(this.device);

  bool stoppedEchoingDeviceLog = false;
  late Future<UpdateFSReport> Function() updateDevFSReportCallback;

  @override
  final FakeDevice device;

  @override
  Future<void> stopEchoingDeviceLog() async {
    stoppedEchoingDeviceLog = true;
  }

  @override
  DevFS? devFS = FakeDevFs();

  @override
  FlutterVmService get vmService => FakeFlutterVmService();

  @override
  ResidentCompiler? generator;

  @override
  Future<UpdateFSReport> updateDevFS({
    Uri? mainUri,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    String? pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) => updateDevFSReportCallback();

  @override
  TargetPlatform? get targetPlatform => device._targetPlatform;
}


class TestHotRunnerConfig extends HotRunnerConfig {
  TestHotRunnerConfig({this.successfulHotRestartSetup, this.successfulHotReloadSetup});
  bool? successfulHotRestartSetup;
  bool? successfulHotReloadSetup;
  bool shutdownHookCalled = false;
  bool updateDevFSCompleteCalled = false;

  @override
  Future<bool?> setupHotRestart() async {
    assert(successfulHotRestartSetup != null, 'setupHotRestart is not expected to be called in this test.');
    return successfulHotRestartSetup;
  }

  @override
  Future<bool?> setupHotReload() async {
    assert(successfulHotReloadSetup != null, 'setupHotReload is not expected to be called in this test.');
    return successfulHotReloadSetup;
  }

  @override
  void updateDevFSComplete() {
    updateDevFSCompleteCalled = true;
  }

  @override
  Future<void> runPreShutdownOperations() async {
    shutdownHookCalled = true;
  }
}


class FakeFlutterVmService extends Fake implements FlutterVmService {
  @override
  vm_service.VmService get service => FakeVmService();

  @override
  Future<List<FlutterView>> getFlutterViews({bool returnEarly = false, Duration delay = const Duration(milliseconds: 50)}) async {
    return <FlutterView>[];
  }
}

class FakeVmService extends Fake implements vm_service.VmService {
  @override
  Future<vm_service.VM> getVM() async => FakeVm();
}

class FakeVm extends Fake implements vm_service.VM {
  @override
  List<vm_service.IsolateRef> get isolates => <vm_service.IsolateRef>[];
}
