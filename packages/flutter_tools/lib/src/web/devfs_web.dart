// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../devfs.dart';
import '../globals.dart';
import 'bootstrap.dart';

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
  final Map<String, Uint8List> _files = <String, Uint8List>{};

  // handle requests for JavaScript source, dart sources maps, or asset files.
  Future<void> _handleRequest(HttpRequest request) async {
    final HttpResponse response = request.response;
    // If the response is `/`, then we are requesting the index file.
    if (request.uri.path == '/') {
      final File indexFile = fs.currentDirectory
        .childDirectory('web')
        .childFile('index.html');
      if (indexFile.existsSync()) {
        response.headers.add('Content-Type', 'text/html');
        response.headers.add('Content-Length', indexFile.lengthSync());
        await response.addStream(indexFile.openRead());
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
      return;
    }

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI, returning a 404 if it is not
    // found.
    if (_files.containsKey(request.uri.path)) {
      final List<int> bytes = _files[request.uri.path];
      response.headers
        ..add('Content-Length', bytes.length)
        ..add('Content-Type', 'application/javascript');
      response.add(bytes);
      await response.close();
      return;
    }
    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. Attempt to look in the
    // local filesystem for it, and return a 404 if it is not found. The tool
    // doesn't currently consider the case of Dart files as assets.
    File file = fs.file(Uri.base.resolve(request.uri.path));

    // If both of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    if (!file.existsSync()) {
      final String assetPath = file.path.replaceFirst('/assets/', '');
      file = fs.file(fs.path.join(getAssetBuildDirectory(), fs.path.relative(assetPath)));
    }

    if (!file.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final int length = file.lengthSync();
    // Attempt to determine the file's mime type. if this is not provided some
    // browsers will refuse to render images/show video et cetera. If the tool
    // cannot determine a mime type, fall back to application/octet-stream.
    String mimeType;
    if (length >= 12) {
      mimeType= mime.lookupMimeType(
        file.path,
        headerBytes: await file.openRead(0, 12).first,
      );
    }
    mimeType ??= _kDefaultMimeType;
    response.headers.add('Content-Length', length);
    response.headers.add('Content-Type', mimeType);
    await response.addStream(file.openRead());
    await response.close();
  }

  /// Tear down the http server running.
  Future<void> dispose() {
    return _httpServer.close();
  }

  /// Write a single file into the in-memory cache.
  void writeFile(String filePath, String contents) {
    _files[filePath] = Uint8List.fromList(utf8.encode(contents));
  }

  /// Update the in-memory asset server with the provided source and manifest files.
  ///
  /// Returns a list of updated modules.
  List<String> write(File sourceFile, File manifestFile) {
    final List<String> modules = <String>[];
    final Uint8List bytes = sourceFile.readAsBytesSync();
    final Map<String, Object> manifest = json.decode(manifestFile.readAsStringSync());
    for (String filePath in manifest.keys) {
      if (filePath == null) {
        printTrace('Invalid manfiest file: $filePath');
        continue;
      }
      final List<Object> offsets = manifest[filePath];
      if (offsets.length != 2) {
        printTrace('Invalid manifest byte offsets: $offsets');
        continue;
      }
      final int start = offsets[0];
      final int end = offsets[1];
      final Uint8List byteView = Uint8List.view(bytes.buffer, start, end - start);
      _files[filePath] = byteView;
      modules.add(filePath);
    }
    return modules;
  }
}

class WebDevFS implements DevFS {
  WebDevFS(this.hostname, this.port, this._packagesFilePath);

  final String hostname;
  final int port;
  final String _packagesFilePath;
  WebAssetServer _webAssetServer;

  @override
  List<Uri> sources = <Uri>[];

  @override
  DateTime lastCompiled;

  // We do not evict assets on the web.
  @override
  Set<String> get assetPathsToEvict => const <String>{};

  @override
  Uri get baseUri => null;

  @override
  Future<Uri> create() async {
    _webAssetServer = await WebAssetServer.start(hostname, port);
   return Uri.base;
  }

  @override
  Future<void> destroy() async {
    await _webAssetServer.dispose();
  }

  @override
  Uri deviceUriToHostUri(Uri deviceUri) {
    return deviceUri;
  }

  @override
  String get fsName => 'web_asset';

  @override
  Directory get rootDirectory => null;

  @override
  Future<UpdateFSReport> update({
    String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    @required ResidentCompiler generator,
    String dillOutputPath,
    @required bool trackWidgetCreation,
    bool fullRestart = false,
    String projectRootPath,
    String pathToReload,
    List<Uri> invalidatedFiles,
  }) async {
    assert(trackWidgetCreation != null);
    assert(generator != null);
    if (bundleFirstUpload) {
      final File requireJS = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'kernel',
        'amd',
        'require.js',
      ));
      final File dartSdk = fs.file(fs.path.join(
        artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));
      _webAssetServer.writeFile('/main.dart.js', generateBootstrapScript(
        requireUrl: requireJS.path,
        mapperUrl: null,
        mainModule: 'main_module.js',
        entrypoint: mainPath,
      ));
      _webAssetServer.writeFile('/main_module.js', generateMainModule(
        entrypoint: mainPath,
      ));
      _webAssetServer.writeFile('/dart_sdk.js', dartSdk.readAsStringSync());
    }
    final DateTime candidateCompileTime = DateTime.now();
    if (fullRestart) {
      generator.reset();
    }
     final CompilerOutput compilerOutput = await generator.recompile(
      mainPath,
      invalidatedFiles,
      outputPath:  dillOutputPath ?? getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation),
      packagesFilePath : _packagesFilePath,
    );
    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      return UpdateFSReport(success: false);
    }
    // Only update the last compiled time if we successfully compiled.
    lastCompiled = candidateCompileTime;
    // list of sources that needs to be monitored are in [compilerOutput.sources]
    sources = compilerOutput.sources;
    File sourceFile;
    File manifestFile;
    List<String> modules;
    try {
      sourceFile = fs.file('${compilerOutput.outputFilename}.sources');
      manifestFile = fs.file('${compilerOutput.outputFilename}.json');
      modules = _webAssetServer.write(sourceFile, manifestFile);
    } on FileSystemException {
      throwToolExit('Incremental compiler did not produce expected output.');
    }
    return UpdateFSReport(success: true, syncedBytes: sourceFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length)
        ..invalidatedModules = modules;
  }
}
