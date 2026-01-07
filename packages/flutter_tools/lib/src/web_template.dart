// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/utils.dart';

/// Placeholder for base href
const kBaseHrefPlaceholder = r'$FLUTTER_BASE_HREF';
const kStaticAssetsUrlPlaceholder = r'$FLUTTER_STATIC_ASSETS_URL';

const _kServiceWorkerDeprecationNotice =
    "Flutter's service worker is deprecated and will be removed in a future Flutter release.";

class WebTemplateWarning {
  WebTemplateWarning(this.warningText, this.lineNumber);
  final String warningText;
  final int lineNumber;
}

/// Utility class for parsing and performing operations on the contents of the
/// index.html file.
///
/// For example, to parse the base href from the index.html file:
///
/// ```dart
/// String parseBaseHref(File indexHtmlFile) {
///   final IndexHtml indexHtml = IndexHtml(indexHtmlFile.readAsStringSync());
///   return indexHtml.getBaseHref();
/// }
/// ```
class WebTemplate {
  const WebTemplate(this._content);

  final String _content;

  static String baseHref(String html) {
    final Element? baseElement = parse(html).querySelector('base');
    final String? baseHref = baseElement?.attributes == null
        ? null
        : baseElement!.attributes['href'];

    if (baseHref == null || baseHref == kBaseHrefPlaceholder) {
      return '';
    }

    if (!baseHref.startsWith('/')) {
      throwToolExit(
        'Error: The base href in "web/index.html" must be absolute (i.e. start '
        'with a "/"), but found: `${baseElement!.outerHtml}`.\n'
        '$_kBasePathExample',
      );
    }

    if (!baseHref.endsWith('/')) {
      throwToolExit(
        'Error: The base href in "web/index.html" must end with a "/", but found: `${baseElement!.outerHtml}`.\n'
        '$_kBasePathExample',
      );
    }

    return stripLeadingSlash(stripTrailingSlash(baseHref));
  }

  List<WebTemplateWarning> getWarnings() {
    return <WebTemplateWarning>[
      ..._getWarningsForPattern(
        RegExp('(const|var) serviceWorkerVersion = null'),
        '$_kServiceWorkerDeprecationNotice See https://github.com/flutter/flutter/issues/156910 for more details.',
      ),
      ..._getWarningsForPattern(
        "navigator.serviceWorker.register('flutter_service_worker.js')",
        '$_kServiceWorkerDeprecationNotice See https://github.com/flutter/flutter/issues/156910 for more details.',
      ),
      ..._getWarningsForPattern(
        '_flutter.loader.loadEntrypoint(',
        '"FlutterLoader.loadEntrypoint" is deprecated. Use "FlutterLoader.load" instead. See https://docs.flutter.dev/platform-integration/web/initialization for more details.',
      ),
    ];
  }

  List<WebTemplateWarning> _getWarningsForPattern(Pattern pattern, String warningText) {
    return <WebTemplateWarning>[
      for (final Match match in pattern.allMatches(_content))
        _getWarningForMatch(match, warningText),
    ];
  }

  WebTemplateWarning _getWarningForMatch(Match match, String warningText) {
    final int lineCount = RegExp(
      r'(\r\n|\r|\n)',
    ).allMatches(_content.substring(0, match.start)).length;
    return WebTemplateWarning(warningText, lineCount + 1);
  }

