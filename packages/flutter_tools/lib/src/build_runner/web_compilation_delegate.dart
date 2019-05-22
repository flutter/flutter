// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

// ignore_for_file: implementation_imports

import 'package:bazel_worker/bazel_worker.dart';
import 'package:bazel_worker/src/driver/driver.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/module_library.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:crypto/crypto.dart';
import 'package:graphs/graphs.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_config/build_config.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';
import 'package:scratch_space/scratch_space.dart';
import 'package:watcher/watcher.dart';
import 'package:build_web_compilers/src/ddc_names.dart';
import 'package:build_modules/src/errors.dart';
import 'package:build_modules/src/module_builder.dart';
import 'package:build_modules/src/module_cache.dart';
import 'package:build_modules/src/modules.dart';
import 'package:build_modules/src/platform.dart';
import 'package:build_modules/src/scratch_space.dart';
import 'package:build_modules/src/workers.dart';


import '../artifacts.dart';
import '../base/logger.dart';
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
final String _modulePartialExtension = path.withoutExtension(jsModuleExtension);
const String multiRootScheme = 'org-dartlang-app';

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

final List<BuilderApplication> builders = <BuilderApplication>[
  apply('flutter_tools|module_library',
      <Builder Function(BuilderOptions)>[moduleLibraryBuilder], toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|module_cleanup']),
  apply(
      'flutter_tools|ddc_modules',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions options) => MetaModuleBuilder(flutterWebPlatform),
        (BuilderOptions options) => MetaModuleCleanBuilder(flutterWebPlatform),
        (BuilderOptions options) => ModuleBuilder(flutterWebPlatform),
      ],
      toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|module_cleanup']),
  apply(
      'flutter_tools|ddc',
      <Builder Function(BuilderOptions)>[
        (BuilderOptions builderOptions) {
          return KernelBuilder(
            platformSdk: artifacts.getArtifactPath(Artifact.flutterWebSdk),
            summaryOnly: true,
            sdkKernelPath: path.join('kernel', 'flutter_ddc_sdk.dill'),
            outputExtension: ddcKernelExtension,
            platform: flutterWebPlatform,
          );
        },
        (BuilderOptions builderOptions) =>
            FlutterDevCompilerBuilder(useIncrementalCompiler: false),
      ],
      toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: <String>['flutter_tools|ddc_modules']),
];
final List<BuilderApplication> postProcessors = <BuilderApplication>[
  applyPostProcess('flutter_tools|module_cleanup', moduleCleanup,
      defaultGenerateFor: const InputSet())
];

class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  PackageGraph _packageGraph;
  BuildImpl _builder;
  PackageUriMapper _packageUriMapper;

  @override
  Future<void> initialize({
    @required Directory projectDirectory,
    @required String target,
  }) async {
    _packageUriMapper = PackageUriMapper(path.absolute(target), PackageMap.globalPackagesPath, null, null);
    _packageGraph = PackageGraph.forPath(projectDirectory.path);
    final BuildEnvironment buildEnvironment =
        OverrideableEnvironment(IOEnvironment(_packageGraph), onLog: (LogRecord record) {
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
    final Status status = logger.startProgress('Compiling to JavaScript...', timeout: null);
    try {
      _builder = await BuildImpl.create(
        buildOptions,
        buildEnvironment,
        <BuilderApplication>[
          ...builders,
          apply(
            'flutter_tools|entrypoint',
            <BuilderFactory>[
              (BuilderOptions options) {
                return FlutterWebEntrypointBuilder(target);
              },
            ],
            toRoot(),
            hideOutput: true,
            defaultGenerateFor: const InputSet(
              include: <String>[
                'lib/**',
                'web/**',
              ],
            ),
          ),
          ...postProcessors
        ],
        const <String, Map<String, dynamic>>{},
        isReleaseBuild: false,
      );
      await _builder.run(const <AssetId, ChangeType>{});
    } finally {
      status.stop();
    }
  }

  @override
  Future<bool> invalidate({@required List<Uri> inputs}) async {
    final Status status = logger.startProgress('Recompiling sources...', timeout: null);
    final Map<AssetId, ChangeType> updates = <AssetId, ChangeType>{};
    for (Uri input in inputs) {
      updates[AssetId.resolve(_packageUriMapper.map(input.toFilePath()).toString())] = ChangeType.MODIFY;
    }
    BuildResult result;
    try {
      result = await _builder.run(updates);
    } finally {
      status.cancel();
    }
    return result.status == BuildStatus.success;
  }
}

class FlutterWebEntrypointBuilder implements Builder {
  const FlutterWebEntrypointBuilder(
    this.target,
  );

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
    await bootstrapDdc(buildStep);
  }
}

