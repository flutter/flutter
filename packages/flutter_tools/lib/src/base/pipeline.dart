// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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

Builder _kFlutterIncrementalBuilder(BuilderOptions builderOptions) {
  return const FlutterIncrementalKernelBuilder();
}

Builder _kFlutterBuilder(BuilderOptions builderOptions) {
  return FlutterKernelBuilder(
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

/// The [core.BuilderApplication] to compile kernel from dart source from builds.
final List<core.BuilderApplication> _kFlutterBuildApplications = <core.BuilderApplication>[
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
  core.apply(
    'build_vm_compilers|flutter',
    <BuilderFactory>[_kFlutterBuilder],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|flutter'],
    defaultGenerateFor: const InputSet(include: <String>['lib/**']),
  ),
  core.applyPostProcess(
    'build_modules|module_cleanup',
    moduleCleanup,
    defaultGenerateFor: const InputSet(),
  )
];

/// The [core.BuilderApplication] to compile kernel from dart source for runs.
final List<core.BuilderApplication> _kFlutterRunApplications = <core.BuilderApplication>[
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
  core.apply(
    'build_vm_compilers|flutter',
    <BuilderFactory>[_kFlutterIncrementalBuilder],
    core.toRoot(),
    isOptional: false,
    hideOutput: true,
    appliesBuilders: <String>['build_modules|flutter'],
    defaultGenerateFor: const InputSet(include: <String>['lib/**']),
  ),
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
    final Directory projectRoot = fs.file(packagesPath).parent.absolute;
    // We should just handle [BuildScriptChangedException]
    final File assetGraph = fs.file(assetGraphPath);
    if (await assetGraph.exists()) {
      await assetGraph.delete();
    }
    final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
    final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
      core.IOEnvironment(packageGraph),
    );
    final core.BuildRunner runner = await core.BuildRunner.create(
      await core.BuildOptions.create(
        core.LogSubscription(environment, verbose: true),
        packageGraph: packageGraph,
        skipBuildScriptCheck: true,
        trackPerformance: true,
      ),
      environment,
      _kFlutterBuildApplications,
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

class BuildResidentCompiler implements ResidentCompiler {
  BuildResidentCompiler._(this._residentCompiler, this._buildRunner, this._watcher, this._packageGraph) {
    final String rootPath = '${_packageGraph.root.path}/lib/';
    _watchSubscription = _watcher.events.listen((WatchEvent watchEvent) {
      final String relativePath =watchEvent.path.replaceFirst(rootPath, '');
      final AssetId assetId = AssetId.parse('${_packageGraph.root.name}|$relativePath');
      _pendingInvalidated[assetId] = watchEvent.type;
    });
  }

  static Future<BuildResidentCompiler> create(String sdkRoot, {
    bool trackWidgetCreation = false,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String initializeFromDill,
    TargetModel targetModel = TargetModel.flutter,
  }) async {
    final PackageGraph packageGraph = PackageGraph.forThisPackage();
    final BuildRunner runner = await createHotRunner();
    final ResidentCompiler compiler = ResidentCompiler(sdkRoot,
      trackWidgetCreation: trackWidgetCreation,
      packagesPath: packagesPath,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      initializeFromDill: initializeFromDill,
      targetModel: targetModel,
    );
    final DirectoryWatcher watcher = Watcher(fs.currentDirectory.childDirectory('lib').path);
    return BuildResidentCompiler._(compiler, runner, watcher, packageGraph);
  }

  final ResidentCompiler _residentCompiler;
  final BuildRunner _buildRunner;
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
    final List<String> invalidatedFilesCopy = invalidatedFiles.toList();
    if (!runOnce || _pendingInvalidated.isNotEmpty) {
      final Map<AssetId, ChangeType> copy = Map<AssetId, ChangeType>.from(_pendingInvalidated);
      _pendingInvalidated.clear();
      final BuildResult result = await _buildRunner.run(copy);
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

Future<BuildRunner> createHotRunner() async{
  printTrace('WARNING: running experimental package:build pipeline. '
    'Opt out by setting ENABLE_PACKAGE_BUILD=false.');
  final File assetGraph = fs.file(assetGraphPath);
  if (await assetGraph.exists()) {
    await assetGraph.delete();
  }
  final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
  final core.OverrideableEnvironment environment = core.OverrideableEnvironment(
    core.IOEnvironment(packageGraph),
  );
  return core.BuildRunner.create(
    await core.BuildOptions.create(
      core.LogSubscription(environment, verbose: true),
      packageGraph: packageGraph,
      skipBuildScriptCheck: true,
      trackPerformance: true,
    ),
    environment,
    _kFlutterRunApplications,
    <String, Map<String, Object>>{
      'build_vm_compilers|flutter': <String, Object>{},
    },
    isReleaseBuild: false,
  );
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
