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
import 'package:package_config/package_config.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../devfs.dart';
import '../globals.dart' as globals;
import '../web/bootstrap.dart';
import '../web/chrome.dart';

typedef DwdsLauncher = Future<Dwds> Function({
  @required AssetReader assetReader,
  @required Stream<BuildResult> buildResults,
  @required ConnectionProvider chromeConnection,
  @required LoadStrategy loadStrategy,
  @required bool enableDebugging,
  bool enableDebugExtension,
  String hostname,
  bool useSseForDebugProxy,
  bool useSseForDebugBackend,
  bool serveDevTools,
  void Function(Level, String) logWriter,
  bool verbose,
  UrlEncoder urlEncoder,
  bool useFileProvider,
  ExpressionCompiler expressionCompiler,
});

// A minimal index for projects that do not yet support web.
const String _kDefaultIndex = '''
<html>
    <body>
        <script src="main.dart.js"></script>
    </body>
</html>
''';

/// An expression compiler connecting to FrontendServer.
///
/// This is only used in development mode.
class WebExpressionCompiler implements ExpressionCompiler {
  WebExpressionCompiler(this._generator);

  final ResidentCompiler _generator;

  @override
  Future<ExpressionCompilationResult> compileExpressionToJs(
    String isolateId,
    String libraryUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) async {
    final CompilerOutput compilerOutput = await _generator.compileExpressionToJs(libraryUri,
        line, column, jsModules, jsFrameValues, moduleName, expression);

    if (compilerOutput != null && compilerOutput.outputFilename != null) {
      final String content = utf8.decode(
          globals.fs.file(compilerOutput.outputFilename).readAsBytesSync());
      return ExpressionCompilationResult(
          content, compilerOutput.errorCount > 0);
    }

    return ExpressionCompilationResult(
      'InternalError: frontend server failed to compile \'$expression\'', true);
  }
}

/// A web server which handles serving JavaScript and assets.
///
/// This is only used in development mode.
class WebAssetServer implements AssetReader {
  @visibleForTesting
  WebAssetServer(
    this._httpServer,
    this._packages,
    this.internetAddress,
    this._modules,
    this._digests,
    this._buildInfo,
  );

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _kDefaultMimeType = 'application/octet-stream';

  final Map<String, String> _modules;
  final Map<String, String> _digests;

  void performRestart(List<String> modules) {
    for (final String module in modules) {
      // We skip computing the digest by using the hashCode of the underlying buffer.
      // Whenever a file is updated, the corresponding Uint8List.view it corresponds
      // to will change.
      final String moduleName = module.startsWith('/')
        ? module.substring(1)
        : module;
      final String name = moduleName.replaceAll('.lib.js', '');
      final String path = moduleName.replaceAll('.js', '');
      _modules[name] = path;
      _digests[name] = _files[moduleName].hashCode.toString();
    }
  }

