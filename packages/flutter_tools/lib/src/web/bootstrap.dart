// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

/// The JavaScript bootstrap script to support in-browser hot restart.
///
/// The [requireUrl] loads our cached RequireJS script file. The [mapperUrl]
/// loads the special Dart stack trace mapper. The [entrypoint] is the
/// actual main.dart file.
///
/// This file is served when the browser requests "main.dart.js" in debug mode,
/// and is responsible for bootstrapping the RequireJS modules and attaching
/// the hot reload hooks.
String generateBootstrapScript({
  required String requireUrl,
  required String mapperUrl,
}) {
  return '''
"use strict";

var styles = `
  .flutter-loader {
    width: 100%;
    height: 8px;
    background-color: #13B9FD;
    position: absolute;
    top: 0px;
    left: 0px;
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

// Attach source mapping.
var mapperEl = document.createElement("script");
mapperEl.defer = true;
mapperEl.async = false;
mapperEl.src = "$mapperUrl";
document.head.appendChild(mapperEl);

// Attach require JS.
var requireEl = document.createElement("script");
requireEl.defer = true;
requireEl.async = false;
requireEl.src = "$requireUrl";
// This attribute tells require JS what to load as main (defined below).
requireEl.setAttribute("data-main", "main_module.bootstrap");
document.head.appendChild(requireEl);
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
  return '''
/* ENTRYPOINT_EXTENTION_MARKER */
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
  import 'dart:html';
  import 'dart:js';
  ${testConfigPath != null ? "import '${Uri.file(testConfigPath)}' as test_config;" : ""}
  import 'package:stream_channel/stream_channel.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:test_api/src/backend/stack_trace_formatter.dart'; // ignore: implementation_imports
  import 'package:test_api/src/remote_listener.dart'; // ignore: implementation_imports
  import 'package:test_api/src/backend/suite_channel_manager.dart'; // ignore: implementation_imports

  Future<void> main() async {
    ui.debugEmulateFlutterTesterEnvironment = true;
    await ui.webOnlyInitializePlatform();
    webGoldenComparator = DefaultWebGoldenComparator(Uri.parse('${Uri.file(absolutePath)}'));
    (ui.window as dynamic).debugOverrideDevicePixelRatio(3.0);
    (ui.window as dynamic).webOnlyDebugPhysicalSizeOverride = const ui.Size(2400, 1800);

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
