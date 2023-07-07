// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../loaders/strategy.dart';
import 'sdk_configuration.dart';

/// The URI for a particular Dart file, able to canonicalize from various
/// different representations.
class DartUri {
  DartUri._(this.serverPath);

  /// Accepts various forms of URI and can convert between forms.
  ///
  /// The accepted forms are:
  ///
  ///  - package:packageName/pathUnderLib/file.dart
  ///  - org-dartlang-app:///prefix/path/file.dart, where prefix is ignored.
  ///    e.g. org-dartlang-app:example/hello_world/main.dart,
  ///  - /packages/packageName/foo.dart, the web server form of a package URI,
  ///    e.g. /packages/path/src/utils.dart
  ///  - /path/foo.dart or path/foo.dart, e.g. /hello_world/web/main.dart, where
  ///    path is a web server path and so relative to the directory being
  ///    served, not to the package.
  ///
  /// The optional [root] is the directory the app is served from.
  factory DartUri(String uri, [String? root]) {
    final serverPath = globalLoadStrategy.serverPathForAppUri(uri);
    if (serverPath != null) {
      return DartUri._(serverPath);
    }
    // TODO(annagrin): Support creating DartUris from `dart:` uris.
    // Issue: https://github.com/dart-lang/webdev/issues/1584
    if (uri.startsWith('package:')) {
      return DartUri._fromPackageUri(uri, root: root);
    }
    if (uri.startsWith('file:')) {
      return DartUri._fromFileUri(uri, root: root);
    }
    if (uri.startsWith('/packages/')) {
      return DartUri._fromRelativePath(uri, root: root);
    }
    if (uri.startsWith('/')) {
      return DartUri._fromRelativePath(uri);
    }
    if (uri.startsWith('http:') || uri.startsWith('https:')) {
      return DartUri(Uri.parse(uri).path);
    }

    throw FormatException('Unsupported URI form', uri);
  }

  @override
  String toString() => 'DartUri: $serverPath';

  /// Construct from a package: URI
  factory DartUri._fromPackageUri(String uri, {String? root}) {
    final packagePath = 'packages/${uri.substring("package:".length)}';
    if (root != null) {
      final relativePath = p.url.join(root, packagePath);
      return DartUri._fromRelativePath(relativePath);
    }
    return DartUri._(packagePath);
  }

  /// Construct from a file: URI
  factory DartUri._fromFileUri(String uri, {String? root}) {
    final libraryName = _resolvedUriToUri[uri];
    if (libraryName != null) return DartUri(libraryName, root);
    // This is not one of our recorded libraries.
    throw ArgumentError.value(uri, 'uri', 'Unknown library');
  }

  /// Construct from a path, relative to the directory being served.
  factory DartUri._fromRelativePath(String uri, {String? root}) {
    uri = uri[0] == '.' ? uri.substring(1) : uri;
    uri = uri[0] == '/' ? uri.substring(1) : uri;

    if (root != null) {
      return DartUri._fromRelativePath(p.url.join(root, uri));
    }
    return DartUri._(uri);
  }

  /// The canonical web server path part of the URI.
  ///
  /// This is a relative path, which can be used to fetch the corresponding file
  /// from the server. For example, 'hello_world/main.dart' or
  /// 'packages/path/src/utils.dart'.
  final String serverPath;

  static final _logger = Logger('DartUri');

  /// The way we resolve file: URLs into package: URLs
  static PackageConfig? _packageConfig;

