// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// The JavaScript bootstrap script to support in-browser hot restart.
///
/// The [requireUrl] loads our cached RequireJS script file. The [mapperUrl]
/// loads the special Dart stack trace mapper. [mainModule] is the name of the
/// actual main.dart module that needs to be loaded by the bootsrap script.
///
/// This file is served when the browser requests "main.dart.js" in debug mode,
/// and is responsible for bootstraping the RequireJS modules and attaching
/// the hot reload hooks.
String generateBootstrapScript({
  @required String requireUrl,
  @required String mapperUrl,
  @required String mainModule,
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
  if (modules == null) {
    return;
  }
  // If no modules change, only invoke main.
  if (modules.length == 0) {
    window.\$hotReload();
  }
  var reloadCount = 0;
  for (var i = 0; i < modules.length; i++) {
    require.undef(modules[i]);
  }
  for (var i = 0; i < modules.length; i++) {
    require([modules[i]], function(module) {
      reloadCount += 1;
      if (reloadCount == modules.length) {
        window.\$hotReload();
      }
    });
  }
}

// Create the main module loaded below.
define("main_module", ["$mainModule", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  dart_sdk._debugger.registerDevtoolsFormatter();

  // Attach the main entrypoint and hot reload functionality to the window.
  window.\$mainEntrypoint = app.main;
  if (window.\$hotReload == null) {
    window.\$hotReload = function() {
      dart_sdk.developer.invokeExtension('ext.flutter.disassemble', {});
      dart_sdk.dart.hotRestart();
      window.\$mainEntrypoint();
    }
  }
  app.main();
});

// Require JS configuration.
require.config({
  waitSeconds: 0,
});
''';
}
