// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

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
  @required String requireUrl,
  @required String mapperUrl,
  @required String entrypoint,
}) {
  return '''
"use strict";

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
requireEl.setAttribute("data-main", "main_module");
document.head.appendChild(requireEl);

// Invoked by connected chrome debugger for hot reload/restart support.
window.\$hotReloadHook = function(modules) {
  return new Promise(function(resolve, reject) {
    if (modules == null) {
      reject();
    }
    // If no modules change, return immediately.
    if (modules.length == 0) {
      resolve();
    }
    var reloadCount = 0;
    for (var i = 0; i < modules.length; i++) {
      require.undef(modules[i]);
      require([modules[i]], function(module) {
        reloadCount += 1;
        // once we've reloaded every module, trigger the hot reload.
        if (reloadCount == modules.length) {
          require(["$entrypoint", "dart_sdk"], function(app, dart_sdk) {
            window.\$mainEntrypoint = app.main.main;
            window.\$hotReload(resolve);
          });
        }
      });
    }
  });
}
''';
}

/// Generate a synthetic main module which captures the application's main
/// method.
String generateMainModule({@required String entrypoint}) {
  return '''
// Create the main module loaded below.
define("main_module", ["$entrypoint", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  dart_sdk._debugger.registerDevtoolsFormatter();
  let voidToNull = () => (voidToNull = dart_sdk.dart.constFn(dart_sdk.dart.fnType(dart_sdk.core.Null, [dart_sdk.dart.void])))();

  // Attach the main entrypoint and hot reload functionality to the window.
  window.\$mainEntrypoint = app.main.main;
  if (window.\$hotReload == null) {
    window.\$hotReload = function(cb) {
      dart_sdk.developer.invokeExtension("ext.flutter.disassemble", "{}").then((_) => {
        dart_sdk.dart.hotRestart();
        dart_sdk.ui.webOnlyInitializePlatform().then(dart_sdk.core.Null, dart_sdk.dart.fn(_ => {
          window.\$mainEntrypoint();
          window.requestAnimationFrame(cb);
        }, voidToNull()));
      });
    }
  }

  dart_sdk.ui.webOnlyInitializePlatform().then(dart_sdk.core.Null, dart_sdk.dart.fn(_ => {
    app.main.main();
  }, voidToNull()));
});

// Require JS configuration.
require.config({
  waitSeconds: 0,
});
''';
}
