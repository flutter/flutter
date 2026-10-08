// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart' show File, FileSystem;
import 'package:file/memory.dart' show MemoryFileSystem;
import 'package:flutter_tools/src/artifacts.dart' show Artifacts;
import 'package:flutter_tools/src/base/logger.dart' show BufferLogger;
import 'package:flutter_tools/src/build_info.dart' show BuildMode, TargetPlatform, kBuildMode;
import 'package:flutter_tools/src/build_system/build_system.dart' show Environment;
import 'package:flutter_tools/src/features.dart' show FeatureFlags;
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart'
    show DartHooksResult;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart'
    show BuildCodeAssetsOptions, runFlutterSpecificHooks;
import 'package:font_asset/font_asset.dart';
import 'package:hooks/hooks.dart' show BuildInput;

import '../../src/common.dart'
    show contains, containsAll, expect, isNot, returnsNormally, setUp, throwsToolExit;
import '../../src/context.dart'
    show FakeProcessManager, Generator, ProcessManager, testUsingContext;
import '../../src/fakes.dart' show TestFeatureFlags;
import 'fake_native_assets_build_runner.dart'
    show FakeFlutterNativeAssetsBuildRunner, FakeFlutterNativeAssetsBuilderResult;

void main() {
  late FakeProcessManager processManager;
  late Environment environment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Uri projectUri;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    projectUri = environment.projectDir.uri;
  });

  for (final dataAssetsEnabled in <bool>[false, true]) {
    testUsingContext(
      'Font assets: hooks are ${dataAssetsEnabled ? '' : 'not '}asked for fonts when '
      'enable-dart-data-assets is ${dataAssetsEnabled ? 'on' : 'off'}',
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isNativeAssetsEnabled: true,
          isDartDataAssetsEnabled: dataAssetsEnabled,
        ),
        ProcessManager: FakeProcessManager.empty,
      },
      () async {
        final File packageConfig = environment.projectDir.childFile(
          '.dart_tool/package_config.json',
        );
        await packageConfig.parent.create();
        await packageConfig.create();

        final requestedAssetTypes = <String>[];
        await runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.release.cliName},
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            onBuild: (BuildInput input) {
              requestedAssetTypes.addAll(input.config.buildAssetTypes);
              return FakeFlutterNativeAssetsBuilderResult.fromAssets();
            },
          ),
        );

        // Fonts are an extension of data assets and ride on the same experiment
        // flag, so a hook only sees the font asset type when that flag is on.
        expect(
          requestedAssetTypes,
          dataAssetsEnabled ? contains(fontAssetType) : isNot(contains(fontAssetType)),
        );
      },
    );
  }

  testUsingContext(
    'Font assets: build, link, filesToBeBundled, and JSON serialization',
    overrides: <Type, Generator>{
      FeatureFlags: () =>
          TestFeatureFlags(isNativeAssetsEnabled: true, isDartDataAssetsEnabled: true),
      ProcessManager: FakeProcessManager.empty,
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File regularFont = environment.projectDir.childFile('fonts/Regular.ttf')
        ..createSync(recursive: true)
        ..writeAsStringSync('regular');
      final File boldFont = environment.projectDir.childFile('fonts/Bold.ttf')
        ..createSync(recursive: true)
        ..writeAsStringSync('bold');

      final asset1 = FontAsset(
        package: 'bar',
        name: 'fonts/Regular.ttf',
        family: 'BarFont',
        file: regularFont.uri,
        weight: 400,
        style: 'normal',
      );
      final asset2 = FontAsset(
        package: 'bar',
        name: 'fonts/Bold.ttf',
        family: 'BarFont',
        file: boldFont.uri,
        weight: 700,
      );

      final DartHooksResult result = await runFlutterSpecificHooks(
        environmentDefines: <String, String>{kBuildMode: BuildMode.release.cliName},
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            fontAssets: <FontAsset>[asset1],
            fontAssetsForLinking: <String, List<FontAsset>>{
              'package:font_asset': <FontAsset>[asset2],
            },
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            fontAssets: <FontAsset>[asset2],
          ),
        ),
      );

      expect(result.fontAssets, <FontAsset>[asset2, asset1]);
      expect(result.filesToBeBundled, containsAll(<Uri>[regularFont.uri, boldFont.uri]));

      final roundTrip = DartHooksResult.fromJson(result.toJson());
      expect(roundTrip.fontAssets, <FontAsset>[asset2, asset1]);
      expect(roundTrip.asFlutterResult.fontAssets.length, 2);
    },
  );

  testUsingContext(
    'Font assets: duplicate font assets with linking throws',
    overrides: <Type, Generator>{
      FeatureFlags: () =>
          TestFeatureFlags(isNativeAssetsEnabled: true, isDartDataAssetsEnabled: true),
      ProcessManager: FakeProcessManager.empty,
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File font1 = environment.projectDir.childFile('font1.ttf')..writeAsStringSync('1');
      final File font2 = environment.projectDir.childFile('font2.ttf')..writeAsStringSync('2');

      FontAsset makeFontAsset(String name, Uri file) =>
          FontAsset(package: 'bar', name: name, family: 'BarFont', file: file);

      for (final buildMode in <BuildMode>[BuildMode.debug, BuildMode.release]) {
        expect(
          () async => runFlutterSpecificHooks(
            environmentDefines: <String, String>{kBuildMode: buildMode.cliName},
            targetPlatform: TargetPlatform.linux_x64,
            projectUri: projectUri,
            buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
            buildDataAssets: true,
            recordedUsesFile: null,
            fileSystem: fileSystem,
            buildRunner: FakeFlutterNativeAssetsBuildRunner(
              packagesWithNativeAssetsResult: <String>['bar'],
              buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
                fontAssets: <FontAsset>[makeFontAsset('direct.ttf', font1.uri)],
              ),
              linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
                fontAssets: <FontAsset>[
                  makeFontAsset('direct.ttf', font1.uri),
                  makeFontAsset('linked.ttf', font2.uri),
                ],
              ),
            ),
          ),
          buildMode == BuildMode.release
              ? throwsToolExit(message: 'Found duplicates in the font assets')
              : returnsNormally,
        );
      }
    },
  );
}