  /// Start the web asset server on a [hostname] and [port].
  ///
  /// If [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  ///
  /// Unhandled exceptions will throw a [ToolExit] with the error and stack
  /// trace.
  static Future<WebAssetServer> start(
    ChromiumLauncher chromiumLauncher,
    String hostname,
    int port,
    UrlTunneller urlTunneller,
    bool useSseForDebugProxy,
    bool useSseForDebugBackend,
    BuildInfo buildInfo,
    bool enableDwds,
    Uri entrypoint,
    ExpressionCompiler expressionCompiler, {
    bool testMode = false,
    DwdsLauncher dwdsLauncher = Dwds.start,
  }) async {
    try {
      InternetAddress address;
      if (hostname == 'any') {
        address = InternetAddress.anyIPv4;
      } else {
        address = (await InternetAddress.lookup(hostname)).first;
      }
      final HttpServer httpServer = await HttpServer.bind(address, port);
      // Allow rendering in a iframe.
      httpServer.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');

      final PackageConfig packageConfig = await loadPackageConfigWithLogging(
        globals.fs.file(buildInfo.packagesPath),
        logger: globals.logger,
      );
      final Map<String, String> digests = <String, String>{};
      final Map<String, String> modules = <String, String>{};
      final WebAssetServer server = WebAssetServer(
        httpServer,
        packageConfig,
        address,
        modules,
        digests,
        buildInfo,
      );
      if (testMode) {
        return server;
      }

      // In release builds deploy a simpler proxy server.
      if (buildInfo.mode != BuildMode.debug) {
        final ReleaseAssetServer releaseAssetServer = ReleaseAssetServer(
          entrypoint,
          fileSystem: globals.fs,
          platform: globals.platform,
          flutterRoot: Cache.flutterRoot,
          webBuildDirectory: getWebBuildDirectory(),
        );
        shelf.serveRequests(httpServer, releaseAssetServer.handle);
        return server;
      }
      // Return the set of all active modules. This is populated by the
      // frontend_server update logic.
      Future<Map<String, String>> moduleProvider(String path) async {
        return modules;
      }
      // Return a version string for all active modules. This is populated
      // along with the `moduleProvider` update logic.
      Future<Map<String, String>> digestProvider(String path) async {
        return digests;
      }
      // Return the module name for a given server path. These are the names
      // used by the browser to request JavaScript files.
      String moduleForServerPath(String serverPath) {
        if (serverPath.endsWith('.lib.js')) {
          serverPath = serverPath.startsWith('/')
            ? serverPath.substring(1)
            : serverPath;
          return serverPath.replaceAll('.lib.js', '');
        }
        return null;
      }
      // Return the server path for modules. These are the JavaScript file names
      // output by the frontend_server.
      String serverPathForModule(String module) {
        return '$module.lib.js';
      }
      // Return the server path for modules or resources that have an
      // org-dartlang-app scheme.
      String serverPathForAppUri(String appUri) {
        if (appUri.startsWith('org-dartlang-app:')) {
          return Uri.parse(appUri).path.substring(1);
        }
        return null;
      }

      // In debug builds, spin up DWDS and the full asset server.
      final Dwds dwds = await dwdsLauncher(
        assetReader: server,
        enableDebugExtension: true,
        buildResults: const Stream<BuildResult>.empty(),
        chromeConnection: () async {
          final Chromium chromium = await chromiumLauncher.connectedInstance;
          return chromium.chromeConnection;
        },
        hostname: hostname,
        urlEncoder: urlTunneller,
        enableDebugging: true,
        useSseForDebugProxy: useSseForDebugProxy,
        useSseForDebugBackend: useSseForDebugBackend,
        serveDevTools: false,
        logWriter: (Level logLevel, String message) => globals.printTrace(message),
        loadStrategy: RequireStrategy(
          ReloadConfiguration.none,
          '.lib.js',
          moduleProvider,
          digestProvider,
          moduleForServerPath,
          serverPathForModule,
          serverPathForAppUri,
        ),
        useFileProvider: true,
        expressionCompiler: expressionCompiler
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

  final BuildInfo _buildInfo;
  final HttpServer _httpServer;
  // If holding these in memory is too much overhead, this can be switched to a
  // RandomAccessFile and read on demand.
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final Map<String, Uint8List> _sourcemaps = <String, Uint8List>{};
  final Map<String, Uint8List> _metadataFiles = <String, Uint8List>{};
  String _mergedMetadata;
  final PackageConfig _packages;
  final InternetAddress internetAddress;
  /* late final */ Dwds dwds;
  Directory entrypointCacheDirectory;

  @visibleForTesting
  HttpHeaders get defaultResponseHeaders => _httpServer.defaultResponseHeaders;

  @visibleForTesting
  Uint8List getFile(String path) => _files[path];

  @visibleForTesting
  Uint8List getSourceMap(String path) => _sourcemaps[path];

  @visibleForTesting
  Uint8List getMetadata(String path) => _metadataFiles[path];

  // handle requests for JavaScript source, dart sources maps, or asset files.
  @visibleForTesting
  Future<shelf.Response> handleRequest(shelf.Request request) async {
    String requestPath = request.url.path;
    while (requestPath.startsWith('/')) {
      requestPath = requestPath.substring(1);
    }
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
      } else {
        headers[HttpHeaders.contentTypeHeader] = 'text/html';
        headers[HttpHeaders.contentLengthHeader] = _kDefaultIndex.length.toString();
        return shelf.Response.ok(_kDefaultIndex, headers: headers);
      }
    }

    // Track etag headers for better caching of resources.
    final String ifNoneMatch = request.headers[HttpHeaders.ifNoneMatchHeader];
    headers[HttpHeaders.cacheControlHeader] = 'max-age=0, must-revalidate';

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    final String webServerPath = requestPath.replaceFirst('.dart.js', '.dart.lib.js');
    if (_files.containsKey(requestPath) || _files.containsKey(webServerPath)) {
      final List<int> bytes = getFile(requestPath)  ?? getFile(webServerPath);
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

    // If this is a metadata file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (_metadataFiles.containsKey(requestPath)) {
      final List<int> bytes = getMetadata(requestPath);
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
        .uri.resolve(requestPath.replaceFirst('assets/', ''));
      file = globals.fs.file(potential);
    }

    if (!file.existsSync()) {
      final Uri webPath = globals.fs.currentDirectory
        .childDirectory('web')
        .uri.resolve(requestPath);
      file = globals.fs.file(webPath);
    }

    if (!file.existsSync()) {
      return shelf.Response.notFound('');
    }

    // For real files, use a serialized file stat plus path as a revision.
    // This allows us to update between canvaskit and non-canvaskit SDKs.
    final String etag = file.lastModifiedSync().toIso8601String()
      + Uri.encodeComponent(file.path);
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
    writeBytes(filePath, utf8.encode(contents) as Uint8List);
  }

  void writeBytes(String filePath, Uint8List contents) {
    _files[filePath] = contents;
  }

  /// Update the in-memory asset server with the provided source and manifest files.
  ///
  /// Returns a list of updated modules.
  List<String> write(
      File codeFile,
      File manifestFile,
      File sourcemapFile,
      File metadataFile) {
    final List<String> modules = <String>[];
    final Uint8List codeBytes = codeFile.readAsBytesSync();
    final Uint8List sourcemapBytes = sourcemapFile.readAsBytesSync();
    final Uint8List metadataBytes = metadataFile.readAsBytesSync();
    final Map<String, dynamic> manifest = castStringKeyedMap(json.decode(manifestFile.readAsStringSync()));
    for (final String filePath in manifest.keys) {
      if (filePath == null) {
        globals.printTrace('Invalid manfiest file: $filePath');
        continue;
      }
      final Map<String, dynamic> offsets = castStringKeyedMap(manifest[filePath]);
      final List<int> codeOffsets = (offsets['code'] as List<dynamic>).cast<int>();
      final List<int> sourcemapOffsets = (offsets['sourcemap'] as List<dynamic>).cast<int>();
      final List<int> metadataOffsets = (offsets['metadata'] as List<dynamic>).cast<int>();
      if (codeOffsets.length != 2 ||
          sourcemapOffsets.length != 2 ||
          metadataOffsets.length != 2) {
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
      final String fileName = filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;
      _files[fileName] = byteView;

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
      final String sourcemapName = '$fileName.map';
      _sourcemaps[sourcemapName] = sourcemapView;

      final int metadataStart = metadataOffsets[0];
      final int metadataEnd = metadataOffsets[1];
      if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
        globals.printTrace('Invalid byte index: [$metadataStart, $metadataEnd]');
        continue;
      }
      final Uint8List metadataView = Uint8List.view(
        metadataBytes.buffer,
        metadataStart,
        metadataEnd - metadataStart,
      );
      final String metadataName = '$fileName.metadata';
      _metadataFiles[metadataName] = metadataView;

      modules.add(fileName);
    }

    _mergedMetadata = _metadataFiles.values
      .map((Uint8List encoded) => utf8.decode(encoded))
      .join('\n');

    return modules;
  }

  /// Whether to use the cavaskit SDK for rendering.
  bool canvasKitRendering = false;

  // Attempt to resolve `path` to a dart file.
  File _resolveDartFile(String path) {
    // Return the actual file objects so that local engine changes are automatically picked up.
    switch (path) {
      case 'dart_sdk.js':
        if (_buildInfo.nullSafetyMode == NullSafetyMode.unsound) {
          return globals.fs.file(canvasKitRendering
            ? globals.artifacts.getArtifactPath(Artifact.webPrecompiledCanvaskitSdk)
            : globals.artifacts.getArtifactPath(Artifact.webPrecompiledSdk));
        } else {
          return globals.fs.file(canvasKitRendering
            ? globals.artifacts.getArtifactPath(Artifact.webPrecompiledCanvaskitSoundSdk)
            : globals.artifacts.getArtifactPath(Artifact.webPrecompiledSoundSdk));
        }
        break;
      case 'dart_sdk.js.map':
        if (_buildInfo.nullSafetyMode == NullSafetyMode.unsound) {
          return globals.fs.file(canvasKitRendering
            ? globals.artifacts.getArtifactPath(Artifact.webPrecompiledCanvaskitSdkSourcemaps)
            : globals.artifacts.getArtifactPath(Artifact.webPrecompiledSdkSourcemaps));
        } else {
          return globals.fs.file(canvasKitRendering
            ? globals.artifacts.getArtifactPath(Artifact.webPrecompiledCanvaskitSoundSdkSourcemaps)
            : globals.artifacts.getArtifactPath(Artifact.webPrecompiledSoundSdkSourcemaps));
        }
    }
    // This is the special generated entrypoint.
    if (path == 'web_entrypoint.dart') {
      return entrypointCacheDirectory.childFile('web_entrypoint.dart');
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
      final Uri filePath = _packages.resolve(Uri(
        scheme: 'package', pathSegments: segments.skip(1)));
      if (filePath != null) {
        final File packageFile = globals.fs.file(filePath);
        if (packageFile.existsSync()) {
          return packageFile;
        }
      }
    }

    // Otherwise it must be a Dart SDK source or a Flutter Web SDK source.
    final Directory dartSdkParent = globals.fs
      .directory(globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath))
      .parent;
    final File dartSdkFile = globals.fs.file(dartSdkParent.uri.resolve(path));
    if (dartSdkFile.existsSync()) {
      return dartSdkFile;
    }

    final Directory flutterWebSdk = globals.fs.directory(globals.artifacts
      .getArtifactPath(Artifact.flutterWebSdk));
    final File webSdkFile = globals.fs.file(flutterWebSdk.uri.resolve(path));

    return webSdkFile;
  }

