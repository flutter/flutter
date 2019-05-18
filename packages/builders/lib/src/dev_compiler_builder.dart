// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:bazel_worker/driver.dart';
import 'package:build_modules/build_modules.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:scratch_space/scratch_space.dart';

const String ddcKernelExtension = '.ddc.dill';
const String jsModuleErrorsExtension = '.ddc.js.errors';
const String jsModuleExtension = '.ddc.js';
const String jsSourceMapExtension = '.ddc.js.map';

p.Context get _context => p.url;

var _modulePartialExtension = _context.withoutExtension(jsModuleExtension);


/// A builder which can output ddc modules
class DevCompilerBuilder implements Builder {
  DevCompilerBuilder(this.sdkDir);

  final String sdkDir;

  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
    moduleExtension(flutterDdcPlatform): <String>[
      jsModuleExtension,
      jsModuleErrorsExtension,
      jsSourceMapExtension
    ]
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final Map<String, dynamic> result = json.decode(await buildStep.readAsString(buildStep.inputId));
    final Module module = Module.fromJson(result);

    Future<void> handleError(dynamic error) async {
      await buildStep.writeAsString(
          module.primarySource.changeExtension(jsModuleErrorsExtension), '$error');
      log.severe('$error');
    }

    try {
      await _createDevCompilerModule(module, buildStep, sdkDir);
    } catch (e) {
      await handleError(e);
    }
  }
}

/// Compile [module] with the dev compiler.
Future<void> _createDevCompilerModule(
   Module module, BuildStep buildStep, String sdkDir, {bool debugMode = true}) async {
  final List<Module> transitiveDeps = await buildStep.trackStage('CollectTransitiveDeps',
      () => module.computeTransitiveDependencies(buildStep));
  final Iterable<AssetId> transitiveKernelDeps = transitiveDeps.map(
      (Module module) => module.primarySource.changeExtension(ddcKernelExtension));
  final ScratchSpace scratchSpace = await buildStep.fetchResource(scratchSpaceResource);

  final Set<AssetId> allAssetIds = <AssetId>{}
    ..addAll(module.sources)
    ..addAll(transitiveKernelDeps);
  await buildStep.trackStage(
      'EnsureAssets', () => scratchSpace.ensureAssets(allAssetIds, buildStep));
  final AssetId jsId = module.primarySource.changeExtension(jsModuleExtension);
  final File jsOutputFile = scratchSpace.fileFor(jsId);
  final String sdkSummary = p.url.join(sdkDir, 'lib/_internal/ddc_sdk.dill');

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
      final AssetId kernelAsset = dep.primarySource.changeExtension(ddcKernelExtension);
      return Input()
        ..path = scratchSpace.fileFor(kernelAsset).path
        ..digest = (await buildStep.digest(kernelAsset)).bytes;
    })))
    ..arguments.addAll(transitiveDeps.expand((Module dep) {
      final AssetId kernelAsset = dep.primarySource.changeExtension(ddcKernelExtension);
      final String moduleName =
          ddcModuleName(dep.primarySource.changeExtension(jsModuleExtension));
      return <String>['-s', '${scratchSpace.fileFor(kernelAsset).path}=$moduleName'];
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

  request.arguments.addAll(<String>[
    '--reuse-compiler-result',
    '--use-incremental-compiler',
  ]);

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
    final BazelWorkerDriver driver = await buildStep.fetchResource(driverResource);
    response = await driver.doWork(request,
        trackWork: (Future<WorkResponse> response) =>
            buildStep.trackStage('Compile', () => response, isExternal: true));
  } finally {
    await packagesFile.parent.delete(recursive: true);
  }

  // TODO(jakemac53): Fix the ddc worker mode so it always sends back a bad
  // status code if something failed. Today we just make sure there is an output
  // JS file to verify it was successful.
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
      final AssetId sourceMapId = module.primarySource.changeExtension(jsSourceMapExtension);
      final File file = scratchSpace.fileFor(sourceMapId);
      final String content = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(content);
      json['sources'] = fixSourceMapSources(json['sources'].cast());
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
    return Uri(path: p.url.joinAll(<String>['/'].followedBy(newSegments))).toString();
  }).toList();
}

