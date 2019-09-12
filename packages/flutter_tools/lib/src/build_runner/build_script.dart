// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:convert'; // ignore: dart_convert_import
import 'dart:io'; // ignore: dart_io_import
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/builders.dart';
import 'package:build_modules/src/module_builder.dart';
import 'package:build_modules/src/platform.dart';
import 'package:build_modules/src/workers.dart';
import 'package:build_runner/build_runner.dart' as build_runner;
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:build_test/builder.dart';
import 'package:build_test/src/debug_test_builder.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/dev_compiler_bootstrap.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path; // ignore: package_path_import
import 'package:scratch_space/scratch_space.dart';
import 'package:test_core/backend.dart';

const String ddcBootstrapExtension = '.dart.bootstrap.js';
const String jsEntrypointExtension = '.dart.js';
const String jsEntrypointSourceMapExtension = '.dart.js.map';
const String jsEntrypointArchiveExtension = '.dart.js.tar.gz';
const String digestsEntrypointExtension = '.digests';
const String jsModuleErrorsExtension = '.ddc.js.errors';
const String jsModuleExtension = '.ddc.js';
const String jsSourceMapExtension = '.ddc.js.map';
const String kReleaseFlag = 'release';
const String kProfileFlag = 'profile';

// A minimum set of libraries to skip checks for to keep the examples compiling
// until we make a decision on whether to support dart:io on the web.
// See https://github.com/dart-lang/sdk/issues/35969
// See https://github.com/flutter/flutter/issues/39998
const Set<String> skipPlatformCheckPackages = <String>{
  'flutter',
  'flutter_test',
  'flutter_driver',
  'flutter_goldens',
  'flutter_goldens_client',
  'flutter_gallery',
  'connectivity',
  'video_player',
};

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
]);

/// The builders required to compile a Flutter application to the web.
final List<core.BuilderApplication> builders = <core.BuilderApplication>[
  core.apply(
    'flutter_tools:test_bootstrap',
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
    'flutter_tools:shell',
    <BuilderFactory>[
      (BuilderOptions options) {
        final bool hasPlugins = options.config['hasPlugins'] == true;
        return FlutterWebShellBuilder(hasPlugins: hasPlugins);
      }
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
      'flutter_tools:module_library',
      <Builder Function(BuilderOptions)>[moduleLibraryBuilder],
      core.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools:module_cleanup']),
  core.apply(
      'flutter_tools:ddc_modules',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions options) => MetaModuleBuilder(flutterWebPlatform),
        (BuilderOptions options) => MetaModuleCleanBuilder(flutterWebPlatform),
        (BuilderOptions options) => ModuleBuilder(flutterWebPlatform),
      ],
      core.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools:module_cleanup']),
  core.apply(
      'flutter_tools:ddc',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions builderOptions) => KernelBuilder(
              platformSdk: builderOptions.config['flutterWebSdk'],
              summaryOnly: true,
              sdkKernelPath: path.join('kernel', 'flutter_ddc_sdk.dill'),
              outputExtension: ddcKernelExtension,
              platform: flutterWebPlatform,
              librariesPath: path.absolute(path.join(builderOptions.config['flutterWebSdk'], 'libraries.json')),
              kernelTargetName: 'ddc',
            ),
        (BuilderOptions builderOptions) => DevCompilerBuilder(
              useIncrementalCompiler: false,
              platform: flutterWebPlatform,
              platformSdk: builderOptions.config['flutterWebSdk'],
              sdkKernelPath: path.url.join('kernel', 'flutter_ddc_sdk.dill'),
              librariesPath: path.absolute(path.join(builderOptions.config['flutterWebSdk'], 'libraries.json')),
            ),
      ],
      core.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools:ddc_modules']),
  core.apply(
    'flutter_tools:entrypoint',
    <BuilderFactory>[
      (BuilderOptions options) => FlutterWebEntrypointBuilder(
          options.config[kReleaseFlag] ?? false,
          options.config[kProfileFlag] ?? false,
          options.config['flutterWebSdk'],
      ),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'lib/**_web_entrypoint.dart',
      ],
    ),
  ),
  core.apply(
    'flutter_tools:test_entrypoint',
    <BuilderFactory>[
      (BuilderOptions options) => const FlutterWebTestEntrypointBuilder(),
    ],
    core.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const InputSet(
      include: <String>[
        'test/**_test.dart.browser_test.dart',
      ],
    ),
  ),
  core.applyPostProcess('flutter_tools:module_cleanup', moduleCleanup,
      defaultGenerateFor: const InputSet())
];

/// The entrypoint to this build script.
Future<void> main(List<String> args, [SendPort sendPort]) async {
  core.overrideGeneratedOutputDirectory('flutter_web');
  final int result = await build_runner.run(args, builders);
  sendPort?.send(result);
}

