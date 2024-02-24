// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

String generateDDCBootstrapScript({
  required String entrypoint,
  required String ddcModuleLoaderUrl,
  required String mapperUrl,
  required bool generateLoadingIndicator,
  String appRootDirectory = '/',
}) {
  return '''
${generateLoadingIndicator ? _generateLoadingIndicator() : ""}
// TODO(markzipan): This is safe if Flutter app roots are always equal to the
// host root '/'. Validate if this is true.
var _currentDirectory = "$appRootDirectory";

window.\$dartCreateScript = (function() {
  // Find the nonce value. (Note, this is only computed once.)
  var scripts = Array.from(document.getElementsByTagName("script"));
  var nonce;
  scripts.some(
      script => (nonce = script.nonce || script.getAttribute("nonce")));
  // If present, return a closure that automatically appends the nonce.
  if (nonce) {
    return function() {
      var script = document.createElement("script");
      script.nonce = nonce;
      return script;
    };
  } else {
    return function() {
      return document.createElement("script");
    };
  }
})();

// Loads a module [relativeUrl] relative to [root].
//
// If not specified, [root] defaults to the directory serving the main app.
var forceLoadModule = function (relativeUrl, root) {
  var actualRoot = root ?? _currentDirectory;
  return new Promise(function(resolve, reject) {
    var script = self.\$dartCreateScript();
    let policy = {
      createScriptURL: function(src) {return src;}
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.onload = resolve;
    script.onerror = reject;
    script.src = policy.createScriptURL(actualRoot + relativeUrl);
    document.head.appendChild(script);
  });
};

// A map containing the URLs for the bootstrap scripts in debug.
let _scriptUrls = {
  "mapper": "$mapperUrl",
  "moduleLoader": "$ddcModuleLoaderUrl"
};

(function() {
  let appName = "$entrypoint";

  // A uuid that identifies a subapp.
  // Stubbed out since subapps aren't supported in Flutter.
  let uuid = "00000000-0000-0000-0000-000000000000";

  window.postMessage(
      {type: "DDC_STATE_CHANGE", state: "initial_load", targetUuid: uuid}, "*");

  // Load pre-requisite DDC scripts.
  // We intentionally use invalid names to avoid namespace clashes.
  let prerequisiteScripts = [
    {
      "src": "$ddcModuleLoaderUrl",
      "id": "ddc_module_loader \x00"
    },
    {
      "src": "$mapperUrl",
      "id": "dart_stack_trace_mapper \x00"
    }
  ];

  // Load ddc_module_loader.js to access DDC's module loader API.
  let prerequisiteLoads = [];
  for (let i = 0; i < prerequisiteScripts.length; i++) {
    prerequisiteLoads.push(forceLoadModule(prerequisiteScripts[i].src));
  }
  Promise.all(prerequisiteLoads).then((_) => afterPrerequisiteLogic());

  // Save the current script so we can access it in a closure.
  var _currentScript = document.currentScript;

  var afterPrerequisiteLogic = function() {
    window.\$dartLoader.rootDirectories.push(_currentDirectory);
    let scripts = [
      {
        "src": "dart_sdk.js",
        "id": "dart_sdk"
      },
      {
        "src": "main_module.bootstrap.js",
        "id": "data-main"
      }
    ];
    let loadConfig = new window.\$dartLoader.LoadConfiguration();
    loadConfig.bootstrapScript = scripts[scripts.length - 1];

    loadConfig.loadScriptFn = function(loader) {
      loader.addScriptsToQueue(scripts, null);
      loader.loadEnqueuedModules();
    }
    loadConfig.ddcEventForLoadStart = /* LOAD_ALL_MODULES_START */ 1;
    loadConfig.ddcEventForLoadedOk = /* LOAD_ALL_MODULES_END_OK */ 2;
    loadConfig.ddcEventForLoadedError = /* LOAD_ALL_MODULES_END_ERROR */ 3;

    let loader = new window.\$dartLoader.DDCLoader(loadConfig);

    // Record prerequisite scripts' fully resolved URLs.
    prerequisiteScripts.forEach(script => loader.registerScript(script));

    // Note: these variables should only be used in non-multi-app scenarios since
    // they can be arbitrarily overridden based on multi-app load order.
    window.\$dartLoader.loadConfig = loadConfig;
    window.\$dartLoader.loader = loader;
    loader.nextAttempt();
  }
})();
''';
}

