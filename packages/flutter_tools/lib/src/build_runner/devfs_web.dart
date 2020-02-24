// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/dwds.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../convert.dart';
import '../devfs.dart';
import '../globals.dart' as globals;
import '../web/bootstrap.dart';
import '../web/chrome.dart';

/// A web server which handles serving JavaScript and assets.
///
/// This is only used in development mode.
class WebAssetServer implements AssetReader {
  @visibleForTesting
  WebAssetServer(this._httpServer, this._packages, this.internetAddress);

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _kDefaultMimeType = 'application/octet-stream';

  /// Start the web asset server on a [hostname] and [port].
  ///
  /// If [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  ///
  /// Unhandled exceptions will throw a [ToolExit] with the error and stack
  /// trace.
  static Future<WebAssetServer> start(
    String hostname,
    int port,
    UrlTunneller urlTunneller,
    BuildMode buildMode,
    bool enableDwds,
    Uri entrypoint, {
    bool testMode = false,
  }) async {
    try {
      final InternetAddress address = (await InternetAddress.lookup(hostname)).first;
      final HttpServer httpServer = await HttpServer.bind(address, port);
      final Packages packages = await loadPackagesFile(
        Uri.base.resolve('.packages'), loader: (Uri uri) => globals.fs.file(uri).readAsBytes());
      final WebAssetServer server = WebAssetServer(httpServer, packages, address);
      if (testMode) {
        return server;
      }

      // In release builds deploy a simpler proxy server.
      if (buildMode != BuildMode.debug) {
        final ReleaseAssetServer releaseAssetServer = ReleaseAssetServer(entrypoint);
        shelf.serveRequests(httpServer, releaseAssetServer.handle);
        return server;
      }
      // In debug builds, spin up DWDS and the full asset server.
      final Dwds dwds = await Dwds.start(
        assetReader: server,
        buildResults: const Stream<BuildResult>.empty(),
        chromeConnection: () async {
          final Chrome chrome = await ChromeLauncher.connectedInstance;
          return chrome.chromeConnection;
        },
        urlEncoder: urlTunneller,
        enableDebugging: true,
        logWriter: (Level logLevel, String message) => globals.printTrace(message)
      );
      shelf.Pipeline pipeline = const shelf.Pipeline();
      if (enableDwds) {
        pipeline = pipeline.addMiddleware(dwds.middleware);
      }
      final shelf.Handler dwdsHandler = pipeline.addHandler(server.handleRequest);
      final shelf.Cascade cascade = shelf.Cascade()
        .add(dwds.handler)
        .add(dwdsHandler);
      shelf.serveRequests(httpServer, cascade.handler);
      server.dwds = dwds;
      return server;
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
  final Packages _packages;
  final InternetAddress internetAddress;
  /* late final */ Dwds dwds;

  @visibleForTesting
  Uint8List getFile(String path) => _files[path];

  @visibleForTesting
  Uint8List getSourceMap(String path) => _sourcemaps[path];

  // handle requests for JavaScript source, dart sources maps, or asset files.
  @visibleForTesting
  Future<shelf.Response> handleRequest(shelf.Request request) async {
    final Map<String, String> headers = <String, String>{};
    // If the response is `/`, then we are requesting the index file.
    if (request.url.path == '/' || request.url.path.isEmpty) {
      final File indexFile = globals.fs.currentDirectory
        .childDirectory('web')
        .childFile('index.html');
      if (indexFile.existsSync()) {
        headers[HttpHeaders.contentTypeHeader] = 'text/html';
        headers[HttpHeaders.contentLengthHeader] = indexFile.lengthSync().toString();
        return shelf.Response.ok(indexFile.openRead(), headers: headers);
      }
      return shelf.Response.notFound('');
    }

    // Track etag headers for better caching of resources.
    final String ifNoneMatch = request.headers[HttpHeaders.ifNoneMatchHeader];
    headers[HttpHeaders.cacheControlHeader] = 'max-age=0, must-revalidate';

    // NOTE: shelf removes leading `/` for some reason.
    final String requestPath = request.url.path.startsWith('/')
      ?  request.url.path
      : '/${request.url.path}';

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    if (_files.containsKey(requestPath)) {
      final List<int> bytes = getFile(requestPath);
      // Use the underlying buffer hashCode as a revision string. This buffer is
      // replaced whenever the frontend_server produces new output files, which
      // will also change the hashCode.
      final String etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      headers[HttpHeaders.contentTypeHeader] = 'application/javascript';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }
    // If this is a sourcemap file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (_sourcemaps.containsKey(requestPath)) {
      final List<int> bytes = getSourceMap(requestPath);
      final String etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }

    File file = _resolveDartFile(requestPath);

    // If all of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    if (!file.existsSync()) {
      final Uri potential = globals.fs.directory(getAssetBuildDirectory())
        .uri.resolve( requestPath.replaceFirst('/assets/', ''));
      file = globals.fs.file(potential);
    }

    if (!file.existsSync()) {
      return shelf.Response.notFound('');
    }

    // For real files, use a serialized file stat as a revision
    final String etag = file.lastModifiedSync().toIso8601String();
    if (ifNoneMatch == etag) {
      return shelf.Response.notModified();
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
    headers[HttpHeaders.contentLengthHeader] = length.toString();
    headers[HttpHeaders.contentTypeHeader] = mimeType;
    headers[HttpHeaders.etagHeader] = etag;
    return shelf.Response.ok(file.openRead(), headers: headers);
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
    final Map<String, dynamic> manifest = castStringKeyedMap(json.decode(manifestFile.readAsStringSync()));
    for (final String filePath in manifest.keys) {
      if (filePath == null) {
        globals.printTrace('Invalid manfiest file: $filePath');
        continue;
      }
      final Map<String, dynamic> offsets = castStringKeyedMap(manifest[filePath]);
      final List<int> codeOffsets = (offsets['code'] as List<dynamic>).cast<int>();
      final List<int> sourcemapOffsets = (offsets['sourcemap'] as List<dynamic>).cast<int>();
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
      _files[filePath] = byteView;

      final int sourcemapStart = sourcemapOffsets[0];
      final int sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        globals.printTrace('Invalid byte index: [$sourcemapStart, $sourcemapEnd]');
        continue;
      }
      final Uint8List sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      _sourcemaps['$filePath.map'] = sourcemapView;

      modules.add(filePath);
    }
    return modules;
  }

