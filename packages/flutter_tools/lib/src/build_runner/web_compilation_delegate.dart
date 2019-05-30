// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/builders.dart';
import 'package:build_modules/src/module_builder.dart';
import 'package:build_modules/src/platform.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/dev_compiler_bootstrap.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../web/compile.dart';

const String ddcBootstrapExtension = '.dart.bootstrap.js';
const String jsEntrypointExtension = '.dart.js';
const String jsEntrypointSourceMapExtension = '.dart.js.map';
const String jsEntrypointArchiveExtension = '.dart.js.tar.gz';
const String digestsEntrypointExtension = '.digests';
const String jsModuleErrorsExtension = '.ddc.js.errors';
const String jsModuleExtension = '.ddc.js';
const String jsSourceMapExtension = '.ddc.js.map';

final DartPlatform flutterWebPlatform =
    DartPlatform.register('flutter_web', <String>[
  'async',
  'collection',
  'convert',
  'core',
  'developer',
  'html',
  'html_common',
  'indexed_db',
  'js',
  'js_util',
  'math',
  'svg',
  'typed_data',
  'web_audio',
  'web_gl',
  'web_sql',
  '_internal',
  // Flutter web specific libraries.
  'ui',
  '_engine',
  'io',
  'isolate',
]);

/// The build application to compile a flutter application to the web.
final List<core.BuilderApplication> builders = <core.BuilderApplication>[
  core.apply(
      'flutter_tools|module_library',
      <Builder Function(BuilderOptions)>[moduleLibraryBuilder],
      core.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|module_cleanup']),
  core.apply(
      'flutter_tools|ddc_modules',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions options) => MetaModuleBuilder(flutterWebPlatform),
        (BuilderOptions options) => MetaModuleCleanBuilder(flutterWebPlatform),
        (BuilderOptions options) => ModuleBuilder(flutterWebPlatform),
      ],
      core.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|module_cleanup']),
  core.apply(
      'flutter_tools|ddc',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions builderOptions) => KernelBuilder(
              platformSdk: artifacts.getArtifactPath(Artifact.flutterWebSdk),
              summaryOnly: true,
              sdkKernelPath: path.join('kernel', 'flutter_ddc_sdk.dill'),
              outputExtension: ddcKernelExtension,
              platform: flutterWebPlatform,
              librariesPath: 'libraries.json',
            ),
        (BuilderOptions builderOptions) => DevCompilerBuilder(
              useIncrementalCompiler: false,
              platform: flutterWebPlatform,
              platformSdk: artifacts.getArtifactPath(Artifact.flutterWebSdk),
              sdkKernelPath: path.join('kernel', 'flutter_ddc_sdk.dill'),
            ),
      ],
      core.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|ddc_modules']),
  core.apply(
    'flutter_tools|entrypoint',
    <BuilderFactory>[
      (BuilderOptions options) => FlutterWebEntrypointBuilder(
          options.config['target'] ?? 'lib/main.dart'),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'lib/**',
        'web/**',
      ],
    ),
  ),
  core.applyPostProcess('flutter_tools|module_cleanup', moduleCleanup,
      defaultGenerateFor: const InputSet())
];

/// A build_runner specific implementation of the [WebCompilationProxy].
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  core.PackageGraph _packageGraph;
  BuildImpl _builder;
  PackageUriMapper _packageUriMapper;

  @override
  Future<void> initialize({
    @required Directory projectDirectory,
    @required String target,
  }) async {
    // Override the generated output directory so this does not conflict with
    // other build_runner output.
    core.overrideGeneratedOutputDirectory('flutter_web');
    _packageUriMapper = PackageUriMapper(
        path.absolute(target), PackageMap.globalPackagesPath, null, null);
    _packageGraph = core.PackageGraph.forPath(projectDirectory.path);
    final core.BuildEnvironment buildEnvironment = core.OverrideableEnvironment(
        core.IOEnvironment(_packageGraph), onLog: (LogRecord record) {
      if (record.level == Level.SEVERE || record.level == Level.SHOUT) {
        printError(record.message);
      } else {
        printTrace(record.message);
      }
    });
    final LogSubscription logSubscription = LogSubscription(
      buildEnvironment,
      verbose: false,
      logLevel: Level.FINE,
    );
    final BuildOptions buildOptions = await BuildOptions.create(
      logSubscription,
      packageGraph: _packageGraph,
      skipBuildScriptCheck: true,
      trackPerformance: false,
      deleteFilesByDefault: true,
    );
    final Status status =
        logger.startProgress('Compiling $target for the Web...', timeout: null);
    try {
      _builder = await BuildImpl.create(
        buildOptions,
        buildEnvironment,
        builders,
        <String, Map<String, dynamic>>{
          'flutter_tools|entrypoint': <String, dynamic>{
            'target': target,
          }
        },
        isReleaseBuild: false,
      );
      await _builder.run(const <AssetId, ChangeType>{});
    } finally {
      status.stop();
    }
  }

  @override
  Future<bool> invalidate({@required List<Uri> inputs}) async {
    final Status status =
        logger.startProgress('Recompiling sources...', timeout: null);
    final Map<AssetId, ChangeType> updates = <AssetId, ChangeType>{};
    for (Uri input in inputs) {
      updates[AssetId.resolve(
              _packageUriMapper.map(input.toFilePath()).toString())] =
          ChangeType.MODIFY;
    }
    core.BuildResult result;
    try {
      result = await _builder.run(updates);
    } finally {
      status.cancel();
    }
    return result.status == core.BuildStatus.success;
  }
}

/// A ddc-only entrypoint builder that respects the Flutter target flag.
class FlutterWebEntrypointBuilder implements Builder {
  const FlutterWebEntrypointBuilder(this.target);

  final String target;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
        '.dart': <String>[
          ddcBootstrapExtension,
          jsEntrypointExtension,
          jsEntrypointSourceMapExtension,
          jsEntrypointArchiveExtension,
          digestsEntrypointExtension,
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.contains(target)) {
      return;
    }
    log.info('building for target ${buildStep.inputId.path}');
    await bootstrapDdc(buildStep, platform: flutterWebPlatform);
  }
}
