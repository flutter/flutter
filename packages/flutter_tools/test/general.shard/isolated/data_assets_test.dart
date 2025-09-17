// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:data_assets/data_assets.dart';
import 'package:file/file.dart' show File, FileSystem;
import 'package:file/memory.dart' show MemoryFileSystem;
import 'package:flutter_tools/src/artifacts.dart' show Artifacts;
import 'package:flutter_tools/src/base/logger.dart' show BufferLogger;
import 'package:flutter_tools/src/build_info.dart' show BuildMode, TargetPlatform, kBuildMode;
import 'package:flutter_tools/src/build_system/build_system.dart' show Environment;
import 'package:flutter_tools/src/features.dart' show FeatureFlags;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart'
    show runFlutterSpecificHooks;

import '../../src/common.dart' show expect, returnsNormally, setUp, throwsToolExit;
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

  testUsingContext(
    'build but data assets are not enabled',
    overrides: <Type, Generator>{
      ProcessManager: FakeProcessManager.empty,
      FeatureFlags: () => TestFeatureFlags(),
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          targetPlatform: TargetPlatform.windows_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
          ),
        ),
        throwsToolExit(
          message: 'Enable data assets using `flutter config --enable-dart-data-assets`',
        ),
      );
    },
  );

  testUsingContext(
    'Data assets: no duplicate assets with linking',
    overrides: <Type, Generator>{
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true),
      ProcessManager: FakeProcessManager.empty,
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File imageFile = environment.projectDir.childFile('image.png');
      imageFile.writeAsBytesSync(<int>[]);
      final File textFile1 = environment.projectDir.childFile('text.txt');
      textFile1.writeAsStringSync('test');
      final File textFile2 = environment.projectDir.childFile('text.json');
      textFile2.writeAsStringSync('{}');

      DataAsset makeDataAsset(String name, Uri file) =>
          DataAsset(package: 'bar', name: name, file: file);

      for (final buildMode in <BuildMode>[BuildMode.debug, BuildMode.release]) {
        expect(
          () async => runFlutterSpecificHooks(
            environmentDefines: <String, String>{kBuildMode: buildMode.cliName},
            targetPlatform: TargetPlatform.linux_x64,
            projectUri: projectUri,
            fileSystem: fileSystem,
            buildRunner: FakeFlutterNativeAssetsBuildRunner(
              packagesWithNativeAssetsResult: <String>['bar'],
              buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
                dataAssets: <DataAsset>[makeDataAsset('direct', imageFile.uri)],
                dataAssetsForLinking: <String, List<DataAsset>>{
                  'package:bar': <DataAsset>[makeDataAsset('linkable', textFile1.uri)],
                },
              ),
              linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
                dataAssets: <DataAsset>[
                  makeDataAsset('direct', imageFile.uri),
                  makeDataAsset('linked', textFile2.uri),
                ],
              ),
            ),
          ),
          buildMode == BuildMode.release
              ? throwsToolExit(message: 'Found duplicates')
              : returnsNormally,
        );
      }
    },
  );
}