  @visibleForTesting
  final File dartSdk = globals.fs.file(globals.fs.path.join(
    globals.artifacts.getArtifactPath(Artifact.flutterWebSdk),
    'kernel',
    'amd',
    'dart_sdk.js',
  ));

  @visibleForTesting
  final File dartSdkSourcemap = globals.fs.file(globals.fs.path.join(
    globals.artifacts.getArtifactPath(Artifact.flutterWebSdk),
    'kernel',
    'amd',
    'dart_sdk.js.map',
  ));

  // Attempt to resolve `path` to a dart file.
  File _resolveDartFile(String path) {
    // Return the actual file objects so that local engine changes are automatically picked up.
    switch (path) {
      case '/dart_sdk.js':
        return dartSdk;
      case '.dart_sdk.js.map':
        return dartSdkSourcemap;
    }
    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. The tool doesn't currently
    // consider the case of Dart files as assets.
    final File dartFile = globals.fs.file(globals.fs.currentDirectory.uri.resolve(path));
    if (dartFile.existsSync()) {
      return dartFile;
    }

    final List<String> segments = path.split('/');
    if (segments.first.isEmpty) {
      segments.removeAt(0);
    }

    // The file might have been a package file which is signaled by a
    // `/packages/<package>/<path>` request.
    if (segments.first == 'packages') {
      final File packageFile = globals.fs.file(_packages.resolve(Uri(
        scheme: 'package', pathSegments: segments.skip(1))));
      if (packageFile.existsSync()) {
        return packageFile;
      }
    }

    // Otherwise it must be a Dart SDK source or a Flutter Web SDK source.
    final Directory dartSdkParent = globals.fs
      .directory(globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath))
      .parent;
    final File dartSdkFile = globals.fs.file(globals.fs.path
      .joinAll(<String>[dartSdkParent.path, ...segments]));
    if (dartSdkFile.existsSync()) {
      return dartSdkFile;
    }