/// The JavaScript bootstrap script to support in-browser hot restart.
///
/// The [requireUrl] loads our cached RequireJS script file. The [mapperUrl]
/// loads the special Dart stack trace mapper. The [entrypoint] is the
/// actual main.dart file.
///
/// This file is served when the browser requests "main.dart.js" in debug mode,
/// and is responsible for bootstrapping the RequireJS modules and attaching
/// the hot reload hooks.
///
/// If `generateLoadingIndicator` is true, embeds a loading indicator onto the
/// web page that's visible while the Flutter app is loading.
String generateBootstrapScript({
  required String requireUrl,
  required String mapperUrl,
  required bool generateLoadingIndicator,
}) {
  return '''
"use strict";

${generateLoadingIndicator ? _generateLoadingIndicator() : ''}

// A map containing the URLs for the bootstrap scripts in debug.
let _scriptUrls = {
  "mapper": "$mapperUrl",
  "requireJs": "$requireUrl"
};

// Create a TrustedTypes policy so we can attach Scripts...
let _ttPolicy;
if (window.trustedTypes) {
  _ttPolicy = trustedTypes.createPolicy("flutter-tools-bootstrap", {
    createScriptURL: (url) => {
      let scriptUrl = _scriptUrls[url];
      if (!scriptUrl) {
        console.error("Unknown Flutter Web bootstrap resource!", url);
      }
      return scriptUrl;
    }
  });
}

// Creates a TrustedScriptURL for a given `scriptName`.
// See `_scriptUrls` and `_ttPolicy` above.
function getTTScriptUrl(scriptName) {
  let defaultUrl = _scriptUrls[scriptName];
  return _ttPolicy ? _ttPolicy.createScriptURL(scriptName) : defaultUrl;
}

// Attach source mapping.
var mapperEl = document.createElement("script");
mapperEl.defer = true;
mapperEl.async = false;
mapperEl.src = getTTScriptUrl("mapper");
document.head.appendChild(mapperEl);

// Attach require JS.
var requireEl = document.createElement("script");
requireEl.defer = true;
requireEl.async = false;
requireEl.src = getTTScriptUrl("requireJs");
// This attribute tells require JS what to load as main (defined below).
requireEl.setAttribute("data-main", "main_module.bootstrap");
document.head.appendChild(requireEl);
''';
}

/// Creates a visual animated loading indicator and puts it on the page to
/// provide feedback to the developer that the app is being loaded. Otherwise,
/// the developer would be staring at a blank page wondering if the app will
/// come up or not.
///
/// This indicator should only be used when DWDS is enabled, e.g. with the
/// `-d chrome` option. Debug builds without DWDS, e.g. `flutter run -d web-server`
/// or `flutter build web --debug` should not use this indicator.
String _generateLoadingIndicator() {
  return '''
var styles = `
  .flutter-loader {
    width: 100%;
    height: 8px;
    background-color: #13B9FD;
    position: absolute;
    top: 0px;
    left: 0px;
    overflow: hidden;
  }

  .indeterminate {
      position: relative;
      width: 100%;
      height: 100%;
  }

  .indeterminate:before {
      content: '';
      position: absolute;
      height: 100%;
      background-color: #0175C2;
      animation: indeterminate_first 2.0s infinite ease-out;
  }

  .indeterminate:after {
      content: '';
      position: absolute;
      height: 100%;
      background-color: #02569B;
      animation: indeterminate_second 2.0s infinite ease-in;
  }

  @keyframes indeterminate_first {
      0% {
          left: -100%;
          width: 100%;
      }
      100% {
          left: 100%;
          width: 10%;
      }
  }

  @keyframes indeterminate_second {
      0% {
          left: -150%;
          width: 100%;
      }
      100% {
          left: 100%;
          width: 10%;
      }
  }
`;

var styleSheet = document.createElement("style")
styleSheet.type = "text/css";
styleSheet.innerText = styles;
document.head.appendChild(styleSheet);

var loader = document.createElement('div');
loader.className = "flutter-loader";
document.body.append(loader);

var indeterminate = document.createElement('div');
indeterminate.className = "indeterminate";
loader.appendChild(indeterminate);

document.addEventListener('dart-app-ready', function (e) {
   loader.parentNode.removeChild(loader);
   styleSheet.parentNode.removeChild(styleSheet);
});
''';
}

String generateDDCMainModule({
  required String entrypoint,
  required bool nullAssertions,
  required bool nativeNullAssertions,
  String? exportedMain,
}) {
  final String entrypointMainName = exportedMain ?? entrypoint.split('.')[0];
  // The typo below in "EXTENTION" is load-bearing, package:build depends on it.
  return '''
/* ENTRYPOINT_EXTENTION_MARKER */

(function() {
  // Flutter Web uses a generated main entrypoint, which shares app and module names.
  let appName = "$entrypoint";
  let moduleName = "$entrypoint";

  // Use a dummy UUID since multi-apps are not supported on Flutter Web.
  let uuid = "00000000-0000-0000-0000-000000000000";

  let child = {};
  child.main = function() {
    let dart = self.dart_library.import('dart_sdk', appName).dart;
    dart.nonNullAsserts($nullAssertions);
    dart.nativeNonNullAsserts($nativeNullAssertions);
    self.dart_library.start(appName, uuid, moduleName, "$entrypointMainName");
  }

  /* MAIN_EXTENSION_MARKER */
  child.main();
})();
''';
}