/// The module name according to ddc for [jsId] which represents the real js
/// module file.
String ddcModuleName(AssetId jsId) {
  final String jsPath = jsId.path.startsWith('lib/')
      ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
      : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}

/// The compiler configuration for a flutter web application.
final DartPlatform flutterDdcPlatform = DartPlatform.register('flutter_ddc', <String>[
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
  '_engine',
  'ui',
]);

Future<File> createPackagesFile(Iterable<AssetId> allAssets) async {
  final Set<String> allPackages = allAssets.map((AssetId id) => id.package).toSet();
  final Directory packagesFileDir = await Directory.systemTemp.createTemp('kernel_builder_');
  final File packagesFile = File(p.join(packagesFileDir.path, '.packages'));
  await packagesFile.create();
  await packagesFile.writeAsString(allPackages
    .map((String pkg) => '$pkg:$multiRootScheme:///packages/$pkg')
    .join('\r\n'));
  return packagesFile;
}

const ddcBootstrapExtension = '.dart.bootstrap.js';
const jsEntrypointExtension = '.dart.js';
const jsEntrypointSourceMapExtension = '.dart.js.map';
const jsEntrypointArchiveExtension = '.dart.js.tar.gz';
const digestsEntrypointExtension = '.digests';

/// Which compiler to use when compiling web entrypoints.
enum WebCompiler {
  Dart2Js,
  DartDevc,
}

/// The top level keys supported for the `options` config for the
/// [WebEntrypointBuilder].
const _supportedOptions = [
  _compiler,
  _dart2jsArgs,
];

const _compiler = 'compiler';
const _dart2jsArgs = 'dart2js_args';

/// The deprecated keys for the `options` config for the [WebEntrypointBuilder].
const _deprecatedOptions = [
  'enable_sync_async',
  'ignore_cast_failures',
];

/// A builder which compiles entrypoints for the web.
///
/// Supports `dart2js` and `dartdevc`.
class WebEntrypointBuilder implements Builder {
  final WebCompiler webCompiler;
  final List<String> dart2JsArgs;

  const WebEntrypointBuilder(this.webCompiler, {this.dart2JsArgs = const []});

  factory WebEntrypointBuilder.fromOptions(BuilderOptions options) {
    var compilerOption = options.config[_compiler] as String ?? 'dartdevc';
    WebCompiler compiler;
    switch (compilerOption) {
      case 'dartdevc':
        compiler = WebCompiler.DartDevc;
        break;
      case 'dart2js':
        compiler = WebCompiler.Dart2Js;
        break;
      default:
        throw ArgumentError.value(compilerOption, _compiler,
            'Only `dartdevc` and `dart2js` are supported.');
    }

    var dart2JsArgs =
        options.config[_dart2jsArgs]?.cast<String>() ?? const <String>[];
    if (dart2JsArgs is! List<String>) {
      throw ArgumentError.value(dart2JsArgs, _dart2jsArgs,
          'Expected a list of strings, but got a ${dart2JsArgs.runtimeType}:');
    }

    return WebEntrypointBuilder(compiler,
        dart2JsArgs: dart2JsArgs as List<String>);
  }

