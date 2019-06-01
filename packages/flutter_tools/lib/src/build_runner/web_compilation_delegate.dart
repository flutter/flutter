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
import 'package:build_test/builder.dart';
import 'package:build_test/src/debug_test_builder.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/dev_compiler_bootstrap.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test_core/backend.dart';
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
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
          options.config['targets'] ?? <String>['lib/main.dart']),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'lib/**',
        'web/**',
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
  Future<void> initialize({
    @required Directory projectDirectory,
    @required List<String> targets,
    String testOutputDir,
  }) async {
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
    try {
      _builder = await BuildImpl.create(
        buildOptions,
        buildEnvironment,
        builders,
        <String, Map<String, dynamic>>{
          'flutter_tools|entrypoint': <String, dynamic>{
            'targets': targets,
          }
        },
        isReleaseBuild: false,
      );
      await _builder.run(const <AssetId, ChangeType>{}, buildDirs: buildDirs);
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
  const FlutterWebEntrypointBuilder(this.targets);

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
  await ui.webOnlyTestSetup();
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

void setStackTraceMap
per(StackTraceMapper mapper) {
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