  /// Applies substitutions to the content of the index.html file and returns the result.
  @useResult
  String withSubstitutions({
    required String baseHref,
    required String? serviceWorkerVersion,
    required File flutterJsFile,
    String? buildConfig,
    String? flutterBootstrapJs,
    String? staticAssetsUrl,
    Map<String, String> webDefines = const <String, String>{},
  }) {
    String newContent = _content;

    if (newContent.contains(kBaseHrefPlaceholder)) {
      newContent = newContent.replaceAll(kBaseHrefPlaceholder, baseHref);
    }

    if (newContent.contains(kStaticAssetsUrlPlaceholder) && staticAssetsUrl != null) {
      newContent = newContent.replaceAll(kStaticAssetsUrlPlaceholder, staticAssetsUrl);
    }

    if (serviceWorkerVersion != null) {
      newContent = newContent
          .replaceFirst(
            // Support older `var` syntax as well as new `const` syntax
            RegExp('(const|var) serviceWorkerVersion = null'),
            'const serviceWorkerVersion = "$serviceWorkerVersion" /* $_kServiceWorkerDeprecationNotice */',
          )
          // This is for legacy index.html that still uses the old service
          // worker loading mechanism.
          .replaceFirst(
            "navigator.serviceWorker.register('flutter_service_worker.js')",
            "navigator.serviceWorker.register('flutter_service_worker.js?v=$serviceWorkerVersion') /* $_kServiceWorkerDeprecationNotice */",
          );
    }
    newContent = _applyVariableSubstitutions(newContent, <String, String>{
      ...webDefines,
      if (buildConfig != null) 'flutter_build_config': buildConfig,
      if (flutterBootstrapJs != null) 'flutter_bootstrap_js': flutterBootstrapJs,
      'flutter_js': flutterJsFile.readAsStringSync(),
      'flutter_service_worker_version': serviceWorkerVersion != null
          ? '"$serviceWorkerVersion" /* $_kServiceWorkerDeprecationNotice */'
          : 'null /* $_kServiceWorkerDeprecationNotice */',
    });

    return newContent;
  }

  /// Applies web-define variable substitutions and validates all variables are provided.
  ///
  /// Replaces {{VARIABLE}} placeholders with values from webDefines. Built-in Flutter
  /// variables are preserved if missing; user-defined variables throw ToolExit.
  String _applyVariableSubstitutions(String content, Map<String, String> webDefines) {
    final variablePattern = RegExp(r'\{\{([A-Za-z_][A-Za-z0-9_]*)\}\}');
    final missingVariables = <String>{};

    // Framework-provided variables added by withSubstitutions(). These don't trigger
    // errors if missing, unlike user --web-define variables.
    // - flutter_js: flutter.js loader content (always added)
    // - flutter_build_config: build config JSON (optional, build-mode dependent)
    // - flutter_service_worker_version: SW version hash (optional)
    // - flutter_bootstrap_js: full bootstrap script (optional)
    const builtInVariables = <String>{
      'flutter_js',
      'flutter_build_config',
      'flutter_service_worker_version',
      'flutter_bootstrap_js',
    };

    final String result = content.replaceAllMapped(variablePattern, (Match match) {
      final String variableName = match.group(1)!;
      if (webDefines.containsKey(variableName)) {
        return webDefines[variableName]!;
      }
      // Skip built-in Flutter variables and only validate user-defined web-define variables
      if (!builtInVariables.contains(variableName)) {
        missingVariables.add(variableName);
      }
      // Return the original match for missing variables.
      return match.group(0)!;
    });
    if (missingVariables.isEmpty) {
      return result;
    }

    final String variables = missingVariables.join(', ');
    final String suggestion = missingVariables
        .map((String name) => '--web-define=$name=VALUE')
        .join(' ');
    final String variablesList = pluralize('variable', missingVariables.length);
    throwToolExit(
      'Missing web-define $variablesList: $variables\n\n'
      'Please provide the missing $variablesList using:\n'
      'flutter run $suggestion\n'
      'or\n'
      'flutter build web $suggestion',
    );
  }
}

/// Strips the leading slash from a path.
String stripLeadingSlash(String path) {
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  return path;
}

/// Strips the trailing slash from a path.
String stripTrailingSlash(String path) {
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

const _kBasePathExample = '''
For example, to serve from the root use:

    <base href="/">

To serve from a subpath "foo" (i.e. http://localhost:8080/foo/ instead of http://localhost:8080/) use:

    <base href="/foo/">

For more information, see: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
''';
