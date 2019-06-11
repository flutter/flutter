// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:io' as io; // ignore: dart_io_import

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/builders.dart';
import 'package:build_modules/src/module_builder.dart';
import 'package:build_modules/src/platform.dart';
import 'package:build_modules/src/workers.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_test/builder.dart';
import 'package:build_test/src/debug_test_builder.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/dev_compiler_bootstrap.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:scratch_space/scratch_space.dart';
import 'package:test_core/backend.dart';
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../compile.dart';
import '../convert.dart';
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
    'flutter_tools|test_bootstrap',
    <BuilderFactory>[
      (BuilderOptions options) => const DebugTestBuilder(),
      (BuilderOptions options) => const FlutterWebTestBootstrapBuilder(),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'test/**',
      ],
    ),
  ),
  core.apply(
    'flutter_tools|shell',
    <BuilderFactory>[
      (BuilderOptions options) => FlutterWebShellBuilder(
        options.config['targets'] ?? <String>['lib/main.dart']
      ),
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
          options.config['targets'] ?? <String>['lib/main.dart'],
          options.config['release'],
      ),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'lib/**',
      ],
    ),
  ),
  core.apply(
    'flutter_tools|test_entrypoint',
    <BuilderFactory>[
      (BuilderOptions options) => FlutterWebTestEntrypointBuilder(
        options.config['targets'] ?? const <String>[]
      ),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'test/**_test.dart.browser_test.dart',
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
  Future<bool> initialize({
    @required Directory projectDirectory,
    @required List<String> targets,
    String testOutputDir,
    bool release = false,
  }) async {
    // Create the .dart_tool directory if it doesn't exist.
    projectDirectory.childDirectory('.dart_tool').createSync();

    // Override the generated output directory so this does not conflict with
    // other build_runner output.
    core.overrideGeneratedOutputDirectory('flutter_web');
    _packageUriMapper = PackageUriMapper(
        path.absolute('lib/main.dart'), PackageMap.globalPackagesPath, null, null);
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
      enableLowResourcesMode: platform.environment['FLUTTER_LOW_RESOURCE_MODE']?.toLowerCase() == 'true',
    );
    final Set<core.BuildDirectory> buildDirs = <core.BuildDirectory>{
      if (testOutputDir != null)
        core.BuildDirectory(
          'test',
          outputLocation: core.OutputLocation(
            testOutputDir,
            useSymlinks: !platform.isWindows,
          ),
      ),
    };
    final Status status =
        logger.startProgress('Compiling ${targets.first} for the Web...', timeout: null);
    core.BuildResult result;
    try {
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        targets,
        release,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
    } on core.BuildConfigChangedException {
      await _cleanAssets(projectDirectory);
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        targets,
        release,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
    } on core.BuildScriptChangedException {
      await _cleanAssets(projectDirectory);
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        targets,
        release,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
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
      final AssetId assetId = AssetId.resolve(_packageUriMapper.map(input.toFilePath()).toString());
      updates[assetId] = ChangeType.MODIFY;
    }
    core.BuildResult result;
    try {
      result = await _builder.run(updates);
    } finally {
      status.cancel();
    }
    return result.status == core.BuildStatus.success;
  }


  Future<core.BuildResult> _runBuilder(core.BuildEnvironment buildEnvironment, BuildOptions buildOptions, List<String> targets, bool release, Set<core.BuildDirectory> buildDirs) async {
    _builder = await BuildImpl.create(
      buildOptions,
      buildEnvironment,
      builders,
      <String, Map<String, dynamic>>{
        'flutter_tools|entrypoint': <String, dynamic>{
          'targets': targets,
          'release': release,
        },
        'flutter_tools|test_entrypoint': <String, dynamic>{
          'targets': targets,
          'release': release,
        },
        'flutter_tools|shell': <String, dynamic>{
          'targets': targets,
        }
      },
      isReleaseBuild: false,
    );
    return _builder.run(
      const <AssetId, ChangeType>{},
      buildDirs: buildDirs,
    );
  }

  Future<void> _cleanAssets(Directory projectDirectory) async {
    final File assetGraphFile = fs.file(core.assetGraphPath);
    AssetGraph assetGraph;
    try {
      assetGraph = AssetGraph.deserialize(await assetGraphFile.readAsBytes());
    } catch (_) {
      printTrace('Failed to clean up asset graph.');
    }
    final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
    await _cleanUpSourceOutputs(assetGraph, packageGraph);
    final Directory cacheDirectory = fs.directory(fs.path.join(
      projectDirectory.path,
      '.dart_tool',
      'build',
      'flutter_web',
    ));
    if (assetGraphFile.existsSync()) {
      assetGraphFile.deleteSync();
    }
    if (cacheDirectory.existsSync()) {
      cacheDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> _cleanUpSourceOutputs(AssetGraph assetGraph, core.PackageGraph packageGraph) async {
    final core.FileBasedAssetWriter writer = core.FileBasedAssetWriter(packageGraph);
    if (assetGraph?.outputs == null) {
      return;
    }
    for (AssetId id in assetGraph.outputs) {
      if (id.package != packageGraph.root.name) {
        continue;
      }
      final GeneratedAssetNode node = assetGraph.get(id);
      if (node.wasOutput) {
        // Note that this does a file.exists check in the root package and
        // only tries to delete the file if it exists. This way we only
        // actually delete to_source outputs, without reading in the build
        // actions.
        await writer.delete(id);
      }
    }
  }
}

/// A ddc-only entrypoint builder that respects the Flutter target flag.
class FlutterWebTestEntrypointBuilder implements Builder {
  const FlutterWebTestEntrypointBuilder(this.targets);

  final List<String> targets;

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
    bool matches = false;
    for (String target in targets) {
      if (buildStep.inputId.path.contains(target)) {
        matches = true;
        break;
      }
    }
    if (!matches) {
      return;
    }
    log.info('building for target ${buildStep.inputId.path}');
    await bootstrapDdc(buildStep, platform: flutterWebPlatform);
  }
}

/// A ddc-only entrypoint builder that respects the Flutter target flag.
class FlutterWebEntrypointBuilder implements Builder {
  const FlutterWebEntrypointBuilder(this.targets, this.release);

  final List<String> targets;
  final bool release;

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
    bool matches = false;
    for (String target in targets) {
      if (buildStep.inputId.path.contains(fs.path.setExtension(target, '_web_entrypoint.dart'))) {
        matches = true;
        break;
      }
    }
    if (!matches) {
      return;
    }
    log.info('building for target ${buildStep.inputId.path}');
    if (release) {
      await bootstrapDart2Js(buildStep);
    } else {
      await bootstrapDdc(buildStep, platform: flutterWebPlatform);
    }
  }
}

