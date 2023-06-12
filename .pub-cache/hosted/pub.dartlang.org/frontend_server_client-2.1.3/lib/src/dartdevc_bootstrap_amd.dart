// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The JavaScript bootstrap script to support in-browser hot restart.
///
/// The [requireUrl] loads our cached RequireJS script file. The [mapperUrl]
/// loads the special Dart stack trace mapper.
///
/// This file is served when the browser requests `$entrypoint.js` in debug
/// mode, and is responsible for bootstrapping the RequireJS modules and
/// attaching the hot reload hooks.
String generateAmdBootstrapScript({
  required String requireUrl,
  required String mapperUrl,
  required String entrypoint,
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
requireEl.setAttribute("data-main", "$entrypoint.bootstrap");
document.head.appendChild(requireEl);
''';
}

/// Generate a synthetic main module which captures the application's main
/// method.
///
/// RE: Object.keys usage in app.main:
/// This attaches the main entrypoint and hot reload functionality to the window.
/// The app module will have a single property which contains the actual application
/// code. The property name is based off of the entrypoint that is generated, for example
/// the file `foo/bar/baz.dart` will generate a property named approximately
/// `foo__bar__baz`. Rather than attempt to guess, we assume the first property of
/// this object is the module.
String generateAmdMainModule({required String entrypoint}) {
  return '''/* ENTRYPOINT_EXTENTION_MARKER */
// Create the main module loaded below.
require(["$entrypoint.lib.js", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._debugger.registerDevtoolsFormatter();

  // See the generateMainModule doc comment.
  app[Object.keys(app)[0]].main();
});
''';
}
