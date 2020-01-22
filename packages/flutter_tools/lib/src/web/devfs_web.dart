// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../compile.dart';
import '../convert.dart';
import '../devfs.dart';
import '../globals.dart' as globals;
import 'bootstrap.dart';

/// A web server which handles serving JavaScript and assets.
///
/// This is only used in development mode.
class WebAssetServer {
  @visibleForTesting
  WebAssetServer(this._httpServer, this._packages, this.internetAddress,
      {@required void Function(dynamic, StackTrace) onError}) {
    _httpServer.listen((HttpRequest request) {
      _handleRequest(request).catchError(onError);
      // TODO(jonahwilliams): test the onError callback when https://github.com/dart-lang/sdk/issues/39094 is fixed.
    }, onError: onError);
  }

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _kDefaultMimeType = 'application/octet-stream';

  /// Start the web asset server on a [hostname] and [port].
  ///
  /// Unhandled exceptions will throw a [ToolExit] with the error and stack
  /// trace.
  static Future<WebAssetServer> start(String hostname, int port) async {
    try {
      final InternetAddress address = (await InternetAddress.lookup(hostname)).first;
      final HttpServer httpServer = await HttpServer.bind(address, port);
      final Packages packages =
          await loadPackagesFile(Uri.base.resolve('.packages'));
      return WebAssetServer(httpServer, packages, address,
          onError: (dynamic error, StackTrace stackTrace) {
        httpServer.close(force: true);
        throwToolExit(
            'Unhandled exception in web development server:\n$error\n$stackTrace');
      });
    } on SocketException catch (err) {
      throwToolExit('Failed to bind web development server:\n$err');
    }
    assert(false);
    return null;
  }

  final HttpServer _httpServer;
  // If holding these in memory is too much overhead, this can be switched to a
  // RandomAccessFile and read on demand.
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final Map<String, Uint8List> _sourcemaps = <String, Uint8List>{};

  final RegExp _drivePath = RegExp(r'\/[A-Z]:\/');

  final Packages _packages;
  final InternetAddress internetAddress;

  // handle requests for JavaScript source, dart sources maps, or asset files.
  Future<void> _handleRequest(HttpRequest request) async {
    final HttpResponse response = request.response;
    // If the response is `/`, then we are requesting the index file.
    if (request.uri.path == '/') {
      final File indexFile = globals.fs.currentDirectory
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
    // TODO(jonahwilliams): better path normalization in frontend_server to remove
    // this workaround.
    String requestPath = request.uri.path;
    if (requestPath.startsWith(_drivePath)) {
      requestPath = requestPath.substring(3);
    }

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    if (_files.containsKey(requestPath)) {
      final List<int> bytes = _files[requestPath];
      response.headers
        ..add('Content-Length', bytes.length)
        ..add('Content-Type', 'application/javascript');
      response.add(bytes);
      await response.close();
      return;
    }
    // If this is a sourcemap file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (_sourcemaps.containsKey(requestPath)) {
      final List<int> bytes = _sourcemaps[requestPath];
      response.headers
        ..add('Content-Length', bytes.length)
        ..add('Content-Type', 'application/json');
      response.add(bytes);
      await response.close();
      return;
    }

    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. Attempt to look in the
    // local filesystem for it, and return a 404 if it is not found. The tool
    // doesn't currently consider the case of Dart files as assets.
    File file = globals.fs.file(Uri.base.resolve(request.uri.path));

    // If both of the lookups above failed, the file might have been a package
    // file which is signaled by a `/packages/<package>/<path>` request.
    if (!file.existsSync() && request.uri.pathSegments.first == 'packages') {
      file = globals.fs.file(_packages.resolve(Uri(
          scheme: 'package', pathSegments: request.uri.pathSegments.skip(1))));
    }

    // If all of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    if (!file.existsSync()) {
      final String assetPath = request.uri.path.replaceFirst('/assets/', '');
      file = globals.fs.file(globals.fs.path
          .join(getAssetBuildDirectory(), globals.fs.path.relative(assetPath)));
    }