  @override
  Future<String> dartSourceContents(String serverPath) async {
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

  @override
  Future<String> metadataContents(String serverPath) async {
    if (serverPath == 'main_module.ddc_merged_metadata') {
      return _mergedMetadata;
    }
    if (_metadataFiles.containsKey(serverPath)) {
      return utf8.decode(_metadataFiles[serverPath]);
    }
    return null;
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
    @required this.useSseForDebugProxy,
    @required this.useSseForDebugBackend,
    @required this.buildInfo,
    @required this.enableDwds,
    @required this.entrypoint,
    @required this.expressionCompiler,
    @required this.chromiumLauncher,
    @required this.nullAssertions,
    this.testMode = false,
  });

  final Uri entrypoint;
  final String hostname;
  final int port;
  final String packagesFilePath;
  final UrlTunneller urlTunneller;
  final bool useSseForDebugProxy;
  final bool useSseForDebugBackend;
  final BuildInfo buildInfo;
  final bool enableDwds;
  final bool testMode;
  final ExpressionCompiler expressionCompiler;
  final ChromiumLauncher chromiumLauncher;
  final bool nullAssertions;

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

  @override
  PackageConfig lastPackageConfig;

  // We do not evict assets on the web.
  @override
  Set<String> get assetPathsToEvict => const <String>{};

