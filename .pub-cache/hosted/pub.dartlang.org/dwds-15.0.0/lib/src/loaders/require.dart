// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../debugging/metadata/provider.dart';
import '../loaders/strategy.dart';
import '../readers/asset_reader.dart';
import '../services/expression_compiler.dart';

/// Find the path we are serving from the url.
///
/// Example:
///   https://localhost/base/index.html => base
///   https://localhost/base => base
String basePathForServerUri(String url) {
  final uri = Uri.parse(url);
  var base = uri.path.endsWith('.html') ? p.dirname(uri.path) : uri.path;
  return base = base.startsWith('/') ? base.substring(1) : base;
}

String relativizePath(String path) =>
    path.startsWith('/') ? path.substring(1) : path;

String removeJsExtension(String path) =>
    path.endsWith('.js') ? p.withoutExtension(path) : path;

String addJsExtension(String path) => '$path.js';

// web/main.ddc.js -> main.ddc.js
// packages/test/test.dart.js -> packages/test/test.dart.js
String stripTopLevelDirectory(String path) =>
    path.startsWith('packages') ? path : path.split('/').skip(1).join('/');

/// JavaScript snippet to determine the base URL of the current path.
const _baseUrlScript = '''
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

/// A load strategy for the require-js module system.
class RequireStrategy extends LoadStrategy {
  @override
  final ReloadConfiguration reloadConfiguration;

  final String _requireDigestsPath = r'$requireDigestsPath';

  /// Returns a map of module name to corresponding server path (excluding .js)
  /// for the provided Dart application entrypoint.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc
  ///   packages/path/path -> packages/path/path.ddc
  ///
  final Future<Map<String, String>> Function(MetadataProvider metadataProvider)
      _moduleProvider;

  /// Returns a map of module name to corresponding digest value.
  ///
  /// For example:
  ///
  ///   web/main -> 8363b363f74b41cac955024ab8b94a3f
  ///   packages/path/path -> d348c2a4647e998011fe305f74f22961
  ///
  final Future<Map<String, String>> Function(MetadataProvider metadataProvider)
      _digestsProvider;

  /// Returns the module for the corresponding server path.
  ///
  /// For example:
  ///
  /// /packages/path/path.ddc.js -> packages/path/path
  ///
  final Future<String?> Function(MetadataProvider provider, String sourcePath)
      _moduleForServerPath;

  /// Returns the server path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js
  ///
  final Future<String> Function(MetadataProvider provider, String module)
      _serverPathForModule;

  /// Returns the source map path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js.map
  ///
  final Future<String> Function(MetadataProvider provider, String module)
      _sourceMapPathForModule;

  /// Returns the server path for the app uri.
  ///
  /// For example:
  ///
  ///   org-dartlang-app://web/main.dart -> main.dart
  ///
  /// Will return `null` if the provided uri is not
  /// an app URI.
  final String? Function(String appUri) _serverPathForAppUri;

  /// Returns a map from module id to module info.
  ///
  /// For example:
  ///
  ///   web/main -> {main.ddc.full.dill, main.ddc.dill}
  ///
  final Future<Map<String, ModuleInfo>> Function(
      MetadataProvider metadataProvider) _moduleInfoForProvider;

  RequireStrategy(
    this.reloadConfiguration,
    this._moduleProvider,
    this._digestsProvider,
    this._moduleForServerPath,
    this._serverPathForModule,
    this._sourceMapPathForModule,
    this._serverPathForAppUri,
    this._moduleInfoForProvider,
    AssetReader assetReader,
  ) : super(assetReader);

  @override
  Handler get handler => (request) async {
        if (request.url.path.endsWith(_requireDigestsPath)) {
          final entrypoint = request.url.queryParameters['entrypoint'];
          if (entrypoint == null) return Response.notFound('${request.url}');
          final metadataProvider =
              metadataProviderFor(request.url.queryParameters['entrypoint']!);
          final digests = await _digestsProvider(metadataProvider);
          return Response.ok(json.encode(digests));
        }
        return Response.notFound('${request.url}');
      };

  @override
  String get id => 'require-js';

  @override
  String get moduleFormat => 'amd';

  @override
  String get loadLibrariesModule => 'require.js';

  @override
  String get loadLibrariesSnippet =>
      'let libs = $loadModuleSnippet("dart_sdk").dart.getLibraries();\n';

  @override
  String get loadModuleSnippet => 'require';

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
  String get _requireJsConfig => '''
$_baseUrlScript;
require.config({
    baseUrl: baseUrl,
    waitSeconds: 0,
    paths: modulePaths 
});
const modulesGraph = new Map();
requirejs.onResourceLoad = function (context, map, depArray) {
  const name = map.name;
  const depNameArray = depArray.map((dep) => dep.name);
  if (modulesGraph.has(name)) {
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
      if (!\$requireLoader.moduleParentsGraph.has(depName)) {
        \$requireLoader.moduleParentsGraph.set(depName, []);
      }
      \$requireLoader.moduleParentsGraph.get(depName).push(name);
      modulesGraph.get(name).push(depName);
    }
  }
};
''';

  @override
  Future<String> bootstrapFor(String entrypoint) async =>
      await _requireLoaderSetup(entrypoint) + _requireJsConfig;

  @override
  String loadClientSnippet(String clientScript) =>
      'window.\$requireLoader.forceLoadModule("$clientScript");\n';

  Future<String> _requireLoaderSetup(String entrypoint) async {
    final metadataProvider = metadataProviderFor(entrypoint);
    final modulePaths = await _moduleProvider(metadataProvider);
    final moduleNames =
        modulePaths.map((key, value) => MapEntry<String, String>(value, key));
    return '''
$_baseUrlScript
let modulePaths = ${const JsonEncoder.withIndent(" ").convert(modulePaths)};
let moduleNames = ${const JsonEncoder.withIndent(" ").convert(moduleNames)};
if(!window.\$requireLoader) {
   window.\$requireLoader = {
     digestsPath: '$_requireDigestsPath?entrypoint=$entrypoint',
     // Used in package:build_runner/src/server/build_updates_client/hot_reload_client.dart
     moduleParentsGraph: new Map(),
     forceLoadModule: function (modulePath, callback, onError) {
       let moduleName = moduleNames[modulePath];
       if (moduleName == null) {
         moduleName = modulePath;
       }
       requirejs.undef(moduleName);
       try{
        requirejs([moduleName], function() {
          if (typeof callback != 'undefined') {
            callback();
          }
        });
       } catch (error) {
        if (typeof onError != 'undefined') {
          onError(error);
        }else{
          throw(error);
        }
       }
     },
     getModuleLibraries: null, // set up by _initializeTools
   };
}
''';
  }

  @override
  Future<String?> moduleForServerPath(String entrypoint, String serverPath) {
    final metadataProvider = metadataProviderFor(entrypoint);
    return _moduleForServerPath(metadataProvider, serverPath);
  }

  @override
  Future<String> serverPathForModule(String entrypoint, String module) {
    final metadataProvider = metadataProviderFor(entrypoint);
    return _serverPathForModule(metadataProvider, module);
  }

  @override
  Future<String> sourceMapPathForModule(String entrypoint, String module) {
    final metadataProvider = metadataProviderFor(entrypoint);
    return _sourceMapPathForModule(metadataProvider, module);
  }

  @override
  String? serverPathForAppUri(String appUri) => _serverPathForAppUri(appUri);

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      _moduleInfoForProvider(metadataProviderFor(entrypoint));
}
