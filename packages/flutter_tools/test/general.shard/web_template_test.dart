// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/web_template.dart';

import '../src/common.dart';

const String htmlSample1 = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="/foo/222/">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script src="main.dart.js"></script>
</body>
</html>
''';

const String htmlSample2 = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="$kBaseHrefPlaceholder">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script src="main.dart.js"></script>
  <script>
    const serviceWorkerVersion = null;
  </script>
  <script>
    navigator.serviceWorker.register('flutter_service_worker.js');
  </script>
</body>
</html>
''';

const String htmlSampleInlineFlutterJsBootstrap = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="/foo/222/">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script>
    {{flutter_js}}
    {{flutter_build_config}}
    _flutter.loader.load({
      serviceWorker: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
    });
  </script>
</body>
</html>
''';

const String htmlSampleInlineFlutterJsBootstrapOutput = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="/foo/222/">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script>
    (flutter.js content)
    (build config)
    _flutter.loader.load({
      serviceWorker: {
        serviceWorkerVersion: "(service worker version)",
      },
    });
  </script>
</body>
</html>
''';

const String htmlSampleFullFlutterBootstrapReplacement = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="/foo/222/">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script>
    {{flutter_bootstrap_js}}
  </script>
</body>
</html>
''';

const String htmlSampleFullFlutterBootstrapReplacementOutput = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="/foo/222/">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script>
    (flutter bootstrap script)
  </script>
</body>
</html>
''';

const String htmlSampleLegacyVar = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="$kBaseHrefPlaceholder">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script src="main.dart.js"></script>
  <script>
    var serviceWorkerVersion = null;
  </script>
  <script>
    navigator.serviceWorker.register('flutter_service_worker.js');
  </script>
</body>
</html>
''';

const String htmlSampleLegacyLoadEntrypoint = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="$kBaseHrefPlaceholder">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <script src="flutter.js" defer></script>
</head>
<body>
  <div></div>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            appRunner.runApp();
          });
      });
    });
  </script>
</body>
</html>
''';

String htmlSample2Replaced({required String baseHref, required String serviceWorkerVersion}) => '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <base href="$baseHref">
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script src="main.dart.js"></script>
  <script>
    const serviceWorkerVersion = "$serviceWorkerVersion";
  </script>
  <script>
    navigator.serviceWorker.register('flutter_service_worker.js?v=$serviceWorkerVersion');
  </script>
</body>
</html>
''';

const String htmlSample3 = '''
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <meta charset="utf-8">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <div></div>
  <script src="main.dart.js"></script>
</body>
</html>
''';

void main() {
  final MemoryFileSystem fs = MemoryFileSystem();
  final File flutterJs = fs.file('flutter.js');
  flutterJs.writeAsStringSync('(flutter.js content)');

  test('can parse baseHref', () {
    expect(WebTemplate.baseHref('<base href="/foo/111/">'), 'foo/111');
    expect(WebTemplate.baseHref(htmlSample1), 'foo/222');
    expect(WebTemplate.baseHref(htmlSample2), ''); // Placeholder base href.
  });

  test('handles missing baseHref', () {
    expect(WebTemplate.baseHref(''), '');
    expect(WebTemplate.baseHref('<base>'), '');
    expect(WebTemplate.baseHref(htmlSample3), '');
  });

  test('throws on invalid baseHref', () {
    expect(() => WebTemplate.baseHref('<base href>'), throwsToolExit());
    expect(() => WebTemplate.baseHref('<base href="">'), throwsToolExit());
    expect(() => WebTemplate.baseHref('<base href="foo/111">'), throwsToolExit());
    expect(() => WebTemplate.baseHref('<base href="foo/111/">'), throwsToolExit());
    expect(() => WebTemplate.baseHref('<base href="/foo/111">'), throwsToolExit());
  });

  test('applies substitutions', () {
    const WebTemplate indexHtml = WebTemplate(htmlSample2);

    expect(
      indexHtml.withSubstitutions(
        baseHref: '/foo/333/',
        serviceWorkerVersion: 'v123xyz',
        flutterJsFile: flutterJs,
      ),
      htmlSample2Replaced(baseHref: '/foo/333/', serviceWorkerVersion: 'v123xyz'),
    );
  });

  test('applies substitutions with legacy var version syntax', () {
    const WebTemplate indexHtml = WebTemplate(htmlSampleLegacyVar);
    expect(
      indexHtml.withSubstitutions(
        baseHref: '/foo/333/',
        serviceWorkerVersion: 'v123xyz',
        flutterJsFile: flutterJs,
      ),
      htmlSample2Replaced(baseHref: '/foo/333/', serviceWorkerVersion: 'v123xyz'),
    );
  });

  test('applies substitutions to inline flutter.js bootstrap script', () {
    const WebTemplate indexHtml = WebTemplate(htmlSampleInlineFlutterJsBootstrap);
    expect(indexHtml.getWarnings(), isEmpty);

    expect(
      indexHtml.withSubstitutions(
        baseHref: '/',
        serviceWorkerVersion: '(service worker version)',
        flutterJsFile: flutterJs,
        buildConfig: '(build config)',
      ),
      htmlSampleInlineFlutterJsBootstrapOutput,
    );
  });

  test('applies substitutions to full flutter_bootstrap.js replacement', () {
    const WebTemplate indexHtml = WebTemplate(htmlSampleFullFlutterBootstrapReplacement);
    expect(indexHtml.getWarnings(), isEmpty);

    expect(
      indexHtml.withSubstitutions(
        baseHref: '/',
        serviceWorkerVersion: '(service worker version)',
        flutterJsFile: flutterJs,
        buildConfig: '(build config)',
        flutterBootstrapJs: '(flutter bootstrap script)',
      ),
      htmlSampleFullFlutterBootstrapReplacementOutput,
    );
  });

  test('re-parses after substitutions', () {
    const WebTemplate indexHtml = WebTemplate(htmlSample2);
    expect(WebTemplate.baseHref(htmlSample2), ''); // Placeholder base href.

    final String substituted = indexHtml.withSubstitutions(
      baseHref: '/foo/333/',
      serviceWorkerVersion: 'v123xyz',
      flutterJsFile: flutterJs,
    );
    // The parsed base href should be updated after substitutions.
    expect(WebTemplate.baseHref(substituted), 'foo/333');
  });

  test('warns on legacy service worker patterns', () {
    const WebTemplate indexHtml = WebTemplate(htmlSampleLegacyVar);
    final List<WebTemplateWarning> warnings = indexHtml.getWarnings();
    expect(warnings.length, 2);

    expect(warnings.where((WebTemplateWarning warning) => warning.lineNumber == 13), isNotEmpty);
    expect(warnings.where((WebTemplateWarning warning) => warning.lineNumber == 16), isNotEmpty);
  });

  test('warns on legacy FlutterLoader.loadEntrypoint', () {
    const WebTemplate indexHtml = WebTemplate(htmlSampleLegacyLoadEntrypoint);
    final List<WebTemplateWarning> warnings = indexHtml.getWarnings();

    expect(warnings.length, 1);
    expect(warnings.single.lineNumber, 14);
  });
}
