// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains a bunch of different index.html "styles" that can be written
// by Flutter Web users.
// This should be somewhat kept in sync with the different index.html files present
// in `flutter/dev/integration_tests/web/web`.
// @see https://github.com/flutter/flutter/tree/main/dev/integration_tests/web/web

/// index_with_flutterjs_entrypoint_loaded.html
String indexHtmlFlutterJsCallback = _generateFlutterJsIndexHtml('''
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint({
        onEntrypointLoaded: onEntrypointLoaded,
      });
      // Once the entrypoint is ready, do things!
      async function onEntrypointLoaded(engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine();
        appRunner.runApp();
      }
    });
''');

/// index_with_flutterjs_short.html
String indexHtmlFlutterJsPromisesShort = _generateFlutterJsIndexHtml('''
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint().then(function(engineInitializer) {
        return engineInitializer.autoStart();
      });
    });
''');

/// index_with_flutterjs.html
String indexHtmlFlutterJsPromisesFull = _generateFlutterJsIndexHtml('''
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint().then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
''');

/// index_with_flutterjs.html
String indexHtmlFlutterJsLoad = _generateFlutterJsIndexHtml('''
    window.addEventListener('load', function(ev) {
      _flutter.buildConfig = {
        builds: [
          {
            "compileTarget": "dartdevc",
            "renderer": "canvaskit",
            "mainJsPath": "main.dart.js",
          }
        ]
      };
      // Download main.dart.js
      _flutter.loader.load();
    });
''');

/// index_without_flutterjs.html
var indexHtmlNoFlutterJs = '''
<!DOCTYPE HTML>
<!-- Copyright 2014 The Flutter Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->
<html>
<head>
  <meta charset="UTF-8">

  <title>Web Test</title>
  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Web Test">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
''';

// Generates the scaffolding of an index.html file, with a configurable `initScript`.
String _generateFlutterJsIndexHtml(String initScript) =>
    '''
<!DOCTYPE HTML>
<!-- Copyright 2014 The Flutter Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->
<html>
<head>
  <meta charset="UTF-8">

  <title>Integration test. App load with flutter.js and onEntrypointLoaded API</title>
  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Web Test">
  <link rel="manifest" href="manifest.json">
  <!-- This script adds the flutter initialization JS code -->
  <script src="flutter.js" defer></script>
</head>
<body>
  <script>
$initScript
  </script>
</body>
</html>
''';

/// index.html using flutter bootstrap script
const indexHtmlWithFlutterBootstrapScriptTag = '''
<!DOCTYPE HTML>
<!-- Copyright 2014 The Flutter Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->
<html>
<head>
  <meta charset="UTF-8">

  <title>Web Test</title>
  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Web Test">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';

/// index.html using flutter bootstrap script
const indexHtmlWithInlinedFlutterBootstrapScript = '''
<!DOCTYPE HTML>
<!-- Copyright 2014 The Flutter Authors. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->
<html>
<head>
  <meta charset="UTF-8">

  <title>Web Test</title>
  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Web Test">
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script>
    {{flutter_bootstrap_js}}
  </script>
</body>
</html>
''';