final Pool _lazyBuildPool = Pool(16);

Future<void> bootstrapDdc(BuildStep buildStep) async {
  final AssetId dartEntrypointId = buildStep.inputId;
  final AssetId moduleId =
      buildStep.inputId.changeExtension(moduleExtension(flutterWebPlatform));
  final Module module = Module.fromJson(json
      .decode(await buildStep.readAsString(moduleId)) as Map<String, dynamic>);

  // First, ensure all transitive modules are built.
  List<Module> transitiveDeps;
  try {
    transitiveDeps = await _ensureTransitiveModules(module, buildStep);
  } on UnsupportedModules catch (e) {
    final String librariesString = (await e.exactLibraries(buildStep).toList())
        .map((ModuleLibrary lib) => AssetId(lib.id.package,
            lib.id.path.replaceFirst(moduleLibraryExtension, '.dart')))
        .join('\n');
    log.warning('''
Skipping compiling ${buildStep.inputId} with ddc because some of its
transitive libraries have sdk dependencies that not supported on this platform:

$librariesString

https://github.com/dart-lang/build/blob/master/docs/faq.md#how-can-i-resolve-skipped-compiling-warnings
''');
    return;
  }
  final AssetId jsId = module.primarySource.changeExtension(jsModuleExtension);
  final String appModuleName = ddcModuleName(jsId);
  final AssetId appDigestsOutput =
      dartEntrypointId.changeExtension(digestsEntrypointExtension);

  // The name of the entrypoint dart library within the entrypoint JS module.
  final String appModuleScope = toJSIdentifier(
      path.withoutExtension(path.basename(buildStep.inputId.path)));

  // Map from module name to module path for custom modules.
  final SplayTreeMap<String, String> modulePaths =
      SplayTreeMap<String, String>.of(
          <String, String>{'dart_sdk': r'dart_sdk'});
  final List<AssetId> transitiveJsModules = <AssetId>[jsId]
    ..addAll(transitiveDeps.map(
        (Module dep) => dep.primarySource.changeExtension(jsModuleExtension)));
  for (AssetId jsId in transitiveJsModules) {
    // Strip out the top level dir from the path for any module, and set it to
    // `packages/` for lib modules. We set baseUrl to `/` to simplify things,
    // and we only allow you to serve top level directories.
    final String moduleName = ddcModuleName(jsId);
    modulePaths[moduleName] = path.withoutExtension(jsId.path.startsWith('lib')
        ? '$moduleName$jsModuleExtension'
        : path.joinAll(path.split(jsId.path).skip(1)));
  }

  final AssetId bootstrapId =
      dartEntrypointId.changeExtension(ddcBootstrapExtension);
  final String bootstrapModuleName = path.withoutExtension(path
      .relative(bootstrapId.path, from: path.dirname(dartEntrypointId.path)));

  // Strip top-level directory
  final String appModuleSource =
      path.joinAll(path.split(module.primarySource.path).sublist(1));

  final StringBuffer bootstrapContent =
      StringBuffer('$_entrypointExtensionMarker\n(function() {\n')
        ..write(_dartLoaderSetup(
            modulePaths,
            path.relative(appDigestsOutput.path,
                from: path.dirname(bootstrapId.path))))
        ..write(_requireJsConfig)
        ..write(_appBootstrap(bootstrapModuleName, appModuleName,
            appModuleScope, appModuleSource));

  await buildStep.writeAsString(bootstrapId, bootstrapContent.toString());

  final String entrypointJsContent = _entryPointJs(bootstrapModuleName);
  await buildStep.writeAsString(
      dartEntrypointId.changeExtension(jsEntrypointExtension),
      entrypointJsContent);

  // Output the digests for transitive modules.
  // These can be consumed for hot reloads.
  final Map<String, String> moduleDigests = <String, String>{};
  for (Module dep in transitiveDeps.followedBy(<Module>[module])) {
    final AssetId assetId =
        dep.primarySource.changeExtension(jsModuleExtension);
    moduleDigests[
            assetId.path.replaceFirst('lib/', 'packages/${assetId.package}/')] =
        (await buildStep.digest(assetId)).toString();
  }

  await buildStep.writeAsString(appDigestsOutput, jsonEncode(moduleDigests));
}

String ddcModuleName(AssetId jsId) {
  final String jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}

/// A builder which can output ddc modules!
class FlutterDevCompilerBuilder implements Builder {
  FlutterDevCompilerBuilder({bool useIncrementalCompiler})
      : useIncrementalCompiler = useIncrementalCompiler ?? true;

