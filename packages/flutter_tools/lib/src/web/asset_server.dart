// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../project.dart';

/// Handles mapping requests from a dartdevc compiled application to assets.
///
/// The server will receive size different kinds of requests:
///
///  1. A request to assets in the form of `/assets/foo`. These are resolved
///     relative to `build/flutter_assets`.
///  2. A request to a bootstrap file, such as `main.dart.js`. These are
///     resolved relative to the dart tool directory.
///  3. A request to a JavaScript asset in the form of `/packages/foo/bar.js`.
///     These are looked up relative to the correct package root of the
///     dart_tool directory.
///  4. A request to a Dart asset in the form of `/packages/foo/bar.dart` for
///     sourcemaps. These either need to be looked up from the application lib
///     directory (if the package is the same), or found in the .packages file.
///  5. A request for a specific dart asset such as `stack_trace_mapper.js` or
///     `dart_sdk.js`. These have fixed locations determined by [artifacts].
///  6. A request to `/` which is translated into `index.html`.
class WebAssetServer {
  WebAssetServer(this.flutterProject, this.target, this.ipv6);

  /// The flutter project corresponding to this application.
  final FlutterProject flutterProject;

  /// The entrypoint we have compiled for.
  final String target;

  /// Whether to serve from ipv6 localhost.
  final bool ipv6;

  HttpServer _server;
  Map<String, Uri> _packages;

  /// The port being served, or null if not initialized.
  int get port => _server?.port;

  /// Initialize the server.
  ///
  /// Throws a [StateError] if called multiple times.
  Future<void> initialize() async {
    if (_server != null) {
      throw StateError('Already serving.');
    }
    _packages = PackageMap(PackageMap.globalPackagesPath).map;
    _server = await HttpServer.bind(
        ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4, 0)
      ..autoCompress = false;
    _server.listen(_onRequest);
  }

  /// Clean up the server.
  Future<void> dispose() {
    return _server.close();
  }

  /// An HTTP server which provides JavaScript and web assets to the browser.
  Future<void> _onRequest(HttpRequest request) async {
    final String targetName = '${fs.path.basenameWithoutExtension(target)}_web_entrypoint';
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    final Uri uri = request.uri;
    if (uri.path == '/') {
      final File file = flutterProject.directory
          .childDirectory('web')
          .childFile('index.html');
      await _completeRequest(request, file, 'text/html');
    } else if (uri.path.contains('stack_trace_mapper')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js'
      ));
      await _completeRequest(request, file, 'text/javascript');
    } else if (uri.path.contains('require.js')) {
     final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
       'lib',
       'dev_compiler',
       'kernel',
       'amd',
       'require.js'
     ));
     await _completeRequest(request, file, 'text/javascript');
    } else if (uri.path.endsWith('main.dart.js')) {
      final File file = fs.file(fs.path.join(
        flutterProject.dartTool.path,
        'build',
        'flutter_web',
        flutterProject.manifest.appName,
        'lib',
        '$targetName.dart.js',
      ));
      await _completeRequest(request, file, 'text/javascript');
    } else if (uri.path.endsWith('$targetName.dart.bootstrap.js')) {
      final File file = fs.file(fs.path.join(
        flutterProject.dartTool.path,
        'build',
        'flutter_web',
        flutterProject.manifest.appName,
        'lib',
        '$targetName.dart.bootstrap.js',
      ));
      await _completeRequest(request, file, 'text/javascript');
    } else if (uri.path.contains('dart_sdk')) {
      final File file = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));
      await _completeRequest(request, file, 'text/javascript');
    } else if (uri.path.startsWith('/packages') && uri.path.endsWith('.dart')) {
      await _resolveDart(request);
    } else if (uri.path.startsWith('/packages')) {
      await _resolveJavascript(request);
    } else if (uri.path.contains('assets')) {
      await _resolveAsset(request);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  /// Resolves requests in the form of `/packages/foo/bar.js` or
  /// `/packages/foo/bar.js.map`.
  Future<void> _resolveJavascript(HttpRequest request) async {
    final List<String> segments = fs.path.split(request.uri.path);
    final String packageName = segments[2];
    final String filePath = fs.path.joinAll(segments.sublist(3));
    final Uri packageUri = flutterProject.dartTool
        .childDirectory('build')
        .childDirectory('flutter_web')
        .childDirectory(packageName)
        .childDirectory('lib')
        .uri;
    await _completeRequest(
        request, fs.file(packageUri.resolve(filePath)), 'text/javascript');
  }

  /// Resolves requests in the form of `/packages/foo/bar.dart`.
  Future<void> _resolveDart(HttpRequest request) async {
    final List<String> segments = fs.path.split(request.uri.path);
    final String packageName = segments[2];
    final String filePath = fs.path.joinAll(segments.sublist(3));
    final Uri packageUri = _packages[packageName];
    await _completeRequest(request, fs.file(packageUri.resolve(filePath)));
  }

  /// Resolves requests in the form of `/assets/foo`.
  Future<void> _resolveAsset(HttpRequest request) async {
    final String assetPath = request.uri.path.replaceFirst('/assets/', '');
    await _completeRequest(
        request, fs.file(fs.path.join(getAssetBuildDirectory(), assetPath)));
  }

  Future<void> _completeRequest(HttpRequest request, File file,
      [String contentType = 'text']) async {
    if (!file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    if (contentType != null) {
      request.response.headers.add(HttpHeaders.contentTypeHeader, contentType);
    }
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}