    final String flutterWebSdk = globals.artifacts
      .getArtifactPath(Artifact.flutterWebSdk);
    final File webSdkFile = globals.fs
      .file(globals.fs.path.joinAll(<String>[flutterWebSdk, ...segments]));

    return webSdkFile;
  }

  @override
  Future<String> dartSourceContents(String serverPath) {
    final File result = _resolveDartFile(serverPath);
    if (result.existsSync()) {
      return result.readAsString();
    }
    return null;
  }

  @override
  Future<String> sourceMapContents(String serverPath) async {
    return utf8.decode(_sourcemaps[serverPath]);
  }
}

class ConnectionResult {
  ConnectionResult(this.appConnection, this.debugConnection);

  final AppConnection appConnection;
  final DebugConnection debugConnection;
}

/// The web specific DevFS implementation.
class WebDevFS implements DevFS {
  /// Create a new [WebDevFS] instance.
  ///
  /// [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  WebDevFS({
    @required this.hostname,
    @required this.port,
    @required this.packagesFilePath,
    @required this.urlTunneller,
    @required this.buildMode,
    @required this.enableDwds,
    @required this.entrypoint,
    this.testMode = false,
  });

  final Uri entrypoint;
  final String hostname;
  final int port;
  final String packagesFilePath;
  final UrlTunneller urlTunneller;
  final BuildMode buildMode;
  final bool enableDwds;
  final bool testMode;

  @visibleForTesting
  WebAssetServer webAssetServer;

  Dwds get dwds => webAssetServer.dwds;

  Future<DebugConnection> _cachedExtensionFuture;
  StreamSubscription<void> _connectedApps;

  /// Connect and retrieve the [DebugConnection] for the current application.
  ///
  /// Only calls [AppConnection.runMain] on the subsequent connections.
  Future<ConnectionResult> connect(bool useDebugExtension) {
    final Completer<ConnectionResult> firstConnection = Completer<ConnectionResult>();
    _connectedApps = dwds.connectedApps.listen((AppConnection appConnection) async {
      try {
        final DebugConnection debugConnection = useDebugExtension
          ? await (_cachedExtensionFuture ??= dwds.extensionDebugConnections.stream.first)
          : await dwds.debugConnection(appConnection);
        if (firstConnection.isCompleted) {
          appConnection.runMain();
        } else {
          firstConnection.complete(ConnectionResult(appConnection, debugConnection));
        }
      } on Exception catch (error, stackTrace) {
        if (!firstConnection.isCompleted) {
          firstConnection.completeError(error, stackTrace);
        }
      }
    }, onError: (dynamic error, StackTrace stackTrace) {
      globals.printError('Unknown error while waiting for debug connection:$error\n$stackTrace');
      if (!firstConnection.isCompleted) {
        firstConnection.completeError(error, stackTrace);
      }
    });
    return firstConnection.future;
  }

  @override
  List<Uri> sources = <Uri>[];

  @override
  DateTime lastCompiled;

  // We do not evict assets on the web.
  @override
  Set<String> get assetPathsToEvict => const <String>{};

  @override
  Uri get baseUri => _baseUri;
  Uri _baseUri;

  @override
  Future<Uri> create() async {
    webAssetServer = await WebAssetServer.start(
      hostname,
      port,
      urlTunneller,
      buildMode,
      enableDwds,
      entrypoint,
      testMode: testMode,
    );
    _baseUri = Uri.parse('http://$hostname:$port');
    return _baseUri;
  }

  @override
  Future<void> destroy() async {
    await webAssetServer.dispose();
    await _connectedApps?.cancel();
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
    final String outputDirectoryPath = globals.fs.file(mainPath).parent.path;

    if (bundleFirstUpload) {
      generator.addFileSystemRoot(outputDirectoryPath);
      final String entrypoint = globals.fs.path.basename(mainPath);
      webAssetServer.writeFile('/$entrypoint', globals.fs.file(mainPath).readAsStringSync());
      webAssetServer.writeFile('/manifest.json', '{"info":"manifest not generated in run mode."}');
      webAssetServer.writeFile('/flutter_service_worker.js', '// Service worker not loaded in run mode.');
      webAssetServer.writeFile(
        '/main.dart.js',
        generateBootstrapScript(
          requireUrl: _filePathToUriFragment(requireJS.path),
          mapperUrl: _filePathToUriFragment(stackTraceMapper.path),
          entrypoint: '/$entrypoint.lib.js',
        ),
      );
      webAssetServer.writeFile(
        '/main_module.bootstrap.js',
        generateMainModule(
          entrypoint: '/$entrypoint.lib.js',
        ),
      );
      // TODO(jonahwilliams): switch to DWDS provided APIs when they are ready.
      webAssetServer.writeFile('/basic.digests', '{}');

      // TODO(jonahwilliams): refactor the asset code in this and the regular devfs to
      // be shared.
      if (bundle != null) {
        await writeBundle(
          globals.fs.directory(getAssetBuildDirectory()),
          bundle.entries,
        );
      }
    }
    final DateTime candidateCompileTime = DateTime.now();
    if (fullRestart) {
      generator.reset();
    }

    // The tool generates an entrypoint file in a temp directory to handle
    // the web specific bootrstrap logic. To make it easier for DWDS to handle
    // mapping the file name, this is done via an additional file root and
    // specicial hard-coded scheme.
    final CompilerOutput compilerOutput = await generator.recompile(
     'org-dartlang-app:///' + globals.fs.path.basename(mainPath),
      invalidatedFiles,
      outputPath: dillOutputPath ??
        getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation),
      packagesFilePath: packagesFilePath,
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
      final Directory parentDirectory = globals.fs.directory(outputDirectoryPath);
      codeFile = parentDirectory.childFile('${compilerOutput.outputFilename}.sources');
      manifestFile = parentDirectory.childFile('${compilerOutput.outputFilename}.json');
      sourcemapFile = parentDirectory.childFile('${compilerOutput.outputFilename}.map');
      modules = webAssetServer.write(codeFile, manifestFile, sourcemapFile);
    } on FileSystemException catch (err) {
      throwToolExit('Failed to load recompiled sources:\n$err');
    }

    return UpdateFSReport(
      success: true,
      syncedBytes: codeFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length,
    )..invalidatedModules = modules;
  }

  @visibleForTesting
  final File requireJS = globals.fs.file(globals.fs.path.join(
    globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
    'lib',
    'dev_compiler',
    'kernel',
    'amd',
    'require.js',
  ));

  @visibleForTesting
  final File stackTraceMapper = globals.fs.file(globals.fs.path.join(
    globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath),
    'lib',
    'dev_compiler',
    'web',
    'dart_stack_trace_mapper.js',
  ));
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