  final bool useIncrementalCompiler;

  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        moduleExtension(flutterWebPlatform): <String>[
          jsModuleExtension,
          jsModuleErrorsExtension,
          jsSourceMapExtension
        ]
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final Module module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    // Entrypoints always have a `.module` file for ease of looking them up,
    // but they might not be the primary source.
    if (module.primarySource
            .changeExtension(moduleExtension(flutterWebPlatform)) !=
        buildStep.inputId) {
      return;
    }

    Future<void> handleError(dynamic error) async {
      await buildStep.writeAsString(
          module.primarySource.changeExtension(jsModuleErrorsExtension),
          '$error');
      log.severe('$error');
    }

    try {
      await _createDevCompilerModule(module, buildStep, useIncrementalCompiler);
    } on Exception catch (e) {
      log.info('$e');
      await handleError(e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future<void> _createDevCompilerModule(
    Module module, BuildStep buildStep, bool useIncrementalCompiler,
    {bool debugMode = true}) async {
  final List<Module> transitiveDeps = await buildStep.trackStage(
      'CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  final Iterable<AssetId> transitiveKernelDeps = transitiveDeps.map(
      (Module module) =>
          module.primarySource.changeExtension(ddcKernelExtension));
  final ScratchSpace scratchSpace =
      await buildStep.fetchResource(scratchSpaceResource);

  final Set<AssetId> allAssetIds = <AssetId>{}
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps);
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  final AssetId jsId = module.primarySource.changeExtension(jsModuleExtension);
  final File jsOutputFile = scratchSpace.fileFor(jsId);
  final String sdkSummary = path.join(
      artifacts.getArtifactPath(Artifact.flutterWebSdk),
      'kernel/flutter_ddc_sdk.dill');

  final WorkRequest request = WorkRequest()
    ..arguments.addAll(<String>[
      '--dart-sdk-summary=$sdkSummary',
      '--modules=amd',
      '--no-summarize',
      '-o',
      jsOutputFile.path,
      debugMode ? '--source-map' : '--no-source-map',
    ])
    ..inputs.add(Input()
      ..path = sdkSummary
      ..digest = <int>[0])
    ..inputs.addAll(await Future.wait(transitiveDeps.map((Module dep) async {
      final AssetId kernelAsset =
          dep.primarySource.changeExtension(ddcKernelExtension);
      return Input()
        ..path = scratchSpace.fileFor(kernelAsset).path
        ..digest = (await buildStep.digest(kernelAsset)).bytes;
    })))
    ..arguments.addAll(transitiveDeps.expand((Module dep) {
      final AssetId kernelAsset =
          dep.primarySource.changeExtension(ddcKernelExtension);
      final String moduleName =
          ddcModuleName(dep.primarySource.changeExtension(jsModuleExtension));
      return <String>[
        '-s',
        '${scratchSpace.fileFor(kernelAsset).path}=$moduleName'
      ];
    }));

  final List<AssetId> allDeps = <AssetId>[]
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps);
  final File packagesFile = await createPackagesFile(allDeps);
  request.arguments.addAll(<String>[
    '--packages',
    packagesFile.absolute.uri.toString(),
    '--module-name',
    ddcModuleName(module.primarySource.changeExtension(jsModuleExtension)),
    '--multi-root-scheme',
    multiRootScheme,
    '--multi-root',
    '.',
    '--track-widget-creation',
    '--inline-source-map',
  ]);

  if (useIncrementalCompiler) {
    request.arguments.addAll(<String>[
      '--reuse-compiler-result',
      '--use-incremental-compiler',
    ]);
  }

  // And finally add all the urls to compile, using the package: path for
  // files under lib and the full absolute path for other files.
  request.arguments.addAll(module.sources.map((AssetId id) {
    final String uri = canonicalUriFor(id);
    if (uri.startsWith('package:')) {
      return uri;
    }
    return '$multiRootScheme:///${id.path}';
  }));

  WorkResponse response;
  try {
    final Resource<BazelWorkerDriver> driverResource = dartdevkDriverResource;
    final BazelWorkerDriver driver =
        await buildStep.fetchResource(driverResource);
    response = await driver.doWork(request,
        trackWork: (Future<WorkResponse> response) =>
            buildStep.trackStage('Compile', () => response, isExternal: true));
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }

  final String message = response.output
      .replaceAll('${scratchSpace.tempDir.path}/', '')
      .replaceAll('$multiRootScheme:///', '');
  if (response.exitCode != EXIT_CODE_OK ||
      !jsOutputFile.existsSync() ||
      message.contains('Error:')) {
    throw Exception('$jsId, $message');
  } else {
    if (message.isNotEmpty) {
      log.info('\n$message');
    }
    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(jsId, buildStep);
    if (debugMode) {
      // We need to modify the sources in the sourcemap to remove the custom
      // `multiRootScheme` that we use.
      final AssetId sourceMapId =
          module.primarySource.changeExtension(jsSourceMapExtension);
      final File file = scratchSpace.fileFor(sourceMapId);
      final String content = await file.readAsString();
      final Map<String, Object> json = jsonDecode(content);
      json['sources'] =
          fixSourceMapSources((json['sources'] as List<dynamic>).cast());
      await buildStep.writeAsString(sourceMapId, jsonEncode(json));
    }
  }
}

/// Copied to `web/stack_trace_mapper.dart`, these need to be kept in sync.
///
/// Given a list of [uris] as [String]s from a sourcemap, fixes them up so that
/// they make sense in a browser context.
///
/// - Strips the scheme from the uri
/// - Strips the top level directory if its not `packages`
List<String> fixSourceMapSources(List<String> uris) {
  return uris.map((String source) {
    final Uri uri = Uri.parse(source);
    final Iterable<String> newSegments = uri.pathSegments.first == 'packages'
        ? uri.pathSegments
        : uri.pathSegments.skip(1);
    return Uri(path: path.joinAll(<String>['/'].followedBy(newSegments)))
        .toString();
  }).toList();
}

/// Ensures that all transitive js modules for [module] are available and built.
///
/// Throws an [UnsupportedModules] exception if there are any
/// unsupported modules.
Future<List<Module>> _ensureTransitiveModules(
    Module module, BuildStep buildStep) async {
  // Collect all the modules this module depends on, plus this module.
  final List<Module> transitiveDeps = await module
      .computeTransitiveDependencies(buildStep, throwIfUnsupported: true);
  final List<AssetId> jsModules = transitiveDeps
      .map((Module module) =>
          module.primarySource.changeExtension(jsModuleExtension))
      .toList()
        ..add(module.primarySource.changeExtension(jsModuleExtension));
  // Check that each module is readable, and warn otherwise.
  await Future.wait(jsModules.map((AssetId jsId) async {
    if (await _lazyBuildPool.withResource(() => buildStep.canRead(jsId))) {
      return;
    }
    final AssetId errorsId = jsId.addExtension('.errors');
    await buildStep.canRead(errorsId);
    log.warning('Unable to read $jsId, check your console or the '
        '`.dart_tool/build/generated/${errorsId.package}/${errorsId.path}` '
        'log file.');
  }));
  return transitiveDeps;
}

/// The actual entrypoint JS file which injects all the necessary scripts to
/// run the app.
String _entryPointJs(String bootstrapModuleName) => '''
(function() {
  $_currentDirectoryScript
  $_baseUrlScript

  var mapperUri = baseUrl + "packages/build_web_compilers/src/" +
      "dev_compiler_stack_trace/stack_trace_mapper.dart.js";
  var requireUri = 'https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js';
  var mainUri = _currentDirectory + "$bootstrapModuleName";

  if (typeof document != 'undefined') {
    var el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = mapperUri;
    document.head.appendChild(el);

    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = requireUri;
    el.setAttribute("data-main", mainUri);
    document.head.appendChild(el);
  } else {
    importScripts(mapperUri, requireUri);
    require.config({
      baseUrl: baseUrl,
    });
    // TODO: update bootstrap code to take argument - dart-lang/build#1115
    window = self;
    require([mainUri + '.js']);
  }
})();
''';

/// JavaScript snippet to determine the directory a script was run from.
const String _currentDirectoryScript = r'''
var _currentDirectory = (function () {
  var _url;
  var lines = new Error().stack.split('\n');
  function lookupUrl() {
    if (lines.length > 2) {
      var match = lines[1].match(/^\s+at (.+):\d+:\d+$/);
      // Chrome.
      if (match) return match[1];
      // Chrome nested eval case.
      match = lines[1].match(/^\s+at eval [(](.+):\d+:\d+[)]$/);
      if (match) return match[1];
      // Edge.
      match = lines[1].match(/^\s+at.+\((.+):\d+:\d+\)$/);
      if (match) return match[1];
      // Firefox.
      match = lines[0].match(/[<][@](.+):\d+:\d+$/)
      if (match) return match[1];
    }
    // Safari.
    return lines[0].match(/(.+):\d+:\d+$/)[1];
  }
  _url = lookupUrl();
  var lastSlash = _url.lastIndexOf('/');
  if (lastSlash == -1) return _url;
  var currentDirectory = _url.substring(0, lastSlash + 1);
  return currentDirectory;
})();
''';

/// Sets up `window.$dartLoader` based on [modulePaths].
String _dartLoaderSetup(Map<String, String> modulePaths, String appDigests) =>
    '''
$_baseUrlScript
let modulePaths = ${const JsonEncoder.withIndent(" ").convert(modulePaths)};
if(!window.\$dartLoader) {
   window.\$dartLoader = {
     appDigests: '$appDigests',
     moduleIdToUrl: new Map(),
     urlToModuleId: new Map(),
     rootDirectories: new Array(),
     // Used in package:build_runner/src/server/build_updates_client/hot_reload_client.dart
     moduleParentsGraph: new Map(),
     moduleLoadingErrorCallbacks: new Map(),
     forceLoadModule: function (moduleName, callback, onError) {
       // dartdevc only strips the final extension when adding modules to source
       // maps, so we need to do the same.
       if (moduleName.endsWith('$_modulePartialExtension')) {
         moduleName = moduleName.substring(0, moduleName.length - ${_modulePartialExtension.length});
       }
       if (typeof onError != 'undefined') {
         var errorCallbacks = \$dartLoader.moduleLoadingErrorCallbacks;
         if (!errorCallbacks.has(moduleName)) {
           errorCallbacks.set(moduleName, new Set());
         }
         errorCallbacks.get(moduleName).add(onError);
       }
       requirejs.undef(moduleName);
       requirejs([moduleName], function() {
         if (typeof onError != 'undefined') {
           errorCallbacks.get(moduleName).delete(onError);
         }
         if (typeof callback != 'undefined') {
           callback();
         }
       });
     },
     getModuleLibraries: null, // set up by _initializeTools
   };
}
let customModulePaths = {};
window.\$dartLoader.rootDirectories.push(window.location.origin + baseUrl);
for (let moduleName of Object.getOwnPropertyNames(modulePaths)) {
  let modulePath = modulePaths[moduleName];
  if (modulePath != moduleName) {
    customModulePaths[moduleName] = modulePath;
  }
  var src = window.location.origin + '/' + modulePath + '.js';
  if (window.\$dartLoader.moduleIdToUrl.has(moduleName)) {
    continue;
  }
  \$dartLoader.moduleIdToUrl.set(moduleName, src);
  \$dartLoader.urlToModuleId.set(src, moduleName);
}
''';

/// Code to initialize the dev tools formatter, stack trace mapper, and any
/// other tools.
///
/// Posts a message to the window when done.
const String _initializeTools = '''
$_baseUrlScript
  dart_sdk._debugger.registerDevtoolsFormatter();
  \$dartLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  if (window.\$dartStackTraceUtility && !window.\$dartStackTraceUtility.ready) {
    window.\$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.\$dartStackTraceUtility.setSourceMapProvider(
      function(url) {
        url = url.replace(baseUrl, '/');
        var module = window.\$dartLoader.urlToModuleId.get(url);
        if (!module) return null;
        return dart.getSourceMap(module);
      });
  }
  if (typeof document != 'undefined') {
    window.postMessage({ type: "DDC_STATE_CHANGE", state: "start" }, "*");
  }
''';

/// Require JS config for ddc.
///
/// Sets the base url to `/` so that all modules can be loaded using absolute
/// paths which simplifies a lot of scenarios.
///
/// Sets the timeout for loading modules to infinity (0).
///
/// Sets up the custom module paths.
///
/// Adds error handler code for require.js which requests a `.errors` file for
/// any failed module, and logs it to the console.
final String _requireJsConfig = '''
// Whenever we fail to load a JS module, try to request the corresponding
// `.errors` file, and log it to the console.
(function() {
  var oldOnError = requirejs.onError;
  requirejs.onError = function(e) {
    if (e.requireModules) {
      if (e.message) {
        // If error occurred on loading dependencies, we need to invalidate ancessor too.
        var ancesor = e.message.match(/needed by: (.*)/);
        if (ancesor) {
          e.requireModules.push(ancesor[1]);
        }
      }
      for (const module of e.requireModules) {
        var errorCallbacks = \$dartLoader.moduleLoadingErrorCallbacks.get(module);
        if (errorCallbacks) {
          for (const callback of errorCallbacks) callback(e);
          errorCallbacks.clear();
        }
      }
    }
    if (e.originalError && e.originalError.srcElement) {
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
          var message;
          if (this.status == 200) {
            message = this.responseText;
          } else {
            message = "Unknown error loading " + e.originalError.srcElement.src;
          }
          console.error(message);
          var errorEvent = new CustomEvent(
            'dartLoadException', { detail: message });
          window.dispatchEvent(errorEvent);
        }
      };
      xhr.open("GET", e.originalError.srcElement.src + ".errors", true);
      xhr.send();
    }
    // Also handle errors the normal way.
    if (oldOnError) oldOnError(e);
  };
}());

$_baseUrlScript;

require.config({
    baseUrl: baseUrl,
    waitSeconds: 0,
    paths: customModulePaths
});

const modulesGraph = new Map();
function getRegisteredModuleName(moduleMap) {
  if (\$dartLoader.moduleIdToUrl.has(moduleMap.name + '$_modulePartialExtension')) {
    return moduleMap.name + '$_modulePartialExtension';
  }
  return moduleMap.name;
}
requirejs.onResourceLoad = function (context, map, depArray) {
  const name = getRegisteredModuleName(map);
  const depNameArray = depArray.map(getRegisteredModuleName);
  if (modulesGraph.has(name)) {
    // TODO Move this logic to better place
    var previousDeps = modulesGraph.get(name);
    var changed = previousDeps.length != depNameArray.length;
    changed = changed || depNameArray.some(function(depName) {
      return !previousDeps.includes(depName);
    });
    if (changed) {
      console.warn("Dependencies graph change for module '" + name + "' detected. " +
        "Dependencies was [" + previousDeps + "], now [" +  depNameArray.map((depName) => depName) +"]. " +
        "Page can't be hot-reloaded, firing full page reload.");
      window.location.reload();
    }
  } else {
    modulesGraph.set(name, []);
    for (const depName of depNameArray) {
      if (!\$dartLoader.moduleParentsGraph.has(depName)) {
        \$dartLoader.moduleParentsGraph.set(depName, []);
      }
      \$dartLoader.moduleParentsGraph.get(depName).push(name);
      modulesGraph.get(name).push(depName);
    }
  }
};
''';

/// Marker comment used by tools to identify the entrypoint file,
/// to inject custom code.
const String _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

/// Marker comment used by tools to identify the main function
/// to inject custom code.
const String _mainExtensionMarker = '/* MAIN_EXTENSION_MARKER */';

const String _baseUrlScript = '''
var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());
''';

/// Code that actually imports the [moduleName] module, and calls the
/// `[moduleScope].main()` function on it.
///
/// Also performs other necessary initialization.
String _appBootstrap(String bootstrapModuleName, String moduleName,
        String moduleScope, String appModuleSource) =>
    '''
define("$bootstrapModuleName", ["$moduleName", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  $_initializeTools
  $_mainExtensionMarker
  app.$moduleScope.main();
  var bootstrap = {
      hot\$onChildUpdate: function(childName, child) {
        if (childName === "$appModuleSource") {
          // Clear static caches.
          dart_sdk.dart.hotRestart();
          child.main();
          return true;
        }
      }
    }
  dart_sdk.dart.trackLibraries("$bootstrapModuleName", {
    "$bootstrapModuleName": bootstrap
  }, '');
  return {
    bootstrap: bootstrap
  };
});
})();
''';

Future<File> createPackagesFile(Iterable<AssetId> allAssets) async {
  final Set<String> allPackages =
      allAssets.map((AssetId id) => id.package).toSet();
  final Directory packagesFileDir =
      await Directory.systemTemp.createTemp('kernel_builder_');
  final File packagesFile = File(path.join(packagesFileDir.path, '.packages'));
  await packagesFile.create();
  await packagesFile.writeAsString(allPackages
      .map((String pkg) => '$pkg:$multiRootScheme:///packages/$pkg')
      .join('\r\n'));
  return packagesFile;
}

/// A builder which can output kernel files for a given sdk.
///
/// This creates kernel files based on [moduleExtension] files, which are what
/// determine the module structure of an application.
class KernelBuilder implements Builder {
  KernelBuilder(
      {@required this.platform,
      @required this.summaryOnly,
      @required this.sdkKernelPath,
      @required this.outputExtension,
      bool useIncrementalCompiler,
      @required this.platformSdk})
      : useIncrementalCompiler = useIncrementalCompiler ?? false,
        buildExtensions = <String, List<String>>{
          moduleExtension(platform): <String>[outputExtension]
        };