  @override
  Uri get baseUri => _baseUri;
  Uri _baseUri;

  @override
  Future<Uri> create() async {
    webAssetServer = await WebAssetServer.start(
      chromiumLauncher,
      hostname,
      port,
      urlTunneller,
      useSseForDebugProxy,
      useSseForDebugBackend,
      buildInfo,
      enableDwds,
      entrypoint,
      expressionCompiler,
      testMode: testMode,
    );
    if (buildInfo.dartDefines.contains('FLUTTER_WEB_USE_SKIA=true')) {
      webAssetServer.canvasKitRendering = true;
    }
    if (hostname == 'any') {
      _baseUri = Uri.http('localhost:$port', '');
    } else {
      _baseUri = Uri.http('$hostname:$port', '');
    }
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
    Uri mainUri,
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
    @required PackageConfig packageConfig,
  }) async {
    assert(trackWidgetCreation != null);
    assert(generator != null);
    lastPackageConfig = packageConfig;
    final File mainFile = globals.fs.file(mainUri);
    final String outputDirectoryPath = mainFile.parent.path;

    if (bundleFirstUpload) {
      webAssetServer.entrypointCacheDirectory = globals.fs.directory(outputDirectoryPath);
      generator.addFileSystemRoot(outputDirectoryPath);
      final String entrypoint = globals.fs.path.basename(mainFile.path);
      webAssetServer.writeBytes(entrypoint, mainFile.readAsBytesSync());
      webAssetServer.writeBytes('require.js', requireJS.readAsBytesSync());
      webAssetServer.writeBytes('stack_trace_mapper.js', stackTraceMapper.readAsBytesSync());
      webAssetServer.writeFile('manifest.json', '{"info":"manifest not generated in run mode."}');
      webAssetServer.writeFile('flutter_service_worker.js', '// Service worker not loaded in run mode.');
      webAssetServer.writeFile(
        'main.dart.js',
        generateBootstrapScript(
          requireUrl: 'require.js',
          mapperUrl: 'stack_trace_mapper.js',
        ),
      );
      webAssetServer.writeFile(
        'main_module.bootstrap.js',
        generateMainModule(
          entrypoint: entrypoint,
          nullAssertions: nullAssertions,
        ),
      );
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
      Uri(
        scheme: 'org-dartlang-app',
        path: '/' + mainUri.pathSegments.last,
      ),
      invalidatedFiles,
      outputPath: dillOutputPath ??
        getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation),
      packageConfig: packageConfig,
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
    File metadataFile;
    List<String> modules;
    try {
      final Directory parentDirectory = globals.fs.directory(outputDirectoryPath);
      codeFile = parentDirectory.childFile('${compilerOutput.outputFilename}.sources');
      manifestFile = parentDirectory.childFile('${compilerOutput.outputFilename}.json');
      sourcemapFile = parentDirectory.childFile('${compilerOutput.outputFilename}.map');
      metadataFile = parentDirectory.childFile('${compilerOutput.outputFilename}.metadata');
      modules = webAssetServer.write(codeFile, manifestFile, sourcemapFile, metadataFile);
    } on FileSystemException catch (err) {
      throwToolExit('Failed to load recompiled sources:\n$err');
    }
    webAssetServer.performRestart(modules);
    return UpdateFSReport(
      success: true,
      syncedBytes: codeFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length,
    );
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

class ReleaseAssetServer {
  ReleaseAssetServer(this.entrypoint, {
    @required FileSystem fileSystem,
    @required String webBuildDirectory,
    @required String flutterRoot,
    @required Platform platform,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _flutterRoot = flutterRoot,
       _webBuildDirectory = webBuildDirectory,
       _fileSystemUtils = FileSystemUtils(fileSystem: fileSystem, platform: platform);

  final Uri entrypoint;
  final String _flutterRoot;
  final String _webBuildDirectory;
  final FileSystem _fileSystem;
  final FileSystemUtils _fileSystemUtils;
  final Platform _platform;

  // Locations where source files, assets, or source maps may be located.
  List<Uri> _searchPaths() => <Uri>[
    _fileSystem.directory(_webBuildDirectory).uri,
    _fileSystem.directory(_flutterRoot).uri,
    _fileSystem.directory(_flutterRoot).parent.uri,
    _fileSystem.currentDirectory.uri,
    _fileSystem.directory(_fileSystemUtils.homeDirPath).uri,
  ];

  Future<shelf.Response> handle(shelf.Request request) async {
    Uri fileUri;
    if (request.url.toString() == 'main.dart') {
      fileUri = entrypoint;
    } else {
      for (final Uri uri in _searchPaths()) {
        final Uri potential = uri.resolve(request.url.path);
        if (potential == null || !_fileSystem.isFileSync(
          potential.toFilePath(windows: _platform.isWindows))) {
          continue;
        }
        fileUri = potential;
        break;
      }
    }
    if (fileUri != null) {
      final File file = _fileSystem.file(fileUri);
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
      final File file = _fileSystem.file(_fileSystem.path.join(_webBuildDirectory, 'index.html'));
      return shelf.Response.ok(file.readAsBytesSync(), headers: <String, String>{
        'Content-Type': 'text/html',
      });
    }
    return shelf.Response.notFound('');
  }
}
