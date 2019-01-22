// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:meta/meta.dart';
import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:watcher/watcher.dart';
import 'package:inject_generator/inject_generator.dart';

import '../base/file_system.dart';
import '../compile.dart';
import '../globals.dart';
import 'builders.dart';

Builder _kFlutterIncrementalBuilder(BuilderOptions builderOptions) {
  return FlutterIncrementalKernelBuilder(
    disabled: builderOptions.config['disabled'],
  );
}

Builder _kFlutterBuilder(BuilderOptions builderOptions) {
  return FlutterKernelBuilder(
    disabled: builderOptions.config['disabled'],
    target: builderOptions.config['target'],
    aot: builderOptions.config['aot'],
    trackWidgetCreation: builderOptions.config['trackWidgetCreation'],
    extraFrontEndOptions: builderOptions.config['extraFrontEndOptions'],
    linkPlatformKernelIn: builderOptions.config['linkPlatformKernelIn'],
    targetProductVm: builderOptions.config['targetProductVm'],
    sdkRoot: builderOptions.config['sdkRoot'],
    incrementalCompilerByteStorePath: builderOptions.config['incrementalCompilerByteStorePath'],
    packagesPath: builderOptions.config['packagesPath'],
  );
}

Builder _kFlutterEntrypointTestBulder(BuilderOptions builderOptions) {
  return FlutterTestEntrypointBuilder(
    disabled: builderOptions.config['disabled'],
  );
}

/// The [core.BuilderApplication] to compile kernel for all flutter commands.
final List<core.BuilderApplication> _kFlutterApplications = <core.BuilderApplication>[
  /// Code generation libraries
  core.apply(
    'flutter_svg|svg',
    <BuilderFactory>[(BuilderOptions options) => const TestSvgBuilder()],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
  ),
  core.apply(
    'inject|inject',
    <BuilderFactory>[summarizeBuilder, generateBuilder],
    core.toDependentsOf('inject'),
    hideOutput: true
  ),
  /// package:build provided applications to compute modules for faster incremental
  /// builds.
  core.apply(
    'build_modules|module_library',
    <BuilderFactory>[moduleLibraryBuilder],
    core.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|module_cleanup'],
  ),
  core.apply(
    'build_modules|flutter',
    <BuilderFactory>[
      metaModuleBuilderFactoryForPlatform('flutter'),
      metaModuleCleanBuilderFactoryForPlatform('flutter'),
      moduleBuilderFactoryForPlatform('flutter')
    ],
    core.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|module_cleanup'],
  ),
  /// Step that triggers code generation for all main entrypoint files.
  core.apply(
    'flutter_run|flutter',
    <BuilderFactory>[_kFlutterIncrementalBuilder],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|flutter'],
    defaultGenerateFor: const InputSet(include: <String>['lib/**']),
  ),
  /// Step that triggers code generation for all test entrypoint files.
  core.apply(
    'flutter_test|flutter',
    <BuilderFactory>[_kFlutterEntrypointTestBulder],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|flutter'],
    defaultGenerateFor: const InputSet(include: <String>['test/**']),
  ),
  /// Step that produces a kernel file for `flutter build`.
  core.apply(
    'flutter_build|flutter',
    <BuilderFactory>[_kFlutterBuilder],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|flutter'],
    defaultGenerateFor: const InputSet(include: <String>['lib/**']),
  ),
  /// Step that removes temporary artifacts created by build process.
  core.applyPostProcess(
    'build_modules|module_cleanup',
    moduleCleanup,
    defaultGenerateFor: const InputSet(),
  ),
];

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
    if (await fs.file(assetGraphPath).exists()) {
      await fs.file(assetGraphPath).delete();
    }
    final Directory projectRoot = fs.file(packagesPath).parent.absolute;
    final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
    final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
      core.IOEnvironment(packageGraph),
    );
    final core.BuildRunner runner = await core.BuildRunner.create(
      await core.BuildOptions.create(
        core.LogSubscription(environment, verbose: false),
        packageGraph: packageGraph,
        skipBuildScriptCheck: true,
        trackPerformance: true,
      ),
      environment,
      _kFlutterApplications,
      <String, Map<String, Object>>{
        'flutter_build|flutter': <String, Object>{
          'disabled': false,
          'target': mainPath,
          'aot': aot,
          'trackWidgetCreation': trackWidgetCreation,
          'extraFrontEndOptions': extraFrontEndOptions,
          'linkPlatformKernelIn': linkPlatformKernelIn,
          'targetProductVm': targetProductVm,
          'sdkRoot': sdkRoot,
          'incrementalCompilerByteStorePath': incrementalCompilerByteStorePath,
          'packagesPath': packagesPath,
          'fileSystemScheme': fileSystemScheme,
          'fileSystemRoots': fileSystemRoots,
        },
        'flutter_run|flutter': <String, Object>{
          'disabled': true,
        },
        'flutter_test|flutter': <String, Object>{
          'disabled': true,
        }
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
    // Copy output file back to expected location by rest of tools.
    fs.file('$outputFilePath')
      ..createSync()
      ..writeAsBytesSync(fs.file(fileName).readAsBytesSync());
    return CompilerOutput(fileName, fileName != null ? 0 : 1);
  }
}

class BuildResidentCompiler implements ResidentCompiler {
  BuildResidentCompiler._(this._residentCompiler, this._buildRunner, this._watcher, this._packageGraph, this.packages, this.fileSystemRoots, this.fileSystemScheme) {
    final String rootPath = '${_packageGraph.root.path}/';
    _watchSubscription = _watcher.events.listen((WatchEvent watchEvent) {
      final String relativePath =watchEvent.path.replaceFirst(rootPath, '');
      final AssetId assetId = AssetId.parse('${_packageGraph.root.name}|$relativePath');
      _pendingInvalidated[assetId] = watchEvent.type;
    });
  }