/// Bootstraps the test entrypoint.
class FlutterWebTestBootstrapBuilder implements Builder {
  const FlutterWebTestBootstrapBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '_test.dart': <String>[
      '_test.dart.browser_test.dart',
    ]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId id = buildStep.inputId;
    final String contents = await buildStep.readAsString(id);
    final String assetPath = id.pathSegments.first == 'lib'
        ? path.url.join('packages', id.package, id.path)
        : id.path;
    final Metadata metadata = parseMetadata(
        assetPath, contents, Runtime.builtIn.map((Runtime runtime) => runtime.name).toSet());

    if (metadata.testOn.evaluate(SuitePlatform(Runtime.chrome))) {
    await buildStep.writeAsString(id.addExtension('.browser_test.dart'), '''
import 'dart:ui' as ui;
import 'dart:html';
import 'dart:js';

import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/src/backend/stack_trace_formatter.dart'; // ignore: implementation_imports
import 'package:test_api/src/util/stack_trace_mapper.dart'; // ignore: implementation_imports
import 'package:test_api/src/remote_listener.dart'; // ignore: implementation_imports
import 'package:test_api/src/suite_channel_manager.dart'; // ignore: implementation_imports

import "${path.url.basename(id.path)}" as test;

Future<void> main() async {
  // Extra initialization for flutter_web.
  // The following parameters are hard-coded in Flutter's test embedder. Since
  // we don't have an embedder yet this is the lowest-most layer we can put
  // this stuff in.
  await ui.webOnlyInitializeEngine();
  // TODO(flutterweb): remove need for dynamic cast.
  (ui.window as dynamic).debugOverrideDevicePixelRatio(3.0);
  (ui.window as dynamic).webOnlyDebugPhysicalSizeOverride = const ui.Size(2400, 1800);
  internalBootstrapBrowserTest(() => test.main);
}

void internalBootstrapBrowserTest(Function getMain()) {
  var channel =
      serializeSuite(getMain, hidePrints: false, beforeLoad: () async {
    var serialized =
        await suiteChannel("test.browser.mapper").stream.first as Map;
    if (serialized == null) return;
  });
  postMessageChannel().pipe(channel);
}
StreamChannel serializeSuite(Function getMain(),
        {bool hidePrints = true, Future beforeLoad()}) =>
    RemoteListener.start(getMain,
        hidePrints: hidePrints, beforeLoad: beforeLoad);

StreamChannel suiteChannel(String name) {
  var manager = SuiteChannelManager.current;
  if (manager == null) {
    throw StateError('suiteChannel() may only be called within a test worker.');
  }

  return manager.connectOut(name);
}

StreamChannel postMessageChannel() {
  var controller = StreamChannelController(sync: true);
  window.onMessage.firstWhere((message) {
    return message.origin == window.location.origin && message.data == "port";
  }).then((message) {
    var port = message.ports.first;
    var portSubscription = port.onMessage.listen((message) {
      controller.local.sink.add(message.data);
    });

    controller.local.stream.listen((data) {
      port.postMessage({"data": data});
    }, onDone: () {
      port.postMessage({"event": "done"});
      portSubscription.cancel();
    });
  });

  context['parent'].callMethod('postMessage', [
    JsObject.jsify({"href": window.location.href, "ready": true}),
    window.location.origin,
  ]);
  return controller.foreign;
}

void setStackTraceMapper(StackTraceMapper mapper) {
  var formatter = StackTraceFormatter.current;
  if (formatter == null) {
    throw StateError(
        'setStackTraceMapper() may only be called within a test worker.');
  }

  formatter.configure(mapper: mapper);
}
''');
    }
  }
}