  @override
  final buildExtensions = const {
    '.dart': [
      ddcBootstrapExtension,
      jsEntrypointExtension,
      jsEntrypointSourceMapExtension,
      jsEntrypointArchiveExtension,
      digestsEntrypointExtension,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var dartEntrypointId = buildStep.inputId;
    var isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) return;
    if (webCompiler == WebCompiler.DartDevc) {
      try {
        await bootstrapDdc(buildStep);
      } on MissingModulesException catch (e) {
        log.severe('$e');
      }
    }
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  var parsed = parseCompilationUnit(await reader.readAsString(dartId),
      suppressErrors: true);
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO: This misses the case where a Dart file doesn't contain main(),
  // but has a part that does, or it exports a `main` from another library.
  return parsed.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == 'main' &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}


Future<void> bootstrapDdc(BuildStep buildStep) async {
  var dartEntrypointId = buildStep.inputId;
  var moduleId =
      buildStep.inputId.changeExtension(moduleExtension(flutterDdcPlatform));
  var module = Module.fromJson(json
      .decode(await buildStep.readAsString(moduleId)) as Map<String, dynamic>);

  // First, ensure all transitive modules are built.
  List<Module> transitiveDeps;
  try {
    transitiveDeps = await _ensureTransitiveModules(module, buildStep);
  } on UnsupportedModules catch (e) {
    var librariesString = (await e.exactLibraries(buildStep).toList())
        .map((lib) => AssetId(lib.id.package,
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
  var jsId = module.primarySource.changeExtension(jsModuleExtension);
  var appModuleName = ddcModuleName(jsId);
  var appDigestsOutput =
      dartEntrypointId.changeExtension(digestsEntrypointExtension);

  // The name of the entrypoint dart library within the entrypoint JS module.
  //
  // This is used to invoke `main()` from within the bootstrap script.
  //
  // TODO(jakemac53): Sane module name creation, this only works in the most
  // basic of cases.
  //
  // See https://github.com/dart-lang/sdk/issues/27262 for the root issue
  // which will allow us to not rely on the naming schemes that dartdevc uses
  // internally, but instead specify our own.
  var appModuleScope = toJSIdentifier(() {
    var basename = _context.basename(jsId.path);
    return basename.substring(0, basename.length - jsModuleExtension.length);
  }());

  // Map from module name to module path for custom modules.
  var modulePaths = SplayTreeMap.of(
      {'dart_sdk': r'packages/build_web_compilers/src/dev_compiler/dart_sdk'});
  var transitiveJsModules = [jsId]..addAll(transitiveDeps
      .map((dep) => dep.primarySource.changeExtension(jsModuleExtension)));
  for (var jsId in transitiveJsModules) {
    // Strip out the top level dir from the path for any module, and set it to
    // `packages/` for lib modules. We set baseUrl to `/` to simplify things,
    // and we only allow you to serve top level directories.
    var moduleName = ddcModuleName(jsId);
    modulePaths[moduleName] = _context.withoutExtension(
        jsId.path.startsWith('lib')
            ? '$moduleName$jsModuleExtension'
            : _context.joinAll(_context.split(jsId.path).skip(1)));
  }

  var bootstrapId = dartEntrypointId.changeExtension(ddcBootstrapExtension);
  var bootstrapModuleName = _context.withoutExtension(_context.relative(
      bootstrapId.path,
      from: _context.dirname(dartEntrypointId.path)));

  // Strip top-level directory
  var appModuleSource =
      _context.joinAll(_context.split(module.primarySource.path).sublist(1));

  var bootstrapContent =
      StringBuffer('$_entrypointExtensionMarker\n(function() {\n')
        ..write(_dartLoaderSetup(
            modulePaths,
            p.url.relative(appDigestsOutput.path,
                from: p.url.dirname(bootstrapId.path))))
        ..write(_requireJsConfig)
        ..write(_appBootstrap(bootstrapModuleName, appModuleName,
            appModuleScope, appModuleSource));

  await buildStep.writeAsString(bootstrapId, bootstrapContent.toString());

  var entrypointJsContent = _entryPointJs(bootstrapModuleName);
  await buildStep.writeAsString(
      dartEntrypointId.changeExtension(jsEntrypointExtension),
      entrypointJsContent);

  // Output the digests for transitive modules.
  // These can be consumed for hot reloads.
  var moduleDigests = <String, String>{};
  for (var dep in transitiveDeps.followedBy([module])) {
    var assetId = dep.primarySource.changeExtension(jsModuleExtension);
    moduleDigests[
            assetId.path.replaceFirst('lib/', 'packages/${assetId.package}/')] =
        (await buildStep.digest(assetId)).toString();
  }

  await buildStep.writeAsString(appDigestsOutput, jsonEncode(moduleDigests));
}

final _lazyBuildPool = Pool(16);

/// Ensures that all transitive js modules for [module] are available and built.
///
/// Throws an [UnsupportedModules] exception if there are any
/// unsupported modules.
Future<List<Module>> _ensureTransitiveModules(
    Module module, BuildStep buildStep) async {
  // Collect all the modules this module depends on, plus this module.
  var transitiveDeps = await module.computeTransitiveDependencies(buildStep,
      throwIfUnsupported: true);
  var jsModules = transitiveDeps
      .map((module) => module.primarySource.changeExtension(jsModuleExtension))
      .toList()
        ..add(module.primarySource.changeExtension(jsModuleExtension));
  // Check that each module is readable, and warn otherwise.
  await Future.wait(jsModules.map((jsId) async {
    if (await _lazyBuildPool.withResource(() => buildStep.canRead(jsId))) {
      return;
    }
    var errorsId = jsId.addExtension('.errors');
    await buildStep.canRead(errorsId);
    log.warning('Unable to read $jsId, check your console or the '
        '`.dart_tool/build/generated/${errorsId.package}/${errorsId.path}` '
        'log file.');
  }));
  return transitiveDeps;
}

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

/// The actual entrypoint JS file which injects all the necessary scripts to
/// run the app.
String _entryPointJs(String bootstrapModuleName) => '''
(function() {
  $_currentDirectoryScript
  $_baseUrlScript
  var mapperUri = baseUrl + "packages/build_web_compilers/src/" +
      "dev_compiler_stack_trace/stack_trace_mapper.dart.js";
  var requireUri = baseUrl +
      "packages/build_web_compilers/src/dev_compiler/require.js";
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
final _currentDirectoryScript = r'''
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
final _initializeTools = '''
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
final _requireJsConfig = '''
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
final _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

/// Marker comment used by tools to identify the main function
/// to inject custom code.
final _mainExtensionMarker = '/* MAIN_EXTENSION_MARKER */';

final _baseUrlScript = '''
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

String toJSIdentifier(String name) {
  if (name.isEmpty) return r'$';

  // Escape any invalid characters
  StringBuffer buffer;
  for (var i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

/// Returns true for invalid JS variable names, such as keywords.
/// Also handles invalid variable names in strict mode, like "arguments".
bool invalidVariableName(String keyword, {bool strictMode = true}) {
  switch (keyword) {
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    case 'await':
    case 'break':
    case 'case':
    case 'catch':
    case 'class':
    case 'const':
    case 'continue':
    case 'debugger':
    case 'default':
    case 'delete':
    case 'do':
    case 'else':
    case 'enum':
    case 'export':
    case 'extends':
    case 'finally':
    case 'for':
    case 'function':
    case 'if':
    case 'import':
    case 'in':
    case 'instanceof':
    case 'let':
    case 'new':
    case 'return':
    case 'super':
    case 'switch':
    case 'this':
    case 'throw':
    case 'try':
    case 'typeof':
    case 'var':
    case 'void':
    case 'while':
    case 'with':
      return true;
    case 'arguments':
    case 'eval':
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    // http://www.ecma-international.org/ecma-262/6.0/#sec-identifiers-static-semantics-early-errors
    case 'implements':
    case 'interface':
    case 'package':
    case 'private':
    case 'protected':
    case 'public':
    case 'static':
    case 'yield':
      return strictMode;
  }
  return false;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = RegExp(r'[^A-Za-z_$0-9]');