  @override
  final Map<String, List<String>> buildExtensions;

  final bool useIncrementalCompiler;

  final String outputExtension;

  final DartPlatform platform;

  /// Whether this should create summary kernel files or full kernel files.
  ///
  /// Summary files only contain the "outline" of the module - you can think of
  /// this as everything but the method bodies.
  final bool summaryOnly;

  /// The sdk kernel file for the current platform.
  final String sdkKernelPath;

  /// The root directory of the platform's dart SDK.
  ///
  /// If not provided, defaults to the directory of
  /// [Platform.resolvedExecutable].
  ///
  /// On flutter this is the path to the root of the flutter_patched_sdk
  /// directory, which contains the platform kernel files.
  final String platformSdk;

  @override
  Future<void> build(BuildStep buildStep) async {
    final Module module = Module.fromJson(
        json.decode(await buildStep.readAsString(buildStep.inputId))
            as Map<String, dynamic>);
    try {
      await _createKernel(
          module: module,
          buildStep: buildStep,
          summaryOnly: summaryOnly,
          outputExtension: outputExtension,
          platform: platform,
          dartSdkDir: platformSdk,
          sdkKernelPath: sdkKernelPath,
          useIncrementalCompiler: useIncrementalCompiler);
    } on Exception catch (e) {
      log.severe(e.toString());
    }
  }
}

/// Creates a kernel file for [module].
Future<void> _createKernel(
    {@required Module module,
    @required BuildStep buildStep,
    @required bool summaryOnly,
    @required String outputExtension,
    @required DartPlatform platform,
    @required String dartSdkDir,
    @required String sdkKernelPath,
    @required bool useIncrementalCompiler}) async {
  final WorkRequest request = WorkRequest();
  final ScratchSpace scratchSpace =
      await buildStep.fetchResource(scratchSpaceResource);
  final AssetId outputId =
      module.primarySource.changeExtension(outputExtension);
  final File outputFile = scratchSpace.fileFor(outputId);

  File packagesFile;

  await buildStep.trackStage('CollectDeps', () async {
    final List<AssetId> kernelDeps = <AssetId>[];
    final List<AssetId> sourceDeps = <AssetId>[];

    await _findModuleDeps(
        module, kernelDeps, sourceDeps, buildStep, outputExtension);

    final Set<AssetId> allAssetIds = <AssetId>{}
      ..addAll(module.sources)
      ..addAll(kernelDeps)
      ..addAll(sourceDeps);
    await scratchSpace.ensureAssets(allAssetIds, buildStep);

    packagesFile = await createPackagesFile(allAssetIds);

    await _addRequestArguments(
        request,
        module,
        kernelDeps,
        platform,
        dartSdkDir,
        sdkKernelPath,
        outputFile,
        packagesFile,
        summaryOnly,
        useIncrementalCompiler,
        buildStep);
  });

  // We need to make sure and clean up the temp dir, even if we fail to compile.
  try {
    final BazelWorkerDriver frontendWorker =
        await buildStep.fetchResource(frontendDriverResource);
    final WorkResponse response = await frontendWorker.doWork(request,
        trackWork: (Future<WorkResponse> response) => buildStep
            .trackStage('Kernel Generate', () => response, isExternal: true));
    if (response.exitCode != EXIT_CODE_OK || !outputFile.existsSync()) {
      throw Exception(
          '$outputId, ${request.arguments.join(' ')}\n${response.output}');
    }

    if (response.output?.isEmpty == false) {
      log.info(response.output);
    }

    // Copy the output back using the buildStep.
    await scratchSpace.copyOutput(outputId, buildStep);
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }
}

/// Finds the transitive dependencies of [root] and categorizes them as
/// [kernelDeps] or [sourceDeps].
///
/// A module will have it's kernel file in [kernelDeps] if it and all of it's
/// transitive dependencies have readable kernel files. If any module has no
/// readable kernel file then it, and all of it's dependents will be categorized
/// as [sourceDeps] which will have all of their [Module.sources].
Future<void> _findModuleDeps(
    Module root,
    List<AssetId> kernelDeps,
    List<AssetId> sourceDeps,
    BuildStep buildStep,
    String outputExtension) async {
  final List<Module> resolvedModules =
      await _resolveTransitiveModules(root, buildStep);
  final Set<AssetId> sourceOnly = await _parentsOfMissingKernelFiles(
      resolvedModules, buildStep, outputExtension);

  for (Module module in resolvedModules) {
    if (sourceOnly.contains(module.primarySource)) {
      sourceDeps.addAll(module.sources);
    } else {
      kernelDeps.add(module.primarySource.changeExtension(outputExtension));
    }
  }
}

/// The transitive dependencies of [root], not including [root] itself.
Future<List<Module>> _resolveTransitiveModules(
    Module root, BuildStep buildStep) async {
  final Set<AssetId> missing = <AssetId>{};
  final Module root2 = root;
  final List<Module> modules = await crawlAsync<AssetId, Module>(
          <AssetId>[root2.primarySource],
          (AssetId id) => buildStep
                  .fetchResource(moduleCache)
                  .then((DecodingCache<Module> c) async {
                final AssetId moduleId =
                    id.changeExtension(moduleExtension(root.platform));
                final Module module = await c.find(moduleId, buildStep);
                if (module == null) {
                  missing.add(moduleId);
                } else if (module.isMissing) {
                  missing.add(module.primarySource);
                }
                return module;
              }),
          (AssetId id, Module module) => module.directDependencies)
      .skip(1) // Skip the root.
      .toList();

  if (missing.isNotEmpty) {
    throw await MissingModulesException.create(
        missing, modules.toList()..add(root), buildStep);
  }

  return modules;
}

/// Finds the primary source of all transitive parents of any module which does
/// not have a readable kernel file.
///
/// Inverts the direction of the graph and then crawls to all reachables nodes
/// from the modules which do not have a readable kernel file
Future<Set<AssetId>> _parentsOfMissingKernelFiles(
    List<Module> modules, BuildStep buildStep, String outputExtension) async {
  final Set<AssetId> sourceOnly = <AssetId>{};
  final Map<AssetId, Set<AssetId>> parents = <AssetId, Set<AssetId>>{};
  for (Module module in modules) {
    for (AssetId dep in module.directDependencies) {
      parents.putIfAbsent(dep, () => <AssetId>{}).add(module.primarySource);
    }
    if (!await buildStep
        .canRead(module.primarySource.changeExtension(outputExtension))) {
      sourceOnly.add(module.primarySource);
    }
  }
  final Queue<AssetId> toCrawl = Queue<AssetId>.of(sourceOnly);
  while (toCrawl.isNotEmpty) {
    final AssetId current = toCrawl.removeFirst();
    if (!parents.containsKey(current)) {
      continue;
    }
    for (AssetId next in parents[current]) {
      if (!sourceOnly.add(next)) {
        toCrawl.add(next);
      }
    }
  }
  return sourceOnly;
}

/// Fills in all the required arguments for [request] in order to compile the
/// kernel file for [module].
Future<void> _addRequestArguments(
    WorkRequest request,
    Module module,
    Iterable<AssetId> transitiveKernelDeps,
    DartPlatform platform,
    String argumentSdkDir,
    String sdkKernelPath,
    File outputFile,
    File packagesFile,
    bool summaryOnly,
    bool useIncrementalCompiler,
    AssetReader reader) async {
  request.arguments.addAll(<String>[
    '--dart-sdk-summary',
    Uri.file(path.join(argumentSdkDir, sdkKernelPath)).toString(),
    '--output',
    outputFile.path,
    '--packages-file',
    packagesFile.uri.toString(),
    '--multi-root-scheme',
    multiRootScheme,
    '--exclude-non-sources',
    summaryOnly ? '--summary-only' : '--no-summary-only',
    '--libraries-file',
    path.toUri(path.join(argumentSdkDir, 'libraries.json')).toString(),
  ]);
  if (useIncrementalCompiler) {
    request.arguments.addAll(<String>[
      '--reuse-compiler-result',
      '--use-incremental-compiler',
    ]);
  }

  request.inputs.add(Input()
    ..path = '${Uri.file(path.join(argumentSdkDir, sdkKernelPath))}'
    // Sdk updates fully invalidate the build anyways.
    ..digest = md5.convert(utf8.encode(platform.name)).bytes);

  // Add all kernel outlines as summary inputs, with digests.
  final List<Input> inputs =
      await Future.wait(transitiveKernelDeps.map((AssetId id) async {
    final String relativePath = path.url.relative(
        scratchSpace.fileFor(id).uri.path,
        from: scratchSpace.tempDir.uri.path);

    return Input()
      ..path = '$multiRootScheme:///$relativePath'
      ..digest = (await reader.digest(id)).bytes;
  }));
  request.arguments.addAll(inputs.map(
      (Input i) => '--input-${summaryOnly ? 'summary' : 'linked'}=${i.path}'));
  request.inputs.addAll(inputs);

  request.arguments.addAll(module.sources.map((AssetId id) {
    final String uri = id.path.startsWith('lib')
        ? canonicalUriFor(id)
        : '$multiRootScheme:///${id.path}';
    return '--source=$uri';
  }));
}