class ReleaseAssetServer {
  ReleaseAssetServer(this.entrypoint);

  final Uri entrypoint;

  // Locations where source files, assets, or source maps may be located.
  final List<Uri> _searchPaths = <Uri>[
    globals.fs.directory(getWebBuildDirectory()).uri,
    globals.fs.directory(Cache.flutterRoot).uri,
    globals.fs.currentDirectory.uri,
  ];

  Future<shelf.Response> handle(shelf.Request request) async {
    Uri fileUri;
    if (request.url.toString() == 'main.dart') {
      fileUri = entrypoint;
    } else {
      for (final Uri uri in _searchPaths) {
        final Uri potential = uri.resolve(request.url.path);
        if (potential == null || !globals.fs.isFileSync(potential.toFilePath())) {
          continue;
        }
        fileUri = potential;
        break;
      }
    }
    if (fileUri != null) {
      final File file = globals.fs.file(fileUri);
      final Uint8List bytes = file.readAsBytesSync();
      // Fallback to "application/octet-stream" on null which
      // makes no claims as to the structure of the data.
      final String mimeType = mime.lookupMimeType(file.path, headerBytes: bytes)
        ?? 'application/octet-stream';
      return shelf.Response.ok(bytes, headers: <String, String>{
        'Content-Type': mimeType,
      });
    }
    if (request.url.path == '') {
      final File file = globals.fs.file(globals.fs.path.join(getWebBuildDirectory(), 'index.html'));
      return shelf.Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/html',
      });
    }
    return shelf.Response.notFound('');
  }
}
