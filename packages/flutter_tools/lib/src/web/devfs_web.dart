// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;

import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart';

/// A web server which handles serving JavaScript manifests and assets.
///
/// This is only used in development mode.
class WebAssetServer {
  @visibleForTesting
  WebAssetServer(this._httpServer) {
    _httpServer.listen(_handleRequest);
  }

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _kDefaultMimeType = 'application/octet-stream';

  /// Start the web asset server on a [hostname] and [port].
  static Future<WebAssetServer> start(String hostname, int port) async {
    return WebAssetServer(await HttpServer.bind(hostname, port));
  }

  final HttpServer _httpServer;
  final Map<Uri, Uint8List> _files = <Uri, Uint8List>{};

  // handle requests for JavaScript source, dart sources maps, or asset files.
  Future<void> _handleRequest(HttpRequest request) async {
    final File file = fs.file(Uri.base.resolve(request.uri.path));
    final String fileExtension = fs.path.extension(file.path);
    final HttpResponse response = request.response;

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI, returning a 404 if it is not
    // found. The tool doesn't currently consider the case of JavaScript files
    // as assets.
    if (fileExtension == '.js') {
      final List<int> bytes = _files[file.uri];
      if (bytes != null) {
        response.headers
          ..add('Content-Length', bytes.length)
          ..add('Content-Type', 'application/javascript');
        response.add(bytes);
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
      return;
    }
    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. Attempt to look in the
    // local filesystem for it, and return a 404 if it is not found. The tool
    // doesn't currently consider the case of Dart files as assets.
    if (fileExtension == '.dart') {
      if (file.existsSync()) {
        response.headers.add('Content-Length', file.lengthSync());
        await response.addStream(file.openRead());
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
      return;
    }
    // If both of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    final String assetPath = file.path.replaceFirst('assets/', '');
    final File assetFile = fs.file(fs.path.join(getAssetBuildDirectory(), fs.path.relative(assetPath)));
    if (!assetFile.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final int length = assetFile.lengthSync();
    // Attempt to determine the file's mime type. if this is not provided some
    // browsers will refuse to render images/show video et cetera. If the tool
    // cannot determine a mime type, fall back to application/octet-stream.
    String mimeType;
    if (length >= 12) {
      mimeType= mime.lookupMimeType(
        assetFile.path,
        headerBytes: await assetFile.openRead(0, 12).first,
      );
    }
    mimeType ??= _kDefaultMimeType;
    response.headers.add('Content-Length', length);
    response.headers.add('Content-Type', mimeType);
    await response.addStream(assetFile.openRead());
    await response.close();
  }

  /// Tear down the http server running.
  Future<void> dispose() {
    return _httpServer.close();
  }

  /// Update the in-memory asset server with the provided source and manifest files.
  Future<void> write(File sourceFile, File manifestFile) async {
    final Uint8List bytes = sourceFile.readAsBytesSync();
    final Map<String, Object> manifest = json.decode(manifestFile.readAsStringSync());
    for (String fileUri in manifest.keys) {
      final Uri uri = Uri.tryParse(fileUri);
      if (uri == null || uri.scheme != 'file') {
        printTrace('Invalid manfiest file uri: $fileUri');
        continue;
      }
      final List<Object> offsets = manifest[fileUri];
      if (offsets.length != 2) {
        printTrace('Invalid manifest byte offsets: $offsets');
        continue;
      }
      final int start = offsets[0];
      final int end = offsets[1];
      final Uint8List byteView = Uint8List.view(bytes.buffer, start, end - start);
      _files[uri] = byteView;
    }
  }
}
