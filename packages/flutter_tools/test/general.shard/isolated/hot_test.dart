// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide Target;
import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../hot_shared.dart';
import 'fake_native_assets_build_runner.dart';

void main() {
  group('native assets', () {
    late TestHotRunnerConfig testingConfig;
    late MemoryFileSystem fileSystem;
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
        buildDryRunResult: FakeNativeAssetsBuilderResult(
          assets: <AssetImpl>[
            NativeCodeAssetImpl(
              id: 'package:bar/bar.dart',
              linkMode: DynamicLoadingBundledImpl(),
              os: OSImpl.macOS,
              architecture: ArchitectureImpl.arm64,
              file: Uri.file('bar.dylib'),
            ),
            NativeCodeAssetImpl(
              id: 'package:bar/bar.dart',
              linkMode: DynamicLoadingBundledImpl(),
              os: OSImpl.macOS,
              architecture: ArchitectureImpl.x64,
              file: Uri.file('bar.dylib'),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        nativeAssetsBuilder: FakeHotRunnerNativeAssetsBuilder(buildRunner),
        analytics: fakeAnalytics,
      );
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      expect(result.isOk, true);
      // Hot restart does not require rerunning anything for native assets.
      // The previous native assets mapping should be used.
      expect(buildRunner.buildInvocations, 0);
      expect(buildRunner.buildDryRunInvocations, 0);
      expect(buildRunner.linkInvocations, 0);
      expect(buildRunner.linkDryRunInvocations, 0);
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
        buildDryRunResult: FakeNativeAssetsBuilderResult(
          assets: <AssetImpl>[
            NativeCodeAssetImpl(
              id: 'package:bar/bar.dart',
              linkMode: DynamicLoadingBundledImpl(),
              os: OSImpl.macOS,
              architecture: ArchitectureImpl.arm64,
              file: Uri.file('bar.dylib'),
            ),
            NativeCodeAssetImpl(
              id: 'package:bar/bar.dart',
              linkMode: DynamicLoadingBundledImpl(),
              os: OSImpl.macOS,
              architecture: ArchitectureImpl.x64,
              file: Uri.file('bar.dylib'),
            ),
          ],
        ),
      );

      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        nativeAssetsBuilder: FakeHotRunnerNativeAssetsBuilder(buildRunner),
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