  /// All of the known absolute library paths, indexed by their library URL.
  ///
  /// Examples:
  ///
  /// We are assuming that all library uris are coming from
  /// https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#getscripts)
  /// and can be translated to their absolute paths and back.
  ///
  /// dart:html <->
  ///   org-dartlang-sdk:///sdk/lib/html/html.dart
  /// (not supported, issue: https://github.com/dart-lang/webdev/issues/1457)
  ///
  /// org-dartlang-app:///example/hello_world/main.dart <->
  ///   file:///source/webdev/fixtures/_test/example/hello_world/main.dart,
  ///
  /// org-dartlang-app:///example/hello_world/part.dart <->
  ///   file:///source/webdev/fixtures/_test/example/hello_world/part.dart,
  ///
  /// package:path/path.dart <->
  ///   file:///.pub-cache/hosted/pub.dartlang.org/path-1.8.0/lib/path.dart,
  ///
  /// package:path/src/path_set.dart <->
  ///   file:///.pub-cache/hosted/pub.dartlang.org/path-1.8.0/lib/src/path_set.dart,
  static final Map<String, String> _uriToResolvedUri = {};

  /// All of the known libraries, indexed by their absolute file URL.
  static final Map<String, String> _resolvedUriToUri = {};

  /// Returns package, app, or dart uri for a resolved path.
  static String? toPackageUri(String uri) => _resolvedUriToUri[uri];

  /// Returns resolved path for a package, app, or dart uri.
  static String? toResolvedUri(String uri) => _uriToResolvedUri[uri];

  /// The directory in which we're running.
  ///
  /// We store this here because for tests we may want to act as if we're
  /// running in the directory of a target package, even if the current
  /// directory of the tests is actually the main dwds directory.
  static String currentDirectory = p.current;

  /// The current directory as a file: Uri, saved here to avoid re-computing.
  static String currentDirectoryUri = '${p.toUri(currentDirectory)}';

  /// Record library and script uris to enable resolving library and script paths.
  static Future<void> initialize(SdkConfiguration sdkConfiguration) async {
    final packagesUri =
        p.toUri(p.join(currentDirectory, '.dart_tool/package_config.json'));

    clear();

    // Allow for tests to supply empty configurations.
    if (sdkConfiguration.sdkDirectory != null) {
      sdkConfiguration.validateSdkDir();
    }

    await _loadPackageConfig(packagesUri);
  }

  /// Clear the uri resolution tables.
  static void clear() {
    _packageConfig = null;
    _resolvedUriToUri.clear();
    _uriToResolvedUri.clear();
  }

  /// Record all of the libraries, indexed by their absolute file: URI.
  static Future<void> recordAbsoluteUris(Iterable<String> libraryUris) async {
    for (var uri in libraryUris) {
      _recordAbsoluteUri(uri);
    }
  }

  /// Load the .dart_tool/package_config.json file associated with the running
  /// application so we can resolve file URLs into package: URLs appropriately.
  static Future<void> _loadPackageConfig(Uri uri) async {
    _packageConfig = await loadPackageConfigUri(uri, onError: (e) {
      _logger.warning('Cannot read packages spec: $uri', e);
    });
  }

  /// Record the library represented by package: or org-dartlang-app: uris
  /// indexed by absolute file: URI.
  static void _recordAbsoluteUri(String libraryUri) {
    final uri = Uri.parse(libraryUri);
    if (uri.scheme.isEmpty && !uri.path.endsWith('.dart')) {
      // ignore non-dart files
      return;
    }

    String? libraryPath;
    switch (uri.scheme) {
      case 'dart':
        // TODO(annagrin): Support resolving `dart:` uris.
        // Issue: https://github.com/dart-lang/webdev/issues/1584
        return;
      case 'org-dartlang-app':
      case 'google3':
        // Both currentDirectoryUri and the libraryUri path should have '/'
        // separators, so we can join them as url paths to get the absolute file
        // url.
        libraryPath = p.url.join(currentDirectoryUri, uri.path.substring(1));
        break;
      case 'package':
        libraryPath = _packageConfig?.resolve(uri)?.toString();
        break;
      default:
        throw ArgumentError.value(libraryUri, 'URI scheme not allowed');
    }

    if (libraryPath != null) {
      _uriToResolvedUri[libraryUri] = libraryPath;
      _resolvedUriToUri[libraryPath] = libraryUri;
    } else {
      _logger.fine('Unresolved uri: $uri');
    }
  }
}