  static Future<BuildResidentCompiler> create(String sdkRoot, {
    bool trackWidgetCreation = false,
    String packagesPath,
    String initializeFromDill,
    TargetModel targetModel = TargetModel.flutter,
  }) async {
    final PackageGraph packageGraph = PackageGraph.forThisPackage();
    final BuildRunner runner = await createBuildRunner(mode: Mode.run);
    final BuildResult result = await runner.run(const <AssetId, ChangeType>{});
    if (result.status != BuildStatus.success) {
      throwToolExit('Build failure: ${result.failureType}');
    }
    final String generatedPath = fs.path.join(fs.currentDirectory.absolute.path, '.dart_tool', 'build', 'generated');
    final File newPackages = fs.file(fs.path.join(generatedPath, 'hello_world', 'lib', 'main.packages'));
    String updatedPackagesPath;
    if (newPackages.existsSync()) {
      updatedPackagesPath = newPackages.absolute.path;
    } else {
      updatedPackagesPath = packagesPath;
    }
    final List<String> fileSystemRoots = <String>[
      fs.path.join(fs.currentDirectory.absolute.path),
      fs.path.join(generatedPath, 'hello_world'),
    ];
    await runner.beforeExit();
    final ResidentCompiler compiler = ResidentCompiler(sdkRoot,
      trackWidgetCreation: trackWidgetCreation,
      packagesPath: updatedPackagesPath,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: multiRootScheme,
      initializeFromDill: initializeFromDill,
      targetModel: targetModel,
    );
    final DirectoryWatcher watcher = Watcher(fs.path.join(fs.currentDirectory.absolute.path, 'lib'));
    return BuildResidentCompiler._(compiler, runner, watcher, packageGraph, updatedPackagesPath, fileSystemRoots, multiRootScheme);
  }

  final ResidentCompiler _residentCompiler;
  final BuildRunner _buildRunner;
  final String packages;
  final List<String> fileSystemRoots;
  final String fileSystemScheme;
  final Map<AssetId, ChangeType> _pendingInvalidated = <AssetId, ChangeType>{};
  DirectoryWatcher _watcher;
  PackageGraph _packageGraph;
  StreamSubscription<WatchEvent> _watchSubscription;
  bool runOnce = false;

  @override
  void accept() {
    _residentCompiler.accept();
  }

  @override
  Future<CompilerOutput> compileExpression(String expression, List<String> definitions, List<String> typeDefinitions, String libraryUri, String klass, bool isStatic) {
    return _residentCompiler.compileExpression(expression, definitions, typeDefinitions, libraryUri, klass, isStatic);
  }

  @override
  Future<CompilerOutput> recompile(String mainPath, List<String> invalidatedFiles, {@required String outputPath, String packagesFilePath}) async {
    final List<String> invalidatedFilesCopy = invalidatedFiles.where((String file) => !file.contains('.dart_tool')).toList();
    if (!runOnce || _pendingInvalidated.isNotEmpty) {
      printTrace('$_pendingInvalidated');
      final Map<AssetId, ChangeType> copy = Map<AssetId, ChangeType>.from(_pendingInvalidated);
      _pendingInvalidated.clear();
      final BuildResult result = await _buildRunner.run(copy);
      await _buildRunner.beforeExit();
      if (result.status == BuildStatus.failure) {
        return const CompilerOutput('', 1);
      }
      for (AssetId assetId in result.outputs) {
        if (assetId.path.endsWith('.dart')) {
          invalidatedFilesCopy.add(assetId.path);
        }
      }
      runOnce = true;
    }
    printTrace('INVALIDED: $invalidatedFilesCopy');
    return _residentCompiler.recompile(mainPath, invalidatedFilesCopy, outputPath: outputPath, packagesFilePath: packagesFilePath);
  }

  @override
  void reject() {
    _residentCompiler.reject();
  }

  @override
  void reset() {
    _residentCompiler.reset();
  }

  @override
  Future<void> shutdown() {
    _watchSubscription.cancel();
    return _residentCompiler.shutdown();
  }
}

enum Mode {
  run,
  test,
}

Future<BuildRunner> createBuildRunner({Mode mode}) async {
  printTrace('WARNING: running experimental package:build pipeline. '
    'Opt out by setting ENABLE_PACKAGE_BUILD=false.');
  if (await fs.file(assetGraphPath).exists()) {
    await fs.file(assetGraphPath).delete();
  }
  final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
  final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
    core.IOEnvironment(packageGraph),
  );
  return core.BuildRunner.create(
    await core.BuildOptions.create(
      core.LogSubscription(environment, verbose: false),
      packageGraph: packageGraph,
      skipBuildScriptCheck: true,
      trackPerformance: true,
    ),
    environment,
    _kFlutterApplications, <String, Map<String, Object>> {
      'flutter_build|flutter': <String, Object>{
        'disabled': true,
      },
      'flutter_run|flutter': <String, Object>{
        'disabled': mode != Mode.run
      },
      'flutter_test|flutter': <String, Object>{
        'disabled': mode != Mode.test
      },
    },
    isReleaseBuild: false,
  );
}

class ToolBuildEnvironment extends core.BuildEnvironment {
  @override
  void onLog(LogRecord record) {
    printTrace(record.toString());
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