/// Generate a synthetic main module which captures the application's main
/// method.
///
/// If a [bootstrapModule] name is not provided, defaults to 'main_module.bootstrap'.
///
/// RE: Object.keys usage in app.main:
/// This attaches the main entrypoint and hot reload functionality to the window.
/// The app module will have a single property which contains the actual application
/// code. The property name is based off of the entrypoint that is generated, for example
/// the file `foo/bar/baz.dart` will generate a property named approximately
/// `foo__bar__baz`. Rather than attempt to guess, we assume the first property of
/// this object is the module.
String generateMainModule({
  required String entrypoint,
  required bool nullAssertions,
  required bool nativeNullAssertions,
  String bootstrapModule = 'main_module.bootstrap',
}) {
  // The typo below in "EXTENTION" is load-bearing, package:build depends on it.
  return '''
/* ENTRYPOINT_EXTENTION_MARKER */
// Disable require module timeout
require.config({
  waitSeconds: 0
});
// Create the main module loaded below.
define("$bootstrapModule", ["$entrypoint", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._debugger.registerDevtoolsFormatter();
  dart_sdk.dart.nonNullAsserts($nullAssertions);
  dart_sdk.dart.nativeNonNullAsserts($nativeNullAssertions);

  // See the generateMainModule doc comment.
  var child = {};
  child.main = app[Object.keys(app)[0]].main;

  /* MAIN_EXTENSION_MARKER */
  child.main();

  window.\$dartLoader = {};
  window.\$dartLoader.rootDirectories = [];
  if (window.\$requireLoader) {
    window.\$requireLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  }
  if (window.\$dartStackTraceUtility && !window.\$dartStackTraceUtility.ready) {
    window.\$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.\$dartStackTraceUtility.setSourceMapProvider(function(url) {
      var baseUrl = window.location.protocol + '//' + window.location.host;
      url = url.replace(baseUrl + '/', '');
      if (url == 'dart_sdk.js') {
        return dart.getSourceMap('dart_sdk');
      }
      url = url.replace(".lib.js", "");
      return dart.getSourceMap(url);
    });
  }
  // Prevent DDC's requireJS to interfere with modern bundling.
  if (typeof define === 'function' && define.amd) {
    // Preserve a copy just in case...
    define._amd = define.amd;
    delete define.amd;
  }
});
''';
}

/// Generates the bootstrap logic required for a flutter test running in a browser.
///
/// This hard-codes the device pixel ratio to 3.0 and a 2400 x 1800 window size.
String generateTestEntrypoint({
  required String relativeTestPath,
  required String absolutePath,
  required String? testConfigPath,
  required LanguageVersion languageVersion,
}) {
  return '''
  // @dart = ${languageVersion.major}.${languageVersion.minor}
  import 'org-dartlang-app:///$relativeTestPath' as test;
  import 'dart:ui' as ui;
  import 'dart:ui_web' as ui_web;
  import 'dart:html';
  import 'dart:js';
  ${testConfigPath != null ? "import '${Uri.file(testConfigPath)}' as test_config;" : ""}
  import 'package:stream_channel/stream_channel.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:test_api/backend.dart';

  Future<void> main() async {
    ui_web.debugEmulateFlutterTesterEnvironment = true;
    await ui_web.bootstrapEngine();
    webGoldenComparator = DefaultWebGoldenComparator(Uri.parse('${Uri.file(absolutePath)}'));
    ui_web.debugOverrideDevicePixelRatio(3.0);
    ui.window.debugPhysicalSizeOverride = const ui.Size(2400, 1800);

    internalBootstrapBrowserTest(() {
      return ${testConfigPath != null ? "() => test_config.testExecutable(test.main)" : "test.main"};
    });
  }

  void internalBootstrapBrowserTest(Function getMain()) {
    var channel = serializeSuite(getMain, hidePrints: false);
    postMessageChannel().pipe(channel);
  }

  StreamChannel serializeSuite(Function getMain(), {bool hidePrints = true}) => RemoteListener.start(getMain, hidePrints: hidePrints);

  StreamChannel postMessageChannel() {
    var controller = StreamChannelController<Object?>(sync: true);
    var channel = MessageChannel();
    window.parent!.postMessage('port', window.location.origin, [channel.port2]);

    var portSubscription = channel.port1.onMessage.listen((message) {
      controller.local.sink.add(message.data);
    });
    controller.local.stream
        .listen(channel.port1.postMessage, onDone: portSubscription.cancel);

    return controller.foreign;
  }
  ''';
}

/// Generate the unit test bootstrap file.
String generateTestBootstrapFileContents(
    String mainUri, String requireUrl, String mapperUrl) {
  return '''
(function() {
  if (typeof document != 'undefined') {
    var el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = '$mapperUrl';
    document.head.appendChild(el);

    el = document.createElement("script");
    el.defer = true;
    el.async = false;
    el.src = '$requireUrl';
    el.setAttribute("data-main", '$mainUri');
    document.head.appendChild(el);
  } else {
    importScripts('$mapperUrl', '$requireUrl');
    require.config({
      baseUrl: baseUrl,
    });
    window = self;
    require(['$mainUri']);
  }
})();
''';
}