    // If it isn't a project source or an asset, it must be a dart SDK source.
    // or a flutter web SDK source.
    if (!file.existsSync()) {
      final Directory dartSdkParent = globals.fs
          .directory(
              globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath))
          .parent;
      file = globals.fs.file(globals.fs.path
          .joinAll(<String>[dartSdkParent.path, ...request.uri.pathSegments]));
    }

    if (!file.existsSync()) {
      final String flutterWebSdk =
          globals.artifacts.getArtifactPath(Artifact.flutterWebSdk);
      file = globals.fs.file(globals.fs.path
          .joinAll(<String>[flutterWebSdk, ...request.uri.pathSegments]));
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
      mimeType = mime.lookupMimeType(
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
  List<String> write(File codeFile, File manifestFile, File sourcemapFile) {
    final List<String> modules = <String>[];
    final Uint8List codeBytes = codeFile.readAsBytesSync();
    final Uint8List sourcemapBytes = sourcemapFile.readAsBytesSync();
    final Map<String, dynamic> manifest =
        castStringKeyedMap(json.decode(manifestFile.readAsStringSync()));
    for (final String filePath in manifest.keys) {
      if (filePath == null) {
        globals.printTrace('Invalid manfiest file: $filePath');
        continue;
      }
      final Map<String, dynamic> offsets =
          castStringKeyedMap(manifest[filePath]);
      final List<int> codeOffsets =
          (offsets['code'] as List<dynamic>).cast<int>();
      final List<int> sourcemapOffsets =
          (offsets['sourcemap'] as List<dynamic>).cast<int>();
      if (codeOffsets.length != 2 || sourcemapOffsets.length != 2) {
        globals.printTrace('Invalid manifest byte offsets: $offsets');
        continue;
      }

      final int codeStart = codeOffsets[0];
      final int codeEnd = codeOffsets[1];
      if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
        globals.printTrace('Invalid byte index: [$codeStart, $codeEnd]');
        continue;
      }
      final Uint8List byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );
      _files[_filePathToUriFragment(filePath)] = byteView;

      final int sourcemapStart = sourcemapOffsets[0];
      final int sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        globals
            .printTrace('Invalid byte index: [$sourcemapStart, $sourcemapEnd]');
        continue;
      }
      final Uint8List sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      _sourcemaps['${_filePathToUriFragment(filePath)}.map'] = sourcemapView;

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
    final InternetAddress internetAddress = _webAssetServer.internetAddress;
    // Format ipv6 hosts according to RFC 5952.
    return Uri.parse(
      internetAddress.type == InternetAddressType.IPv4
        ? '${internetAddress.address}:$port'
        : '[${internetAddress.address}]:$port'
    );
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
    bool skipAssets = false,
  }) async {
    assert(trackWidgetCreation != null);
    assert(generator != null);
    if (bundleFirstUpload) {
      final File requireJS = globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'kernel',
        'amd',
        'require.js',
      ));
      final File dartSdk = globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js',
      ));
      final File dartSdkSourcemap = globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.flutterWebSdk),
        'kernel',
        'amd',
        'dart_sdk.js.map',
      ));
      final File stackTraceMapper = globals.fs.file(globals.fs.path.join(
        globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
        'lib',
        'dev_compiler',
        'web',
        'dart_stack_trace_mapper.js',
      ));
      _webAssetServer.writeFile(
          '/main.dart.js',
          generateBootstrapScript(
            requireUrl: _filePathToUriFragment(requireJS.path),
            mapperUrl: _filePathToUriFragment(stackTraceMapper.path),
            entrypoint: '${_filePathToUriFragment(mainPath)}.js',
          ));
      _webAssetServer.writeFile(
          '/main_module.js',
          generateMainModule(
            entrypoint: '${_filePathToUriFragment(mainPath)}.js',
          ));
      _webAssetServer.writeFile('/dart_sdk.js', dartSdk.readAsStringSync());
      _webAssetServer.writeFile(
          '/dart_sdk.js.map', dartSdkSourcemap.readAsStringSync());
      // TODO(jonahwilliams): refactor the asset code in this and the regular devfs to
      // be shared.
      await writeBundle(
          globals.fs.directory(getAssetBuildDirectory()), bundle.entries);
    }
    final DateTime candidateCompileTime = DateTime.now();
    if (fullRestart) {
      generator.reset();
    }
    final CompilerOutput compilerOutput = await generator.recompile(
      mainPath,
      invalidatedFiles,
      outputPath: dillOutputPath ??
          getDefaultApplicationKernelPath(
              trackWidgetCreation: trackWidgetCreation),
      packagesFilePath: _packagesFilePath,
    );
    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      return UpdateFSReport(success: false);
    }
    // Only update the last compiled time if we successfully compiled.
    lastCompiled = candidateCompileTime;
    // list of sources that needs to be monitored are in [compilerOutput.sources]
    sources = compilerOutput.sources;
    File codeFile;
    File manifestFile;
    File sourcemapFile;
    List<String> modules;
    try {
      codeFile = globals.fs.file('${compilerOutput.outputFilename}.sources');
      manifestFile = globals.fs.file('${compilerOutput.outputFilename}.json');
      sourcemapFile = globals.fs.file('${compilerOutput.outputFilename}.map');
      modules = _webAssetServer.write(codeFile, manifestFile, sourcemapFile);
    } on FileSystemException catch (err) {
      throwToolExit('Failed to load recompiled sources:\n$err');
    }
    return UpdateFSReport(
        success: true,
        syncedBytes: codeFile.lengthSync(),
        invalidatedSourcesCount: invalidatedFiles.length)
      ..invalidatedModules = modules.map(_filePathToUriFragment).toList();
  }
}

String _filePathToUriFragment(String path) {
  if (globals.platform.isWindows) {
    final bool startWithSlash = path.startsWith('/');
    final String partial =
        globals.fs.path.split(path).skip(startWithSlash ? 2 : 1).join('/');
    if (partial.startsWith('/')) {
      return partial;
    }
    return '/$partial';
  }
  return path;
}
