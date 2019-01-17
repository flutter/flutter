// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:meta/meta.dart';
import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../compile.dart';
import '../globals.dart';
import 'builders.dart';

/// An implementation of [KernelCompiler] which is implemented with package:build.
class BuildKernelCompiler implements KernelCompiler {
  const BuildKernelCompiler();

  @override
  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    @required bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool targetProductVm = false,
  }) async {
    printTrace('WARNING: running experimental package:build pipeline. '
      'Opt out by setting ENABLE_PACKAGE_BUILD=false.');
    final Directory projectRoot = fs.file(packagesPath).parent.absolute;
    // We should just handle [BuildScriptChangedException]
    final File assetGraph = fs.file(assetGraphPath);
    if (await assetGraph.exists()) {
      await assetGraph.delete();
    }
    final List<core.BuilderApplication> applications = <core.BuilderApplication>[
        core.apply('build_modules|module_library',
          <BuilderFactory>[moduleLibraryBuilder],
          core.toAllPackages(),
          isOptional: true,
          hideOutput: true,
          appliesBuilders: <String>['build_modules|module_cleanup']),
        core.apply('build_modules|flutter', <BuilderFactory>[
            metaModuleBuilderFactoryForPlatform('flutter'),
            metaModuleCleanBuilderFactoryForPlatform('flutter'),
            moduleBuilderFactoryForPlatform('flutter')
          ],
          core.toAllPackages(),
          isOptional: true,
          hideOutput: true,
          appliesBuilders: <String>['build_modules|module_cleanup']),
        core.apply('build_vm_compilers|flutter', <BuilderFactory>[
          (BuilderOptions buildOptions) {
            return FlutterKernelBuilder(
              target: buildOptions.config['target'],
              aot: buildOptions.config['aot'],
              trackWidgetCreation: buildOptions.config['trackWidgetCreation'],
              extraFrontEndOptions: buildOptions.config['extraFrontEndOptions'],
              linkPlatformKernelIn: buildOptions.config['linkPlatformKernelIn'],
              targetProductVm: buildOptions.config['targetProductVm'],
              sdkRoot: buildOptions.config['sdkRoot'],
              incrementalCompilerByteStorePath: buildOptions.config['incrementalCompilerByteStorePath'],
              packagesPath: buildOptions.config['packagesPath'],
            );
          }
        ],
        core.toRoot(),
        isOptional: false,
        hideOutput: true,
        appliesBuilders: <String>['build_modules|flutter'],
        defaultGenerateFor: const InputSet(include: <String>['lib/**'])
      ),
      core.applyPostProcess('build_modules|module_cleanup', moduleCleanup, defaultGenerateFor: const InputSet())
    ];
    final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
    final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
      core.IOEnvironment(
        packageGraph,
        assumeTty: true,
        outputMap: null,
        outputSymlinksOnly: false,
      ),
      onLog: (LogRecord record) {
        printTrace(record.toString());
      },
    );
    final core.BuildRunner runner = await core.BuildRunner.create(
      await core.BuildOptions.create(
        core.LogSubscription(environment, verbose: true),
        packageGraph: packageGraph,
        skipBuildScriptCheck: true,
        trackPerformance: true,
      ),
      environment,
      applications,
      <String, Map<String, Object>>{
        'build_vm_compilers|flutter': <String, Object>{
          'target': mainPath,
          'aot': aot,
          'trackWidgetCreation': trackWidgetCreation,
          'extraFrontEndOptions': extraFrontEndOptions,
          'linkPlatformKernelIn': linkPlatformKernelIn,
          'targetProductVm': targetProductVm,
          'sdkRoot': sdkRoot,
          'incrementalCompilerByteStorePath': incrementalCompilerByteStorePath,
          'packagesPath': packagesPath,
        },
      },
      isReleaseBuild: aot,
    );
    final core.BuildResult result = await runner.run(const <AssetId, ChangeType>{});
    await runner.beforeExit();
    final Duration executionTime = result.performance.stopTime.difference(result.performance.startTime);
    printTrace('build took: $executionTime');

    if (result.status == core.BuildStatus.failure) {
      printTrace('build failed: ${result.failureType}');
      return const CompilerOutput(null, 1);
    }

    // Figure out a nicer way to do this.
    final AssetId output = result.outputs.firstWhere((AssetId assetId) {
      return assetId.path != null && assetId.path.contains('.app.dill');
    }, orElse: () => null);
    if (output == null) {
      return const CompilerOutput(null, 1);
    }
    final String fileName = '${projectRoot.path}/.dart_tool/build/generated/${output.package}/${output.path}';
    // Copy output file back to expected location.
    fs.file('$outputFilePath')
      ..createSync()
      ..writeAsBytesSync(fs.file(fileName).readAsBytesSync());
    return CompilerOutput(fileName, fileName != null ? 0 : 1);
  }
}

class ToolBuildEnvironment extends core.BuildEnvironment {
  @override
  void onLog(LogRecord record) {
    print(record.toString());
  }

  @override
  Future<int> prompt(String message, List<String> choices) async {
    throw UnsupportedError(message);
  }

  @override
  core.RunnerAssetReader reader;

  @override
  core.RunnerAssetWriter writer;
}
