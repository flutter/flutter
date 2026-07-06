// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;
import 'package:shelf/shelf.dart' as shelf;

import '../base/file_system.dart';
import '../base/platform.dart';
import '../web/web_constants.dart';

import 'web_server_utilities.dart';

class ReleaseAssetServer {
  ReleaseAssetServer(
    this.entrypoint, {
    required this._fileSystem,
    required this._webBuildDirectory,
    required this._flutterRoot,
    required this._platform,
    required this._needsCoopCoep,
    this.basePath = '',
  });

  final Uri entrypoint;
  final String? _flutterRoot;
  final String? _webBuildDirectory;
  final FileSystem _fileSystem;
  final Platform _platform;
  final bool _needsCoopCoep;

  /// The base path to serve from.
  ///
  /// It should have no leading or trailing slashes.
  @visibleForTesting
  final String basePath;

  // File extensions that may legitimately be requested from the project and
  // Flutter SDK roots. These roots only need to satisfy source-map source
  // resolution (the original Dart sources and `.map` files referenced by a
  // build's source maps), so requests for other files (for example `.env`,
  // keystore/signing config, or arbitrary project files) are not served from
  // them. The web build output directory is unrestricted because it only
  // contains generated, publishable assets.
  static const Set<String> _sourceMapExtensions = <String>{'.dart', '.map'};

  // Locations where source files, assets, or source maps may be located, paired
  // with the set of file extensions allowed to be served from each location. An
  // empty set means no extension restriction is applied.
  List<(Uri, Set<String>)> _searchPaths() => <(Uri, Set<String>)>[
    (_fileSystem.directory(_webBuildDirectory).uri, const <String>{}),
    (_fileSystem.directory(_flutterRoot).uri, _sourceMapExtensions),
    (_fileSystem.currentDirectory.uri, _sourceMapExtensions),
  ];

  Future<shelf.Response> handle(shelf.Request request) async {
    if (request.method != 'GET') {
      // Assets are served via GET only.
      return shelf.Response.notFound('');
    }

    Uri? fileUri;
    final String? requestPath = stripBasePath(request.url.path, basePath);

    if (requestPath == null) {
      return shelf.Response.notFound('');
    }

    if (request.url.toString() == 'main.dart') {
      fileUri = entrypoint;
    } else {
      for (final (Uri uri, Set<String> allowedExtensions) in _searchPaths()) {
        final Uri potential = uri.resolve(requestPath);
        final String potentialPath = potential.toFilePath(windows: _platform.isWindows);
        if (allowedExtensions.isNotEmpty &&
            !allowedExtensions.contains(_fileSystem.path.extension(potentialPath))) {
          // This root only serves source-map related files; skip anything else
          // so unrelated project or SDK files are not exposed.
          continue;
        }
        if (_fileSystem.isFileSync(potentialPath)) {
          fileUri = potential;
          break;
        }
      }
    }
    if (fileUri != null) {
      final File file = _fileSystem.file(fileUri);
      final Uint8List bytes = file.readAsBytesSync();
      // Fallback to "application/octet-stream" on null which
      // makes no claims as to the structure of the data.
      final String mimeType =
          mime.lookupMimeType(file.path, headerBytes: bytes) ?? 'application/octet-stream';
      return shelf.Response.ok(
        bytes,
        headers: <String, String>{
          'Content-Type': mimeType,
          'Cross-Origin-Resource-Policy': 'cross-origin',
          'Access-Control-Allow-Origin': '*',
          if (_needsCoopCoep && _fileSystem.path.extension(file.path) == '.html')
            ...kCrossOriginIsolationHeaders,
        },
      );
    }

    final File file = _fileSystem.file(_fileSystem.path.join(_webBuildDirectory!, 'index.html'));
    return shelf.Response.ok(
      file.readAsBytesSync(),
      headers: <String, String>{
        'Content-Type': 'text/html',
        if (_needsCoopCoep) ...kCrossOriginIsolationHeaders,
      },
    );
  }
}