/// A ddc-only entrypoint builder that respects the Flutter target flag.
class FlutterWebTestEntrypointBuilder implements Builder {
  const FlutterWebTestEntrypointBuilder();

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
    log.info('building for target ${buildStep.inputId.path}');
    await bootstrapDdc(buildStep, platform: flutterWebPlatform,
        skipPlatformCheckPackages: skipPlatformCheckPackages);
  }
}

/// A ddc-only entrypoint builder that respects the Flutter target flag.
class FlutterWebEntrypointBuilder implements Builder {
  const FlutterWebEntrypointBuilder(this.release, this.profile, this.flutterWebSdk);

  final bool release;
  final bool profile;
  final String flutterWebSdk;

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
    if (release || profile) {
      await bootstrapDart2Js(buildStep, flutterWebSdk, profile);
    } else {
      await bootstrapDdc(buildStep, platform: flutterWebPlatform,
          skipPlatformCheckPackages: skipPlatformCheckPackages);
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
  const FlutterWebShellBuilder({this.hasPlugins = false});

  final bool hasPlugins;

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId dartEntrypointId = buildStep.inputId;
    final bool isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) {
      return;
    }
    final AssetId outputId = buildStep.inputId.changeExtension('_web_entrypoint.dart');
    if (hasPlugins) {
      await buildStep.writeAsString(outputId, '''
import 'dart:ui' as ui;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'generated_plugin_registrant.dart';
import "${path.url.basename(buildStep.inputId.path)}" as entrypoint;

Future<void> main() async {
  registerPlugins(webPluginRegistry);
  await ui.webOnlyInitializePlatform();
  entrypoint.main();
}
''');
    } else {
      await buildStep.writeAsString(outputId, '''
import 'dart:ui' as ui;

import "${path.url.basename(buildStep.inputId.path)}" as entrypoint;

Future<void> main() async {
  await ui.webOnlyInitializePlatform();
  entrypoint.main();
}
''');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['_web_entrypoint.dart'],
  };
}

Future<void> bootstrapDart2Js(BuildStep buildStep, String flutterWebSdk, bool profile) async {
  final AssetId dartEntrypointId = buildStep.inputId;
  final AssetId moduleId = dartEntrypointId.changeExtension(moduleExtension(flutterWebPlatform));
  final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));

  final List<Module> allDeps = await module.computeTransitiveDependencies(buildStep, throwIfUnsupported: false)..add(module);
  final ScratchSpace scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  final Iterable<AssetId> allSrcs = allDeps.expand((Module module) => module.sources);
  await scratchSpace.ensureAssets(allSrcs, buildStep);

  final String packageFile = _createPackageFile(allSrcs, buildStep, scratchSpace);
  final String dartPath = dartEntrypointId.path.startsWith('lib/')
      ? 'package:${dartEntrypointId.package}/'
          '${dartEntrypointId.path.substring('lib/'.length)}'
      : dartEntrypointId.path;
  final String jsOutputPath =
      '${path.withoutExtension(dartPath.replaceFirst('package:', 'packages/'))}'
      '$jsEntrypointExtension';
  final String flutterWebSdkPath = flutterWebSdk;
  final String librariesPath = path.join(flutterWebSdkPath, 'libraries.json');
  final List<String> args = <String>[
    '--libraries-spec="$librariesPath"',
    if (profile)
      '-O1'
    else
      '-O4',
    '-o',
    '$jsOutputPath',
    '--packages="$packageFile"',
    if (profile)
      '-Ddart.vm.profile=true'
    else
      '-Ddart.vm.product=true',
    dartPath,
  ];
  final Dart2JsBatchWorkerPool dart2js = await buildStep.fetchResource(dart2JsWorkerResource);
  final Dart2JsResult result = await dart2js.compile(args);
  final AssetId jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  final File jsOutputFile = scratchSpace.fileFor(jsOutputId);
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
  final File file = scratchSpace.fileFor(id);
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
String _createPackageFile(Iterable<AssetId> inputSources, BuildStep buildStep, ScratchSpace scratchSpace) {
  final Uri inputUri = buildStep.inputId.uri;
  final String packageFileName =
      '.package-${md5.convert(inputUri.toString().codeUnits)}';
  final File packagesFile =
      scratchSpace.fileFor(AssetId(buildStep.inputId.package, packageFileName));
  final Set<String> packageNames = inputSources.map((AssetId s) => s.package).toSet();
  final String packagesFileContent =
      packageNames.map((String name) => '$name:packages/$name/').join('\n');
  packagesFile .writeAsStringSync('# Generated for $inputUri\n$packagesFileContent');
  return packageFileName;
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  final ParseStringResult result = parseString(
    content: await reader.readAsString(dartId),
    throwIfDiagnostics: false,
  );
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  return result.unit.declarations.any((CompilationUnitMember node) {
    return node is FunctionDeclaration &&
        node.name.name == 'main' &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}
