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

import 'web_server_utlities.dart';

class ReleaseAssetServer {
  ReleaseAssetServer(
    this.entrypoint, {
    required FileSystem fileSystem,
    required String? webBuildDirectory,
    required String? flutterRoot,
    required Platform platform,
    required bool needsCoopCoep,
    this.basePath = '',
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _flutterRoot = flutterRoot,
       _webBuildDirectory = webBuildDirectory,
       _needsCoopCoep = needsCoopCoep,
       _fileSystemUtils = FileSystemUtils(fileSystem: fileSystem, platform: platform);

  final Uri entrypoint;
  final String? _flutterRoot;
  final String? _webBuildDirectory;
  final FileSystem _fileSystem;
  final FileSystemUtils _fileSystemUtils;
  final Platform _platform;
  final bool _needsCoopCoep;

  /// The base path to serve from.
  ///
  /// It should have no leading or trailing slashes.
  @visibleForTesting
  final String basePath;

  // Locations where source files, assets, or source maps may be located.
  List<Uri> _searchPaths() => <Uri>[
    _fileSystem.directory(_webBuildDirectory).uri,
    _fileSystem.directory(_flutterRoot).uri,
    _fileSystem.directory(_flutterRoot).parent.uri,
    _fileSystem.currentDirectory.uri,
    _fileSystem.directory(_fileSystemUtils.homeDirPath).uri,
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
      for (final Uri uri in _searchPaths()) {
        final Uri potential = uri.resolve(requestPath);
        if (_fileSystem.isFileSync(potential.toFilePath(windows: _platform.isWindows))) {
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
            ...kMultiThreadedHeaders,
        },
      );
    }

    final File file = _fileSystem.file(_fileSystem.path.join(_webBuildDirectory!, 'index.html'));
    return shelf.Response.ok(
      file.readAsBytesSync(),
      headers: <String, String>{
        'Content-Type': 'text/html',
        if (_needsCoopCoep) ...kMultiThreadedHeaders,
      },
    );
  }
}
