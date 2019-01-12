// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:meta/meta.dart';

import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:watcher/watcher.dart';

import '../build_info.dart';
import '../globals.dart';
import 'builders.dart';

Future<String> compileKernel({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String packagesPath,
    @required String outputPath,
    @required bool trackWidgetCreation,
    @required bool aot,
    List<String> extraFrontEndOptions = const <String>[],
  }) async {
    final Directory outputDir = Directory(outputPath);
    outputDir.createSync(recursive: true);
    printTrace('Compiling Dart to kernel: $mainPath');
    final List<core.BuilderApplication> applications = <core.BuilderApplication>[
      core.apply('build_modules|module_library',
        <BuilderFactory>[moduleLibraryBuilder],
        core.toAllPackages(),
        isOptional: true,
        hideOutput: true,
        appliesBuilders: <String>['build_modules|module_cleanup']),
      core.apply('build_modules|vm', <BuilderFactory>[
          metaModuleBuilderFactoryForPlatform('flutter'),
          metaModuleCleanBuilderFactoryForPlatform('flutter'),
          moduleBuilderFactoryForPlatform('flutter')
        ],
        core.toNoneByDefault(),
        isOptional: true,
        hideOutput: true,
        appliesBuilders: <String>['build_modules|module_cleanup']),
      core.apply('build_vm_compilers|vm', <BuilderFactory>[
        (BuilderOptions buildOptions) {
          return FlutterKernelBuilder(
            target: mainPath,
            aot: aot,
            trackWidgetCreation: trackWidgetCreation,
            extraFrontEndOptions: extraFrontEndOptions,
            linkPlatformKernelIn: true,
            targetProductVm:  buildMode == BuildMode.release,
          );
        }
      ], core.toRoot(), isOptional: false, hideOutput: true, appliesBuilders: <String>['build_modules|vm'], defaultGenerateFor: const InputSet(
        include: <String>['lib/**'],
      )),
      core.applyPostProcess('build_modules|module_cleanup', moduleCleanup, defaultGenerateFor: const InputSet())
    ];
    final Directory projectRoot = File(packagesPath).parent.absolute;
    final core.PackageGraph packageGraph = core.PackageGraph.forPath(projectRoot.path);
    final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
      core.IOEnvironment(
        packageGraph,
        assumeTty: true,
        outputMap: null,
        outputSymlinksOnly: false,
      ),
      reader: core.FileBasedAssetReader(packageGraph),
      writer: core.FileBasedAssetWriter(packageGraph),
      onLog: (LogRecord record) {
        printTrace(record.toString());
      },
    );
    final core.BuildRunner runner = await core.BuildRunner.create(
      await core.BuildOptions.create(
        core.LogSubscription(environment, verbose: true),
        packageGraph: packageGraph,
        buildDirs: <String>[
          '${projectRoot.path}/build',
        ],
        skipBuildScriptCheck: true,
        trackPerformance: true,
      ),
      environment,
      applications,
      <String, Map<String, Object>>{},
      isReleaseBuild: buildMode == BuildMode.release,
    );
    final core.BuildResult result = await runner.run(const <AssetId, ChangeType>{});
    final String fileName = result.outputs.firstWhere((AssetId assetId) {
      return assetId.path != null && assetId.path.contains('main.app.dill');
    }, orElse: () => null)?.path;
    return fileName;
  }


class ToolBuildEnvironment extends core.BuildEnvironment {
  @override
  void onLog(LogRecord record) {
    print(record.toString());
  }

  @override
  Future<int> prompt(String message, List<String> choices) async {
    print(message);
    print(choices);
    return 0;
  }

  @override
  core.RunnerAssetReader reader;

  @override
  core.RunnerAssetWriter writer;
}
