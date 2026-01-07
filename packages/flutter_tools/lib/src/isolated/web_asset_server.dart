// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dwds/data/build_result.dart';
import 'package:dwds/dwds.dart';
import 'package:logging/logging.dart' as logging;
import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;
import 'package:package_config/package_config.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf;

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../web/bootstrap.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web/devfs_proxy.dart';
import '../web/memory_fs.dart';
import '../web/module_metadata.dart';
import '../web/web_constants.dart';
import '../web_template.dart';
import 'proxy_middleware.dart';
import 'release_asset_server.dart';
import 'web_server_utilities.dart';

// A minimal index for projects that do not yet support web. A meta tag is used
// to ensure loaded scripts are always parsed as UTF-8.
const _kDefaultIndex = '''
<html>
    <head>
        <meta charset='utf-8'>
        <base href="/">
    </head>
    <body>
        <script src="main.dart.js"></script>
    </body>
</html>
''';

typedef DwdsLauncher =
    Future<Dwds> Function({
      required AssetReader assetReader,
      required Stream<BuildResult> buildResults,
      required ConnectionProvider chromeConnection,
      required ToolConfiguration toolConfiguration,
      bool useDwdsWebSocketConnection,
    });

const kLuciEnvName = 'LUCI_CONTEXT';

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
    this._ddcModuleSystem,
    this._canaryFeatures, {
    required this.webRenderer,
    required this.useLocalCanvasKit,
    required this.fileSystem,
  }) : basePath = WebTemplate.baseHref(htmlTemplate(fileSystem, 'index.html', _kDefaultIndex)) {
    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (_ddcModuleSystem) {
      assert(_canaryFeatures);
    }
  }

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const _kDefaultMimeType = 'application/octet-stream';

  final Map<String, String> _modules;
  final Map<String, String> _digests;

  int get selectedPort => _httpServer.port;

  /// Given a list of [modules] that need to be loaded, compute module names and
  /// digests.
  void updateModulesAndDigests(List<String> modules) {
    for (final module in modules) {
      // We skip computing the digest by using the hashCode of the underlying buffer.
      // Whenever a file is updated, the corresponding Uint8List.view it corresponds
      // to will change.
      final String moduleName = module.startsWith('/') ? module.substring(1) : module;
      final String name = moduleName.replaceAll('.lib.js', '');
      final String path = moduleName.replaceAll('.js', '');
      _modules[name] = path;
      _digests[name] = _webMemoryFS.files[moduleName].hashCode.toString();
    }
  }

  static const _reloadedSourcesFileName = 'reloaded_sources.json';

  /// Given a list of [modules] that need to be reloaded during a hot restart or
  /// hot reload, writes a file that contains a list of objects each with three
  /// fields:
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle. To support embedded libraries, the path should include the
  /// `baseUri` of the web server.
  /// `module`: The name of the library bundle in `src`.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  ///
  /// For example:
  /// ```json
  /// [
  ///   {
  ///     "src": "<baseUri>/<file_name>",
  ///     "module": "<module_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// The path of the output file should stay consistent across the lifetime of
  /// the app.
  void writeReloadedSources(List<String> modules) {
    final moduleToLibrary = <Map<String, Object>>[];
    for (final module in modules) {
      final metadata = ModuleMetadata.fromJson(
        json.decode(utf8.decode(_webMemoryFS.metadataFiles['$module.metadata']!.toList()))
            as Map<String, dynamic>,
      );
      final List<String> libraries = metadata.libraries.keys.toList();
      final moduleUri = '$baseUri/$module';
      moduleToLibrary.add(<String, Object>{
        'src': moduleUri,
        'module': metadata.name,
        'libraries': libraries,
      });
    }
    writeFile(_reloadedSourcesFileName, json.encode(moduleToLibrary));
  }

  @visibleForTesting
  List<String> write(File codeFile, File manifestFile, File sourcemapFile, File metadataFile) {
    return _webMemoryFS.write(codeFile, manifestFile, sourcemapFile, metadataFile);
  }

  Uri get baseUri => _baseUri;
  late Uri _baseUri;

  /// Start the web asset server with configuration provided by [webDevServerConfig].
  ///
  /// If [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  ///
  /// Unhandled exceptions will throw a [ToolExit] with the error and stack
  /// trace.
  static Future<WebAssetServer> start(
    ChromiumLauncher? chromiumLauncher,
    UrlTunneller? urlTunneller,
    bool useSseForDebugProxy,
    bool useSseForDebugBackend,
    bool useSseForInjectedClient,
    BuildInfo buildInfo,
    bool enableDwds,
    DartDevelopmentServiceConfiguration ddsConfig,
    Uri entrypoint,
    ExpressionCompiler? expressionCompiler, {
    required bool crossOriginIsolation,
    required WebDevServerConfig webDevServerConfig,
    required WebRendererMode webRenderer,
    required bool isWasm,
    required bool useLocalCanvasKit,
    bool testMode = false,
    DwdsLauncher dwdsLauncher = Dwds.start,
    // TODO(markzipan): Make sure this default value aligns with that in the debugger options.
    bool ddcModuleSystem = false,
    bool canaryFeatures = false,
    bool useDwdsWebSocketConnection = false,
    required FileSystem fileSystem,
    required Logger logger,
    required Platform platform,
    bool shouldEnableMiddleware = true,
  }) async {
    final String hostname = webDevServerConfig.host;
    final int port = webDevServerConfig.port;
    final HttpsConfig? httpsConfig = webDevServerConfig.https;
    final Map<String, String> extraHeaders = webDevServerConfig.headers;
    final List<ProxyRule> proxy = webDevServerConfig.proxy;

    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (ddcModuleSystem) {
      assert(canaryFeatures);
    }
    final InternetAddress address;
    if (hostname == webDevAnyHostDefault) {
      address = InternetAddress.anyIPv4;
    } else {
      address = (await InternetAddress.lookup(hostname)).first;
    }
    HttpServer? httpServer;
    const kMaxRetries = 4;
    for (var i = 0; i <= kMaxRetries; i++) {
      try {
        if (httpsConfig != null) {
          final serverContext = SecurityContext()
            ..useCertificateChain(httpsConfig.certPath)
            ..usePrivateKey(httpsConfig.certKeyPath);
          httpServer = await HttpServer.bindSecure(address, port, serverContext);
        } else {
          httpServer = await HttpServer.bind(address, port);
        }
        break;
      } on SocketException catch (e, s) {
        if (i >= kMaxRetries) {
          logger.printError('Failed to bind web development server:\n$e', stackTrace: s);
          throwToolExit('Failed to bind web development server:\n$e');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    // Allow rendering in a iframe.
    httpServer!.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');

    if (crossOriginIsolation) {
      for (final MapEntry<String, String> header in kCrossOriginIsolationHeaders.entries) {
        httpServer.defaultResponseHeaders.add(header.key, header.value);
      }
    }

    for (final MapEntry<String, String> header in extraHeaders.entries) {
      httpServer.defaultResponseHeaders.add(header.key, header.value);
    }

    final PackageConfig packageConfig = buildInfo.packageConfig;
    final modules = <String, String>{};
    final digests = <String, String>{};
    final server = WebAssetServer(
      httpServer,
      packageConfig,
      address,
      modules,
      digests,
      ddcModuleSystem,
      canaryFeatures,
      webRenderer: webRenderer,
      useLocalCanvasKit: useLocalCanvasKit,
      fileSystem: fileSystem,
    );
    final int selectedPort = server.selectedPort;

    final cleanHost = hostname == webDevAnyHostDefault ? 'localhost' : hostname;
    final scheme = httpsConfig != null ? 'https' : 'http';
    server._baseUri = Uri(
      scheme: scheme,
      host: cleanHost,
      port: selectedPort,
      path: server.basePath,
    );
    if (testMode) {
      return server;
    }

    // In release builds (or wasm builds) deploy a simpler proxy server.
    if (buildInfo.mode != BuildMode.debug || isWasm) {
      final releaseAssetServer = ReleaseAssetServer(
        entrypoint,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: Cache.flutterRoot,
        webBuildDirectory: getWebBuildDirectory(),
        basePath: server.basePath,
        needsCoopCoep: crossOriginIsolation,
      );
      runZonedGuarded(
        () {
          shelf.serveRequests(httpServer!, releaseAssetServer.handle);
        },
        (Object e, StackTrace s) {
          logger.printTrace('Release asset server: error serving requests: $e:$s');
        },
      );
      return server;
    }

    // Return a version string for all active modules. This is populated
    // along with the `moduleProvider` update logic.
    Future<Map<String, String>> digestProvider() async => digests;

    // Ensure dwds is present and provide middleware to avoid trying to
    // load the through the isolate APIs.
    final Directory directory = await loadDwdsDirectory(fileSystem, logger);
    shelf.Handler middleware(FutureOr<shelf.Response> Function(shelf.Request) innerHandler) {
      return (shelf.Request request) async {
        if (request.url.path.endsWith('dwds/src/injected/client.js')) {
          final Uri uri = directory.uri.resolve('src/injected/client.js');
          final String result = await fileSystem.file(uri.toFilePath()).readAsString();
          return shelf.Response.ok(
            result,
            headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/javascript'},
          );
        }
        return innerHandler(request);
      };
    }

    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen((logging.LogRecord event) => log(logger, event));

    // In debug builds, spin up DWDS and the full asset server.
    final Dwds dwds = await dwdsLauncher(
      assetReader: server,
      buildResults: const Stream<BuildResult>.empty(),
      chromeConnection: () async {
        final Chromium chromium = await chromiumLauncher!.connectedInstance;
        return chromium.chromeConnection;
      },
      toolConfiguration: ToolConfiguration(
        loadStrategy: ddcModuleSystem
            ? FrontendServerDdcLibraryBundleStrategyProvider(
                ReloadConfiguration.none,
                server,
                PackageUriMapper(packageConfig),
                digestProvider,
                BuildSettings(
                  appEntrypoint: packageConfig.toPackageUri(
                    fileSystem.file(entrypoint).absolute.uri,
                  ),
                  canaryFeatures: canaryFeatures,
                ),
                packageConfigPath: buildInfo.packageConfigPath,
                reloadedSourcesUri: server._baseUri.replace(
                  pathSegments: List<String>.from(server._baseUri.pathSegments)
                    ..add(_reloadedSourcesFileName),
                ),
              ).strategy
            : FrontendServerRequireStrategyProvider(
                ReloadConfiguration.none,
                server,
                PackageUriMapper(packageConfig),
                digestProvider,
                BuildSettings(
                  appEntrypoint: packageConfig.toPackageUri(
                    fileSystem.file(entrypoint).absolute.uri,
                  ),
                  canaryFeatures: canaryFeatures,
                ),
                packageConfigPath: buildInfo.packageConfigPath,
              ).strategy,
        debugSettings: DebugSettings(
          enableDebugExtension: true,
          urlEncoder: urlTunneller,
          useSseForDebugProxy: useSseForDebugProxy,
          useSseForDebugBackend: useSseForDebugBackend,
          useSseForInjectedClient: useSseForInjectedClient,
          expressionCompiler: expressionCompiler,
          ddsConfiguration: ddsConfig,
        ),
        appMetadata: AppMetadata(hostname: hostname),
      ),
      // Use DWDS WebSocket-based connection instead of Chrome-based connection for debugging
      useDwdsWebSocketConnection: useDwdsWebSocketConnection,
    );
    var pipeline = const shelf.Pipeline();
    if (shouldEnableMiddleware) {
      pipeline = pipeline.addMiddleware(middleware).addMiddleware(dwds.middleware);
    }
    pipeline = pipeline.addMiddleware(proxyMiddleware(proxy, globals.logger));
    final shelf.Handler dwdsHandler = pipeline.addHandler(server.handleRequest);
    final shelf.Cascade cascade = shelf.Cascade().add(dwds.handler).add(dwdsHandler);
    runZonedGuarded(
      () {
        shelf.serveRequests(httpServer!, cascade.handler);
      },
      (Object e, StackTrace s) {
        logger.printTrace('Dwds server: error serving requests: $e:$s');
      },
    );
    server.dwds = dwds;
    server._dwdsInit = true;
    return server;
  }

  final bool _ddcModuleSystem;
  final bool _canaryFeatures;
  final HttpServer _httpServer;
  final _webMemoryFS = WebMemoryFS();
  final PackageConfig _packages;
  final InternetAddress internetAddress;
  late final Dwds dwds;
  late Directory entrypointCacheDirectory;
  var _dwdsInit = false;
  WebMemoryFS get webMemoryFS => _webMemoryFS;

  @visibleForTesting
  HttpHeaders get defaultResponseHeaders => _httpServer.defaultResponseHeaders;

  @visibleForTesting
  Uint8List? getFile(String path) => _webMemoryFS.files[path];

  @visibleForTesting
  Uint8List? getSourceMap(String path) => _webMemoryFS.sourcemaps[path];

  @visibleForTesting
  Uint8List? getMetadata(String path) => _webMemoryFS.metadataFiles[path];

  /// The base path to serve from.
  ///
  /// It should have no leading or trailing slashes.
  @visibleForTesting
  @override
  String basePath;

  // handle requests for JavaScript source, dart sources maps, or asset files.
  @visibleForTesting
  Future<shelf.Response> handleRequest(shelf.Request request) async {
    if (request.method != 'GET') {
      // Assets are served via GET only.
      return shelf.Response.notFound('');
    }

    final String? requestPath = stripBasePath(request.url.path, basePath);

    if (requestPath == null) {
      return shelf.Response.notFound('');
    }

    // If the response is `/`, then we are requesting the index file.
    if (requestPath == '/' || requestPath.isEmpty) {
      return _serveIndexHtml();
    }

    if (requestPath == 'flutter_bootstrap.js') {
      return _serveFlutterBootstrapJs();
    }

    final headers = <String, String>{};

    // Track etag headers for better caching of resources.
    final String? ifNoneMatch = request.headers[HttpHeaders.ifNoneMatchHeader];
    headers[HttpHeaders.cacheControlHeader] = 'max-age=0, must-revalidate';

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    final String webServerPath = requestPath.replaceFirst('.dart.js', '.dart.lib.js');
    if (_webMemoryFS.files.containsKey(requestPath) ||
        _webMemoryFS.files.containsKey(webServerPath)) {
      final List<int>? bytes = getFile(requestPath) ?? getFile(webServerPath);
      // Use the underlying buffer hashCode as a revision string. This buffer is
      // replaced whenever the frontend_server produces new output files, which
      // will also change the hashCode.
      final etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentTypeHeader] = 'application/javascript';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }
    // If this is a sourcemap file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (_webMemoryFS.sourcemaps.containsKey(requestPath)) {
      final List<int>? bytes = getSourceMap(requestPath);
      final etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }

    // If this is a metadata file, then it might be in the in-memory cache.
    // Attempt to lookup the file by URI.
    if (_webMemoryFS.metadataFiles.containsKey(requestPath)) {
      final List<int>? bytes = getMetadata(requestPath);
      final etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }

    File file = _resolveDartFile(requestPath);

    if (!file.existsSync() && requestPath.startsWith('canvaskit/')) {
      final Directory canvasKitDirectory = fileSystem.directory(
        fileSystem.path.join(
          globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path,
          'canvaskit',
        ),
      );
      final Uri potential = canvasKitDirectory.uri.resolve(
        requestPath.replaceFirst('canvaskit/', ''),
      );
      file = fileSystem.file(potential);
    }

    // If all of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    if (!file.existsSync()) {
      final Uri potential = fileSystem
          .directory(getAssetBuildDirectory())
          .uri
          .resolve(requestPath.replaceFirst('assets/', ''));
      file = fileSystem.file(potential);
    }

    if (!file.existsSync()) {
      final Uri webPath = fileSystem.currentDirectory
          .childDirectory('web')
          .uri
          .resolve(requestPath);
      file = fileSystem.file(webPath);
    }

    if (!file.existsSync()) {
      // Paths starting with these prefixes should've been resolved above.
      if (requestPath.startsWith('assets/') ||
          requestPath.startsWith('packages/') ||
          requestPath.startsWith('canvaskit/')) {
        return shelf.Response.notFound('');
      }
      return _serveIndexHtml();
    }

    // For real files, use a serialized file stat plus path as a revision.
    // This allows us to update between canvaskit and non-canvaskit SDKs.
    final String etag = file.lastModifiedSync().toIso8601String() + Uri.encodeComponent(file.path);
    if (ifNoneMatch == etag) {
      return shelf.Response.notModified();
    }

    final int length = file.lengthSync();
    // Attempt to determine the file's mime type. if this is not provided some
    // browsers will refuse to render images/show video etc. If the tool
    // cannot determine a mime type, fall back to application/octet-stream.
    final String mimeType =
        mime.lookupMimeType(
          file.path,
          headerBytes: await file.openRead(0, mime.defaultMagicNumbersMaxLength).first,
        ) ??
        _kDefaultMimeType;

    headers[HttpHeaders.contentLengthHeader] = length.toString();
    headers[HttpHeaders.contentTypeHeader] = mimeType;
    headers[HttpHeaders.etagHeader] = etag;
    return shelf.Response.ok(file.openRead(), headers: headers);
  }

  /// Tear down the http server running.
  Future<void> dispose() async {
    if (_dwdsInit) {
      await dwds.stop();
    }
    return _httpServer.close();
  }

  /// Write a single file into the in-memory cache.
  void writeFile(String filePath, String contents) {
    writeBytes(filePath, const Utf8Encoder().convert(contents));
  }

  void writeBytes(String filePath, Uint8List contents) {
    _webMemoryFS.files[filePath] = contents;
  }

  /// Determines what rendering backed to use.
  final WebRendererMode webRenderer;

  final bool useLocalCanvasKit;

  final FileSystem fileSystem;

  String get _buildConfigString {
    final buildConfig = <String, Object>{
      'engineRevision': globals.flutterVersion.engineRevision,
      'builds': <Object>[
        <String, Object>{
          'compileTarget': 'dartdevc',
          'renderer': webRenderer.name,
          'mainJsPath': 'main.dart.js',
        },
      ],
      if (useLocalCanvasKit) 'useLocalCanvasKit': true,
    };
    return '''
if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = ${jsonEncode(buildConfig)};
''';
  }

  File get _flutterJsFile => fileSystem.file(
    fileSystem.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      'flutter.js',
    ),
  );

  String get _flutterBootstrapJsContent {
    final WebTemplate bootstrapTemplate = getWebTemplate(
      fileSystem,
      'flutter_bootstrap.js',
      generateDefaultFlutterBootstrapScript(includeServiceWorkerSettings: false),
    );
    return bootstrapTemplate.withSubstitutions(
      baseHref: '/',
      serviceWorkerVersion: null,
      buildConfig: _buildConfigString,
      flutterJsFile: _flutterJsFile,
    );
  }

  shelf.Response _serveFlutterBootstrapJs() {
    return shelf.Response.ok(
      _flutterBootstrapJsContent,
      headers: <String, String>{HttpHeaders.contentTypeHeader: 'text/javascript'},
    );
  }

  shelf.Response _serveIndexHtml() {
    final WebTemplate indexHtml = getWebTemplate(fileSystem, 'index.html', _kDefaultIndex);
    return shelf.Response.ok(
      indexHtml.withSubstitutions(
        // Currently, we don't support --base-href for the "run" command.
        baseHref: '/',
        // Currently, we don't support --static-assets-url for the "run" command.
        staticAssetsUrl: '/',
        serviceWorkerVersion: null,
        buildConfig: _buildConfigString,
        flutterJsFile: _flutterJsFile,
        flutterBootstrapJs: _flutterBootstrapJsContent,
      ),
      encoding: utf8,
      headers: <String, String>{HttpHeaders.contentTypeHeader: 'text/html'},
    );
  }

  // Attempt to resolve `path` to a dart file.
  File _resolveDartFile(String path) {
    // Return the actual file objects so that local engine changes are automatically picked up.
    switch (path) {
      case 'dart_sdk.js':
        return _resolveDartSdkJsFile;
      case 'dart_sdk.js.map':
        return _resolveDartSdkJsMapFile;
    }
    // This is the special generated entrypoint.
    if (path == 'web_entrypoint.dart') {
      return entrypointCacheDirectory.childFile('web_entrypoint.dart');
    }

    // If this is a dart file, it must be on the local file system and is
    // likely coming from a source map request. The tool doesn't currently
    // consider the case of Dart files as assets.
    final File dartFile = fileSystem.file(fileSystem.currentDirectory.uri.resolve(path));
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
      final Uri? filePath = _packages.resolve(
        Uri(scheme: 'package', pathSegments: segments.skip(1)),
      );
      if (filePath != null) {
        final File packageFile = fileSystem.file(filePath);
        if (packageFile.existsSync()) {
          return packageFile;
        }
      }
    }

    // Otherwise it must be a Dart SDK source or a Flutter Web SDK source.
    final Directory dartSdkParent = fileSystem
        .directory(
          globals.artifacts!.getArtifactPath(
            Artifact.engineDartSdkPath,
            platform: TargetPlatform.web_javascript,
          ),
        )
        .parent;
    final File dartSdkFile = fileSystem.file(dartSdkParent.uri.resolve(path));
    if (dartSdkFile.existsSync()) {
      return dartSdkFile;
    }

    final Directory flutterWebSdk = fileSystem.directory(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk),
    );
    final File webSdkFile = fileSystem.file(flutterWebSdk.uri.resolve(path));

    return webSdkFile;
  }

  File get _resolveDartSdkJsFile {
    final Map<WebRendererMode, HostArtifact> dartSdkArtifactMap = _ddcModuleSystem
        ? kDdcLibraryBundleDartSdkJsArtifactMap
        : kAmdDartSdkJsArtifactMap;
    return fileSystem.file(globals.artifacts!.getHostArtifact(dartSdkArtifactMap[webRenderer]!));
  }

  File get _resolveDartSdkJsMapFile {
    final Map<WebRendererMode, HostArtifact> dartSdkArtifactMap = _ddcModuleSystem
        ? kDdcLibraryBundleDartSdkJsMapArtifactMap
        : kAmdDartSdkJsMapArtifactMap;
    return fileSystem.file(globals.artifacts!.getHostArtifact(dartSdkArtifactMap[webRenderer]!));
  }

  @override
  Future<String?> dartSourceContents(String serverPath) async {
    serverPath = stripBasePath(serverPath, basePath)!;
    final File result = _resolveDartFile(serverPath);
    if (result.existsSync()) {
      return result.readAsString();
    }
    return null;
  }

  @override
  Future<String> sourceMapContents(String serverPath) async {
    serverPath = stripBasePath(serverPath, basePath)!;
    return utf8.decode(_webMemoryFS.sourcemaps[serverPath]!);
  }

  @override
  Future<String?> metadataContents(String serverPath) async {
    final String? resultPath = stripBasePath(serverPath, basePath);
    if (resultPath == 'main_module.ddc_merged_metadata') {
      return _webMemoryFS.mergedMetadata;
    }
    if (_webMemoryFS.metadataFiles.containsKey(resultPath)) {
      return utf8.decode(_webMemoryFS.metadataFiles[resultPath]!);
    }
    throw Exception('Could not find metadata contents for $serverPath');
  }

  @override
  Future<void> close() async {}
}