/// A shell builder which generates the web specific entrypoint.
class FlutterWebShellBuilder implements Builder {
  const FlutterWebShellBuilder(this.targets);

  final List<String> targets;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    bool matches = false;
    for (String target in targets) {
      if (buildStep.inputId.path.contains(target)) {
        matches = true;
        break;
      }
    }
    if (!matches) {
      return;
    }
    final AssetId outputId = buildStep.inputId.changeExtension('_web_entrypoint.dart');
    await buildStep.writeAsString(outputId, '''
import 'dart:ui' as ui;
import "${path.url.basename(buildStep.inputId.path)}" as entrypoint;

Future<void> main() async {
  await ui.webOnlyInitializePlatform();
  entrypoint.main();
}

''');
  }

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['_web_entrypoint.dart'],
  };
}

Future<void> bootstrapDart2Js(BuildStep buildStep) async {
  final AssetId dartEntrypointId = buildStep.inputId;
  final AssetId moduleId = dartEntrypointId.changeExtension(moduleExtension(flutterWebPlatform));
  final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));

  final List<Module> allDeps = await module.computeTransitiveDependencies(buildStep, throwIfUnsupported: false)..add(module);
  final ScratchSpace scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  final Iterable<AssetId> allSrcs = allDeps.expand((Module module) => module.sources);
  await scratchSpace.ensureAssets(allSrcs, buildStep);

  final String packageFile = await _createPackageFile(allSrcs, buildStep, scratchSpace);
  final String dartPath = dartEntrypointId.path.startsWith('lib/')
      ? 'package:${dartEntrypointId.package}/'
          '${dartEntrypointId.path.substring('lib/'.length)}'
      : dartEntrypointId.path;
  final String jsOutputPath =
      '${fs.path.withoutExtension(dartPath.replaceFirst('package:', 'packages/'))}'
      '$jsEntrypointExtension';
  final String flutterWebSdkPath = artifacts.getArtifactPath(Artifact.flutterWebSdk);
  final String librariesPath = fs.path.join(flutterWebSdkPath, 'libraries.json');
  final List<String> args = <String>[
    '--libraries-spec="$librariesPath"',
    '-m',
    '-o4',
    '-o',
    '$jsOutputPath',
    '--packages="$packageFile"',
    '-Ddart.vm.product=true',
    dartPath,
  ];
  final Dart2JsBatchWorkerPool dart2js = await buildStep.fetchResource(dart2JsWorkerResource);
  final Dart2JsResult result = await dart2js.compile(args);
  final AssetId jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  final io.File jsOutputFile = scratchSpace.fileFor(jsOutputId);
  if (result.succeeded && jsOutputFile.existsSync()) {
    log.info(result.output);
    // Explicitly write out the original js file and sourcemap.
    await scratchSpace.copyOutput(jsOutputId, buildStep);
    final AssetId jsSourceMapId =
        dartEntrypointId.changeExtension(jsEntrypointSourceMapExtension);
    await _copyIfExists(jsSourceMapId, scratchSpace, buildStep);
  } else {
    log.severe(result.output);
  }
}

Future<void> _copyIfExists(
    AssetId id, ScratchSpace scratchSpace, AssetWriter writer) async {
  final io.File file = scratchSpace.fileFor(id);
  if (file.existsSync()) {
    await scratchSpace.copyOutput(id, writer);
  }
}

/// Creates a `.packages` file unique to this entrypoint at the root of the
/// scratch space and returns it's filename.
///
/// Since mulitple invocations of Dart2Js will share a scratch space and we only
/// know the set of packages involved the current entrypoint we can't construct
/// a `.packages` file that will work for all invocations of Dart2Js so a unique
/// file is created for every entrypoint that is run.
///
/// The filename is based off the MD5 hash of the asset path so that files are
/// unique regarless of situations like `web/foo/bar.dart` vs
/// `web/foo-bar.dart`.
Future<String> _createPackageFile(Iterable<AssetId> inputSources, BuildStep buildStep, ScratchSpace scratchSpace) async {
  final Uri inputUri = buildStep.inputId.uri;
  final String packageFileName =
      '.package-${md5.convert(inputUri.toString().codeUnits)}';
  final io.File packagesFile =
      scratchSpace.fileFor(AssetId(buildStep.inputId.package, packageFileName));
  final Set<String> packageNames = inputSources.map((AssetId s) => s.package).toSet();
  final String packagesFileContent =
      packageNames.map((String name) => '$name:packages/$name/').join('\n');
  await packagesFile
      .writeAsString('# Generated for $inputUri\n$packagesFileContent');
  return packageFileName;
}
