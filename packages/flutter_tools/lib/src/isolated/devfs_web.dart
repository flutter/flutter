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
import 'package:vm_service/vm_service.dart' as vm_service;

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../bundle_builder.dart';
import '../cache.dart';
import '../compile.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../devfs.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../vmservice.dart';
import '../web/bootstrap.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/memory_fs.dart';
import '../web/module_metadata.dart';
import '../web/web_constants.dart';
import '../web_template.dart';

typedef DwdsLauncher =
    Future<Dwds> Function({
      required AssetReader assetReader,
      required Stream<BuildResult> buildResults,
      required ConnectionProvider chromeConnection,
      required ToolConfiguration toolConfiguration,
      bool injectDebuggingSupportCode,
    });

// A minimal index for projects that do not yet support web. A meta tag is used
// to ensure loaded scripts are always parsed as UTF-8.
const String _kDefaultIndex = '''
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

/// An expression compiler connecting to FrontendServer.
///
/// This is only used in development mode.
class WebExpressionCompiler implements ExpressionCompiler {
  WebExpressionCompiler(this._generator, {required FileSystem fileSystem})
    : _fileSystem = fileSystem;

  final ResidentCompiler _generator;
  final FileSystem _fileSystem;

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
    final CompilerOutput? compilerOutput = await _generator.compileExpressionToJs(
      libraryUri,
      line,
      column,
      jsModules,
      jsFrameValues,
      moduleName,
      expression,
    );

    if (compilerOutput != null) {
      final String content = utf8.decode(
        _fileSystem.file(compilerOutput.outputFilename).readAsBytesSync(),
      );
      return ExpressionCompilationResult(content, compilerOutput.errorCount > 0);
    }

    return ExpressionCompilationResult(
      "InternalError: frontend server failed to compile '$expression'",
      true,
    );
  }

  @override
  Future<void> initialize(CompilerOptions options) async {}

  @override
  Future<bool> updateDependencies(Map<String, ModuleInfo> modules) async => true;
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
    this._ddcModuleSystem,
    this._canaryFeatures, {
    required this.webRenderer,
    required this.useLocalCanvasKit,
  }) : basePath = WebTemplate.baseHref(_htmlTemplate('index.html', _kDefaultIndex)) {
    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (_ddcModuleSystem) {
      assert(_canaryFeatures);
    }
  }

  // Fallback to "application/octet-stream" on null which
  // makes no claims as to the structure of the data.
  static const String _kDefaultMimeType = 'application/octet-stream';

  final Map<String, String> _modules;
  final Map<String, String> _digests;

  int get selectedPort => _httpServer.port;

  /// Given a list of [modules] that need to be loaded, compute module names and
  /// digests.
  ///
  /// If [writeRestartScripts] is true, writes a list of sources mapped to their
  /// ids to the file system that can then be consumed by the hot restart
  /// callback.
  ///
  /// For example:
  /// ```json
  /// [
  ///   {
  ///     "src": "<file_name>",
  ///     "id": "<id>",
  ///   },
  /// ]
  /// ```
  void performRestart(List<String> modules, {required bool writeRestartScripts}) {
    for (final String module in modules) {
      // We skip computing the digest by using the hashCode of the underlying buffer.
      // Whenever a file is updated, the corresponding Uint8List.view it corresponds
      // to will change.
      final String moduleName = module.startsWith('/') ? module.substring(1) : module;
      final String name = moduleName.replaceAll('.lib.js', '');
      final String path = moduleName.replaceAll('.js', '');
      _modules[name] = path;
      _digests[name] = _webMemoryFS.files[moduleName].hashCode.toString();
    }
    if (writeRestartScripts) {
      final List<Map<String, String>> srcIdsList = <Map<String, String>>[];
      for (final String src in modules) {
        srcIdsList.add(<String, String>{'src': src, 'id': src});
      }
      writeFile('restart_scripts.json', json.encode(srcIdsList));
    }
  }

  static const String _reloadScriptsFileName = 'reload_scripts.json';

  /// Given a list of [modules] that need to be reloaded, writes a file that
  /// contains a list of objects each with two fields:
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle. To support embedded libraries, the path should include the
  /// `baseUri` of the web server.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  ///
  /// For example:
  /// ```json
  /// [
  ///   {
  ///     "src": "<baseUri>/<file_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// The path of the output file should stay consistent across the lifetime of
  /// the app.
  void performReload(List<String> modules) {
    final List<Map<String, Object>> moduleToLibrary = <Map<String, Object>>[];
    for (final String module in modules) {
      final ModuleMetadata metadata = ModuleMetadata.fromJson(
        json.decode(utf8.decode(_webMemoryFS.metadataFiles['$module.metadata']!.toList()))
            as Map<String, dynamic>,
      );
      final List<String> libraries = metadata.libraries.keys.toList();
      final String moduleUri = baseUri != null ? '$baseUri/$module' : module;
      moduleToLibrary.add(<String, Object>{'src': moduleUri, 'libraries': libraries});
    }
    writeFile(_reloadScriptsFileName, json.encode(moduleToLibrary));
  }

  @visibleForTesting
  List<String> write(File codeFile, File manifestFile, File sourcemapFile, File metadataFile) {
    return _webMemoryFS.write(codeFile, manifestFile, sourcemapFile, metadataFile);
  }

  Uri? get baseUri => _baseUri;
  Uri? _baseUri;

  /// Start the web asset server on a [hostname] and [port].
  ///
  /// If [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  ///
  /// Unhandled exceptions will throw a [ToolExit] with the error and stack
  /// trace.
  static Future<WebAssetServer> start(
    ChromiumLauncher? chromiumLauncher,
    String hostname,
    int port,
    String? tlsCertPath,
    String? tlsCertKeyPath,
    UrlTunneller? urlTunneller,
    bool useSseForDebugProxy,
    bool useSseForDebugBackend,
    bool useSseForInjectedClient,
    BuildInfo buildInfo,
    bool enableDwds,
    bool enableDds,
    Uri entrypoint,
    ExpressionCompiler? expressionCompiler,
    Map<String, String> extraHeaders, {
    required WebRendererMode webRenderer,
    required bool isWasm,
    required bool useLocalCanvasKit,
    bool testMode = false,
    DwdsLauncher dwdsLauncher = Dwds.start,
    // TODO(markzipan): Make sure this default value aligns with that in the debugger options.
    bool ddcModuleSystem = false,
    bool canaryFeatures = false,
  }) async {
    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (ddcModuleSystem) {
      assert(canaryFeatures);
    }
    InternetAddress address;
    if (hostname == 'any') {
      address = InternetAddress.anyIPv4;
    } else {
      address = (await InternetAddress.lookup(hostname)).first;
    }
    HttpServer? httpServer;
    const int kMaxRetries = 4;
    for (int i = 0; i <= kMaxRetries; i++) {
      try {
        if (tlsCertPath != null && tlsCertKeyPath != null) {
          final SecurityContext serverContext =
              SecurityContext()
                ..useCertificateChain(tlsCertPath)
                ..usePrivateKey(tlsCertKeyPath);
          httpServer = await HttpServer.bindSecure(address, port, serverContext);
        } else {
          httpServer = await HttpServer.bind(address, port);
        }
        break;
      } on SocketException catch (e, s) {
        if (i >= kMaxRetries) {
          globals.printError('Failed to bind web development server:\n$e', stackTrace: s);
          throwToolExit('Failed to bind web development server:\n$e');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    // Allow rendering in a iframe.
    httpServer!.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');

    for (final MapEntry<String, String> header in extraHeaders.entries) {
      httpServer.defaultResponseHeaders.add(header.key, header.value);
    }

    final PackageConfig packageConfig = buildInfo.packageConfig;
    final Map<String, String> modules = <String, String>{};
    final Map<String, String> digests = <String, String>{};
    final WebAssetServer server = WebAssetServer(
      httpServer,
      packageConfig,
      address,
      modules,
      digests,
      ddcModuleSystem,
      canaryFeatures,
      webRenderer: webRenderer,
      useLocalCanvasKit: useLocalCanvasKit,
    );
    final int selectedPort = server.selectedPort;
    String url = '$hostname:$selectedPort';
    if (hostname == 'any') {
      url = 'localhost:$selectedPort';
    }
    server._baseUri = Uri.http(url, server.basePath);
    if (tlsCertPath != null && tlsCertKeyPath != null) {
      server._baseUri = Uri.https(url, server.basePath);
    }
    if (testMode) {
      return server;
    }

    // In release builds (or wasm builds) deploy a simpler proxy server.
    if (buildInfo.mode != BuildMode.debug || isWasm) {
      final ReleaseAssetServer releaseAssetServer = ReleaseAssetServer(
        entrypoint,
        fileSystem: globals.fs,
        platform: globals.platform,
        flutterRoot: Cache.flutterRoot,
        webBuildDirectory: getWebBuildDirectory(),
        basePath: server.basePath,
        needsCoopCoep: webRenderer == WebRendererMode.skwasm,
      );
      runZonedGuarded(
        () {
          shelf.serveRequests(httpServer!, releaseAssetServer.handle);
        },
        (Object e, StackTrace s) {
          globals.printTrace('Release asset server: error serving requests: $e:$s');
        },
      );
      return server;
    }

    // Return a version string for all active modules. This is populated
    // along with the `moduleProvider` update logic.
    Future<Map<String, String>> digestProvider() async => digests;

    // Ensure dwds is present and provide middleware to avoid trying to
    // load the through the isolate APIs.
    final Directory directory = await _loadDwdsDirectory(globals.fs, globals.logger);
    shelf.Handler middleware(FutureOr<shelf.Response> Function(shelf.Request) innerHandler) {
      return (shelf.Request request) async {
        if (request.url.path.endsWith('dwds/src/injected/client.js')) {
          final Uri uri = directory.uri.resolve('src/injected/client.js');
          final String result = await globals.fs.file(uri.toFilePath()).readAsString();
          return shelf.Response.ok(
            result,
            headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/javascript'},
          );
        }
        return innerHandler(request);
      };
    }

    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen(log);

    // Retrieve connected web devices.
    final List<Device>? devices = await globals.deviceManager?.getAllDevices();
    final Set<String> connectedWebDeviceIds =
        devices
            ?.where((Device d) => d.platformType == PlatformType.web && d.isConnected)
            .map((Device d) => d.id)
            .toSet() ??
        <String>{};

    // In debug builds, spin up DWDS and the full asset server.
    final Dwds dwds = await dwdsLauncher(
      assetReader: server,
      buildResults: const Stream<BuildResult>.empty(),
      chromeConnection: () async {
        final Chromium chromium = await chromiumLauncher!.connectedInstance;
        return chromium.chromeConnection;
      },
      toolConfiguration: ToolConfiguration(
        loadStrategy:
            ddcModuleSystem
                ? FrontendServerDdcLibraryBundleStrategyProvider(
                  ReloadConfiguration.none,
                  server,
                  PackageUriMapper(packageConfig),
                  digestProvider,
                  BuildSettings(
                    appEntrypoint: packageConfig.toPackageUri(
                      globals.fs.file(entrypoint).absolute.uri,
                    ),
                  ),
                  packageConfigPath: buildInfo.packageConfigPath,
                  hotReloadSourcesUri: server._baseUri!.replace(
                    pathSegments: List<String>.from(server._baseUri!.pathSegments)
                      ..add(_reloadScriptsFileName),
                  ),
                ).strategy
                : FrontendServerRequireStrategyProvider(
                  ReloadConfiguration.none,
                  server,
                  PackageUriMapper(packageConfig),
                  digestProvider,
                  BuildSettings(
                    appEntrypoint: packageConfig.toPackageUri(
                      globals.fs.file(entrypoint).absolute.uri,
                    ),
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
          spawnDds: enableDds,
        ),
        appMetadata: AppMetadata(hostname: hostname),
      ),
      // Inject the debugging support code if connected web devices are present,
      // and user specified a device id that matches a connected web device.
      // If the user did not specify a device id, we use chrome as the default.
      injectDebuggingSupportCode:
          connectedWebDeviceIds.isNotEmpty &&
          connectedWebDeviceIds.contains(globals.deviceManager?.specifiedDeviceId ?? 'chrome'),
    );
    shelf.Pipeline pipeline = const shelf.Pipeline();
    if (enableDwds) {
      pipeline = pipeline.addMiddleware(middleware);
      pipeline = pipeline.addMiddleware(dwds.middleware);
    }
    globals.printTrace('Added middleware');
    final shelf.Handler dwdsHandler = pipeline.addHandler(server.handleRequest);
    final shelf.Cascade cascade = shelf.Cascade().add(dwds.handler).add(dwdsHandler);
    runZonedGuarded(
      () {
        shelf.serveRequests(httpServer!, cascade.handler);
      },
      (Object e, StackTrace s) {
        globals.printTrace('Dwds server: error serving requests: $e:$s');
      },
    );
    server.dwds = dwds;
    server._dwdsInit = true;
    globals.printTrace('Done starting webserver');
    return server;
  }

  final bool _ddcModuleSystem;
  final bool _canaryFeatures;
  final HttpServer _httpServer;
  final WebMemoryFS _webMemoryFS = WebMemoryFS();
  final PackageConfig _packages;
  final InternetAddress internetAddress;
  late final Dwds dwds;
  late Directory entrypointCacheDirectory;
  bool _dwdsInit = false;

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
      globals.printError('Not a GET request');
      // Assets are served via GET only.
      return shelf.Response.notFound('');
    }

    final String? requestPath = _stripBasePath(request.url.path, basePath);

    if (requestPath == null) {
      globals.printError('requestPath is null');
      return shelf.Response.notFound('');
    }

    // If the response is `/`, then we are requesting the index file.
    if (requestPath == '/' || requestPath.isEmpty) {
      globals.printError('Serving index.html');
      return _serveIndexHtml();
    }

    if (requestPath == 'flutter_bootstrap.js') {
      globals.printError('Serving flutter_bootstrap.js');
      return _serveFlutterBootstrapJs();
    }

    final Map<String, String> headers = <String, String>{};

    // Track etag headers for better caching of resources.
    final String? ifNoneMatch = request.headers[HttpHeaders.ifNoneMatchHeader];
    headers[HttpHeaders.cacheControlHeader] = 'max-age=0, must-revalidate';

    // If this is a JavaScript file, it must be in the in-memory cache.
    // Attempt to look up the file by URI.
    final String webServerPath = requestPath.replaceFirst('.dart.js', '.dart.lib.js');
    if (_webMemoryFS.files.containsKey(requestPath) ||
        _webMemoryFS.files.containsKey(webServerPath)) {
      globals.printError(
        'Received request for Dart file in handleRequest: ${request.requestedUri}',
      );
      final List<int>? bytes = getFile(requestPath) ?? getFile(webServerPath);
      // Use the underlying buffer hashCode as a revision string. This buffer is
      // replaced whenever the frontend_server produces new output files, which
      // will also change the hashCode.
      final String etag = bytes.hashCode.toString();
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
      final String etag = bytes.hashCode.toString();
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
      final String etag = bytes.hashCode.toString();
      if (ifNoneMatch == etag) {
        return shelf.Response.notModified();
      }
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
      headers[HttpHeaders.etagHeader] = etag;
      return shelf.Response.ok(bytes, headers: headers);
    }

    File file = _resolveDartFile(requestPath);

    if (!file.existsSync() && requestPath.startsWith('canvaskit/')) {
      final Directory canvasKitDirectory = globals.fs.directory(
        globals.fs.path.join(
          globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path,
          'canvaskit',
        ),
      );
      final Uri potential = canvasKitDirectory.uri.resolve(
        requestPath.replaceFirst('canvaskit/', ''),
      );
      file = globals.fs.file(potential);
    }

    // If all of the lookups above failed, the file might have been an asset.
    // Try and resolve the path relative to the built asset directory.
    if (!file.existsSync()) {
      final Uri potential = globals.fs
          .directory(getAssetBuildDirectory())
          .uri
          .resolve(requestPath.replaceFirst('assets/', ''));
      file = globals.fs.file(potential);
    }

    if (!file.existsSync()) {
      final Uri webPath = globals.fs.currentDirectory
          .childDirectory('web')
          .uri
          .resolve(requestPath);
      file = globals.fs.file(webPath);
    }

    if (!file.existsSync()) {
      // Paths starting with these prefixes should've been resolved above.
      if (requestPath.startsWith('assets/') ||
          requestPath.startsWith('packages/') ||
          requestPath.startsWith('canvaskit/')) {
        return shelf.Response.notFound('');
      }

      globals.printError('File does not exist: ${file.uri}');
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

  String get _buildConfigString {
    final Map<String, dynamic> buildConfig = <String, dynamic>{
      'engineRevision': globals.flutterVersion.engineRevision,
      'builds': <dynamic>[
        <String, dynamic>{
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

  File get _flutterJsFile => globals.fs.file(
    globals.fs.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      'flutter.js',
    ),
  );

  String get _flutterBootstrapJsContent {
    final WebTemplate bootstrapTemplate = _getWebTemplate(
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
    final WebTemplate indexHtml = _getWebTemplate('index.html', _kDefaultIndex);
    return shelf.Response.ok(
      indexHtml.withSubstitutions(
        // Currently, we don't support --base-href for the "run" command.
        baseHref: '/',
        serviceWorkerVersion: null,
        buildConfig: _buildConfigString,
        flutterJsFile: _flutterJsFile,
        flutterBootstrapJs: _flutterBootstrapJsContent,
      ),
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
      final Uri? filePath = _packages.resolve(
        Uri(scheme: 'package', pathSegments: segments.skip(1)),
      );
      if (filePath != null) {
        final File packageFile = globals.fs.file(filePath);
        if (packageFile.existsSync()) {
          return packageFile;
        }
      }
    }

    // Otherwise it must be a Dart SDK source or a Flutter Web SDK source.
    final Directory dartSdkParent =
        globals.fs
            .directory(
              globals.artifacts!.getArtifactPath(
                Artifact.engineDartSdkPath,
                platform: TargetPlatform.web_javascript,
              ),
            )
            .parent;
    final File dartSdkFile = globals.fs.file(dartSdkParent.uri.resolve(path));
    if (dartSdkFile.existsSync()) {
      return dartSdkFile;
    }

    final Directory flutterWebSdk = globals.fs.directory(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk),
    );
    final File webSdkFile = globals.fs.file(flutterWebSdk.uri.resolve(path));

    return webSdkFile;
  }

  File get _resolveDartSdkJsFile {
    final Map<WebRendererMode, HostArtifact> dartSdkArtifactMap =
        _ddcModuleSystem ? kDdcLibraryBundleDartSdkJsArtifactMap : kAmdDartSdkJsArtifactMap;
    return globals.fs.file(globals.artifacts!.getHostArtifact(dartSdkArtifactMap[webRenderer]!));
  }

  File get _resolveDartSdkJsMapFile {
    final Map<WebRendererMode, HostArtifact> dartSdkArtifactMap =
        _ddcModuleSystem ? kDdcLibraryBundleDartSdkJsMapArtifactMap : kAmdDartSdkJsMapArtifactMap;
    return globals.fs.file(globals.artifacts!.getHostArtifact(dartSdkArtifactMap[webRenderer]!));
  }

  @override
  Future<String?> dartSourceContents(String serverPath) async {
    serverPath = _stripBasePath(serverPath, basePath)!;
    final File result = _resolveDartFile(serverPath);
    if (result.existsSync()) {
      return result.readAsString();
    }
    return null;
  }

  @override
  Future<String> sourceMapContents(String serverPath) async {
    serverPath = _stripBasePath(serverPath, basePath)!;
    return utf8.decode(_webMemoryFS.sourcemaps[serverPath]!);
  }

  @override
  Future<String?> metadataContents(String serverPath) async {
    final String? resultPath = _stripBasePath(serverPath, basePath);
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

class ConnectionResult {
  ConnectionResult(this.appConnection, this.debugConnection, this.vmService);

  final AppConnection? appConnection;
  final DebugConnection? debugConnection;
  final vm_service.VmService vmService;
}

typedef VmServiceFactory =
    Future<vm_service.VmService> Function(
      Uri, {
      CompressionOptions compression,
      required Logger logger,
    });

/// The web specific DevFS implementation.
class WebDevFS implements DevFS {
  /// Create a new [WebDevFS] instance.
  ///
  /// [testMode] is true, do not actually initialize dwds or the shelf static
  /// server.
  WebDevFS({
    required this.hostname,
    required int port,
    required this.tlsCertPath,
    required this.tlsCertKeyPath,
    required this.packagesFilePath,
    required this.urlTunneller,
    required this.useSseForDebugProxy,
    required this.useSseForDebugBackend,
    required this.useSseForInjectedClient,
    required this.buildInfo,
    required this.enableDwds,
    required this.enableDds,
    required this.entrypoint,
    required this.expressionCompiler,
    required this.extraHeaders,
    required this.chromiumLauncher,
    required this.nativeNullAssertions,
    required this.ddcModuleSystem,
    required this.canaryFeatures,
    required this.webRenderer,
    required this.isWasm,
    required this.useLocalCanvasKit,
    required this.rootDirectory,
    required this.isWindows,
    this.testMode = false,
  }) : _port = port {
    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (ddcModuleSystem) {
      assert(canaryFeatures);
    }
  }

  final Uri entrypoint;
  final String hostname;
  final String packagesFilePath;
  final UrlTunneller? urlTunneller;
  final bool useSseForDebugProxy;
  final bool useSseForDebugBackend;
  final bool useSseForInjectedClient;
  final BuildInfo buildInfo;
  final bool enableDwds;
  final bool enableDds;
  final Map<String, String> extraHeaders;
  final bool testMode;
  final bool ddcModuleSystem;
  final bool canaryFeatures;
  final ExpressionCompiler? expressionCompiler;
  final ChromiumLauncher? chromiumLauncher;
  final bool nativeNullAssertions;
  final int _port;
  final String? tlsCertPath;
  final String? tlsCertKeyPath;
  final WebRendererMode webRenderer;
  final bool isWasm;
  final bool useLocalCanvasKit;
  final bool isWindows;

  late WebAssetServer webAssetServer;

  Dwds get dwds => webAssetServer.dwds;

  // A flag to indicate whether we have called `setAssetDirectory` on the target device.
  @override
  bool hasSetAssetDirectory = false;

  @override
  bool didUpdateFontManifest = false;

  Future<DebugConnection>? _cachedExtensionFuture;
  StreamSubscription<void>? _connectedApps;

  /// Connect and retrieve the [DebugConnection] for the current application.
  ///
  /// Only calls [AppConnection.runMain] on the subsequent connections. This
  /// should be called before the browser is launched to make sure the listener
  /// is registered early enough.
  Future<ConnectionResult?> connect(
    bool useDebugExtension, {
    @visibleForTesting VmServiceFactory vmServiceFactory = createVmServiceDelegate,
  }) {
    final Completer<ConnectionResult> firstConnection = Completer<ConnectionResult>();
    // Note there is an asynchronous gap between this being set to true and
    // [firstConnection] completing; thus test the boolean to determine if
    // the current connection is the first.
    bool foundFirstConnection = false;
    _connectedApps = dwds.connectedApps.listen(
      (AppConnection appConnection) async {
        globals.printTrace('listening to connectedApps');
        try {
          final DebugConnection debugConnection =
              useDebugExtension
                  ? await (_cachedExtensionFuture ??= dwds.extensionDebugConnections.stream.first)
                  : await dwds.debugConnection(appConnection);
          globals.printTrace('awaited debug connected, useDebugExtension: $useDebugExtension');
          if (foundFirstConnection) {
            globals.printTrace('running main!');
            appConnection.runMain();
            globals.printTrace('ran main!');
          } else {
            foundFirstConnection = true;
            globals.printTrace('second connection');
            final vm_service.VmService vmService = await vmServiceFactory(
              Uri.parse(debugConnection.uri),
              logger: globals.logger,
            );
            firstConnection.complete(ConnectionResult(appConnection, debugConnection, vmService));
          }
        } on Exception catch (error, stackTrace) {
          if (!firstConnection.isCompleted) {
            firstConnection.completeError(error, stackTrace);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        globals.printError('Unknown error while waiting for debug connection:$error\n$stackTrace');
        if (!firstConnection.isCompleted) {
          firstConnection.completeError(error, stackTrace);
        }
      },
    );
    return firstConnection.future;
  }

  @override
  List<Uri> sources = <Uri>[];

  @override
  DateTime? lastCompiled;

  @override
  PackageConfig? lastPackageConfig;

  // We do not evict assets on the web.
  @override
  Set<String> get assetPathsToEvict => const <String>{};

  @override
  Uri? get baseUri => webAssetServer._baseUri;

  @override
  Future<Uri> create() async {
    webAssetServer = await WebAssetServer.start(
      chromiumLauncher,
      hostname,
      _port,
      tlsCertPath,
      tlsCertKeyPath,
      urlTunneller,
      useSseForDebugProxy,
      useSseForDebugBackend,
      useSseForInjectedClient,
      buildInfo,
      enableDwds,
      enableDds,
      entrypoint,
      expressionCompiler,
      extraHeaders,
      webRenderer: webRenderer,
      isWasm: isWasm,
      useLocalCanvasKit: useLocalCanvasKit,
      testMode: testMode,
      ddcModuleSystem: ddcModuleSystem,
      canaryFeatures: canaryFeatures,
    );
    return baseUri!;
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
  final Directory rootDirectory;

  Future<void> _validateTemplateFile(String filename) async {
    final File file = globals.fs.currentDirectory.childDirectory('web').childFile(filename);
    if (!await file.exists()) {
      return;
    }

    final WebTemplate template = WebTemplate(await file.readAsString());
    for (final WebTemplateWarning warning in template.getWarnings()) {
      globals.logger.printWarning(
        'Warning: In $filename:${warning.lineNumber}: ${warning.warningText}',
      );
    }
  }

  @override
  Future<UpdateFSReport> update({
    required Uri mainUri,
    required ResidentCompiler generator,
    required bool trackWidgetCreation,
    required String pathToReload,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
    required String dillOutputPath,
    required DevelopmentShaderCompiler shaderCompiler,
    DevFSWriter? devFSWriter,
    String? target,
    AssetBundle? bundle,
    bool bundleFirstUpload = false,
    bool fullRestart = false,
    bool resetCompiler = false,
    String? projectRootPath,
    File? dartPluginRegistrant,
  }) async {
    lastPackageConfig = packageConfig;
    final File mainFile = globals.fs.file(mainUri);
    final String outputDirectoryPath = mainFile.parent.path;

    if (bundleFirstUpload) {
      webAssetServer.entrypointCacheDirectory = globals.fs.directory(outputDirectoryPath);
      generator.addFileSystemRoot(outputDirectoryPath);
      final String entrypoint = globals.fs.path.basename(mainFile.path);
      webAssetServer.writeBytes(entrypoint, mainFile.readAsBytesSync());
      if (ddcModuleSystem) {
        webAssetServer.writeFile('ddc_module_loader.js', _overriddenDDCModuleLoader);
      } else {
        webAssetServer.writeBytes('require.js', requireJS.readAsBytesSync());
      }
      webAssetServer.writeBytes('flutter.js', flutterJs.readAsBytesSync());
      webAssetServer.writeBytes('stack_trace_mapper.js', stackTraceMapper.readAsBytesSync());
      webAssetServer.writeFile('manifest.json', '{"info":"manifest not generated in run mode."}');
      webAssetServer.writeFile(
        'flutter_service_worker.js',
        '// Service worker not loaded in run mode.',
      );
      webAssetServer.writeFile('version.json', FlutterProject.current().getVersionInfo());
      webAssetServer.writeFile(
        'main.dart.js',
        ddcModuleSystem
            ? generateDDCLibraryBundleBootstrapScript(
              entrypoint: entrypoint,
              ddcModuleLoaderUrl: 'ddc_module_loader.js',
              mapperUrl: 'stack_trace_mapper.js',
              generateLoadingIndicator: enableDwds,
              isWindows: isWindows,
            )
            : generateBootstrapScript(
              requireUrl: 'require.js',
              mapperUrl: 'stack_trace_mapper.js',
              generateLoadingIndicator: enableDwds,
            ),
      );
      const String onLoadEndBootstrap = 'on_load_end_bootstrap.js';
      if (ddcModuleSystem) {
        webAssetServer.writeFile(onLoadEndBootstrap, generateDDCLibraryBundleOnLoadEndBootstrap());
      }
      webAssetServer.writeFile(
        'main_module.bootstrap.js',
        ddcModuleSystem
            ? generateDDCLibraryBundleMainModule(
              entrypoint: entrypoint,
              nativeNullAssertions: nativeNullAssertions,
              onLoadEndBootstrap: onLoadEndBootstrap,
            )
            : generateMainModule(
              entrypoint: entrypoint,
              nativeNullAssertions: nativeNullAssertions,
              loaderRootDirectory: baseUri.toString(),
            ),
      );
      // TODO(zanderso): refactor the asset code in this and the regular devfs to
      // be shared.
      if (bundle != null) {
        await writeBundle(
          globals.fs.directory(getAssetBuildDirectory()),
          bundle.entries,
          targetPlatform: TargetPlatform.web_javascript,
          impellerStatus: ImpellerStatus.disabled,
          processManager: globals.processManager,
          fileSystem: globals.fs,
          artifacts: globals.artifacts!,
          logger: globals.logger,
          projectDir: rootDirectory,
          buildMode: buildInfo.mode,
        );
      }
    }
    await _validateTemplateFile('index.html');
    await _validateTemplateFile('flutter_bootstrap.js');
    final DateTime candidateCompileTime = DateTime.now();
    if (resetCompiler) {
      generator.reset();
    }

    // The tool generates an entrypoint file in a temp directory to handle
    // the web specific bootstrap logic. To make it easier for DWDS to handle
    // mapping the file name, this is done via an additional file root and
    // special hard-coded scheme.
    final CompilerOutput? compilerOutput = await generator.recompile(
      Uri(scheme: 'org-dartlang-app', path: '/${mainUri.pathSegments.last}'),
      invalidatedFiles,
      outputPath: dillOutputPath,
      packageConfig: packageConfig,
      projectRootPath: projectRootPath,
      fs: globals.fs,
      dartPluginRegistrant: dartPluginRegistrant,
      recompileRestart: fullRestart,
    );
    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      return UpdateFSReport(
        // TODO(srujzs): We're currently reliant on compile error string parsing
        // as hot reload rejections are sent to stderr just like other
        // compilation errors. Ideally, we should have some shared parsing
        // functionality, but that would require a shared package.
        // See https://github.com/dart-lang/sdk/issues/60275.
        hotReloadRejected: compilerOutput?.errorMessage?.contains('Hot reload rejected') ?? false,
      );
    }

    // Only update the last compiled time if we successfully compiled.
    lastCompiled = candidateCompileTime;
    // list of sources that needs to be monitored are in [compilerOutput.sources]
    sources = compilerOutput.sources;
    late File codeFile;
    File manifestFile;
    File sourcemapFile;
    File metadataFile;
    late List<String> modules;
    try {
      final Directory parentDirectory = globals.fs.directory(outputDirectoryPath);
      codeFile = parentDirectory.childFile('${compilerOutput.outputFilename}.sources');
      manifestFile = parentDirectory.childFile('${compilerOutput.outputFilename}.json');
      sourcemapFile = parentDirectory.childFile('${compilerOutput.outputFilename}.map');
      metadataFile = parentDirectory.childFile('${compilerOutput.outputFilename}.metadata');
      modules = webAssetServer._webMemoryFS.write(
        codeFile,
        manifestFile,
        sourcemapFile,
        metadataFile,
      );
    } on FileSystemException catch (err) {
      throwToolExit('Failed to load recompiled sources:\n$err');
    }
    if (fullRestart) {
      webAssetServer.performRestart(
        modules,
        writeRestartScripts: ddcModuleSystem && !bundleFirstUpload,
      );
    } else {
      webAssetServer.performReload(modules);
    }
    return UpdateFSReport(
      success: true,
      syncedBytes: codeFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length,
    );
  }

  @visibleForTesting
  final File requireJS = globals.fs.file(
    globals.fs.path.join(
      globals.artifacts!.getArtifactPath(
        Artifact.engineDartSdkPath,
        platform: TargetPlatform.web_javascript,
      ),
      'lib',
      'dev_compiler',
      'amd',
      'require.js',
    ),
  );

  @visibleForTesting
  final File ddcModuleLoaderJS = globals.fs.file(
    globals.fs.path.join(
      globals.artifacts!.getArtifactPath(
        Artifact.engineDartSdkPath,
        platform: TargetPlatform.web_javascript,
      ),
      'lib',
      'dev_compiler',
      'ddc',
      'ddc_module_loader.js',
    ),
  );

  @visibleForTesting
  final File flutterJs = globals.fs.file(
    globals.fs.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      'flutter.js',
    ),
  );

  @visibleForTesting
  final File stackTraceMapper = globals.fs.file(
    globals.fs.path.join(
      globals.artifacts!.getArtifactPath(
        Artifact.engineDartSdkPath,
        platform: TargetPlatform.web_javascript,
      ),
      'lib',
      'dev_compiler',
      'web',
      'dart_stack_trace_mapper.js',
    ),
  );

  @override
  void resetLastCompiled() {
    // Not used for web compilation.
  }

  @override
  Set<String> get shaderPathsToEvict => <String>{};
}

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
    final String? requestPath = _stripBasePath(request.url.path, basePath);

    if (requestPath == null) {
      return shelf.Response.notFound('');
    }

    if (request.url.toString() == 'main.dart') {
      fileUri = entrypoint;
    } else {
      for (final Uri uri in _searchPaths()) {
        final Uri potential = uri.resolve(requestPath);
        if (!_fileSystem.isFileSync(potential.toFilePath(windows: _platform.isWindows))) {
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

@visibleForTesting
void log(logging.LogRecord event) {
  final String error = event.error == null ? '' : 'Error: ${event.error}';
  if (event.level >= logging.Level.SEVERE) {
    globals.printError('${event.loggerName}: ${event.message}$error', stackTrace: event.stackTrace);
  } else if (event.level == logging.Level.WARNING) {
    // Temporary fix for https://github.com/flutter/flutter/issues/109792
    // TODO(annagrin): Remove the condition after the bogus warning is
    // removed in dwds: https://github.com/dart-lang/webdev/issues/1722
    if (!event.message.contains('No module for')) {
      globals.printWarning('${event.loggerName}: ${event.message}$error');
    }
  } else {
    globals.printTrace('${event.loggerName}: ${event.message}$error');
  }
}

Future<Directory> _loadDwdsDirectory(FileSystem fileSystem, Logger logger) async {
  final PackageConfig packageConfig = await currentPackageConfig();
  return fileSystem.directory(packageConfig['dwds']!.packageUriRoot);
}

String? _stripBasePath(String path, String basePath) {
  path = stripLeadingSlash(path);
  if (path.startsWith(basePath)) {
    path = path.substring(basePath.length);
  } else {
    // The given path isn't under base path, return null to indicate that.
    return null;
  }
  return stripLeadingSlash(path);
}

WebTemplate _getWebTemplate(String filename, String fallbackContent) {
  final String htmlContent = _htmlTemplate(filename, fallbackContent);
  return WebTemplate(htmlContent);
}

String _htmlTemplate(String filename, String fallbackContent) {
  final File template = globals.fs.currentDirectory.childDirectory('web').childFile(filename);
  return template.existsSync() ? template.readAsStringSync() : fallbackContent;
}

const String _overriddenDDCModuleLoader = r'''
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file defines the module loader for the dart runtime.
if (!self.dart_library) {
  self.dart_library = typeof module != 'undefined' && module.exports || {};

  (function (dart_library) {
    'use strict';

    // Throws an error related to module loading.
    //
    // This does not throw a Dart error because the Dart SDK may not have loaded
    // yet, and module loading errors cannot be caught by Dart code.
    function throwLibraryError(message) {
      // Dispatch event to allow others to react to the load error without
      // capturing the exception.
      if (!!self.dispatchEvent) {
        self.dispatchEvent(
          new CustomEvent('dartLoadException', { detail: message }));
      }
      throw Error(message);
    }

    /**
     * Returns true if we're running in d8.
     *
     * TODO(markzipan): Determine if this d8 check is too inexact.
     */
    self.dart_library.isD8 = self.document.head == void 0;

    const libraryImports = Symbol('libraryImports');
    self.dart_library.libraryImports = libraryImports;

    const _metrics = Symbol('metrics');

    // Returns a map from module name to various metrics for module.
    function moduleMetrics() {
      const map = {};
      const keys = Array.from(_libraries.keys());
      for (const key of keys) {
        const lib = _libraries.get(key);
        map[lib._name] = lib.firstLibraryValue[_metrics];
      }
      return map;
    }
    self.dart_library.moduleMetrics = moduleMetrics;

    // Returns an application level overview of the module metrics.
    function appMetrics() {
      const metrics = moduleMetrics();
      let dartSize = 0;
      let jsSize = 0;
      let sourceMapSize = 0;
      let evaluatedModules = 0;
      const keys = Array.from(_libraries.keys());

      let firstLoadStart = Number.MAX_VALUE;
      let lastLoadEnd = Number.MIN_VALUE;

      for (const module of keys) {
        let data = metrics[module];
        if (data != null) {
          evaluatedModules++;
          dartSize += data.dartSize;
          jsSize += data.jsSize;
          sourceMapSize += data.sourceMapSize;
          firstLoadStart = Math.min(firstLoadStart, data.loadStart);
          lastLoadEnd = Math.max(lastLoadEnd, data.loadEnd);
        }
      }
      let loadTimeMs =
        lastLoadEnd === Number.MIN_VALUE ? 0 : lastLoadEnd - firstLoadStart;
      return {
        'dartSize': dartSize,
        'jsSize': jsSize,
        'sourceMapSize': sourceMapSize,
        'evaluatedModules': evaluatedModules,
        'loadTimeMs': loadTimeMs
      };
    }
    self.dart_library.appMetrics = appMetrics;

    function _sortFn(key1, key2) {
      const t1 = _libraries.get(key1).firstLibraryValue[_metrics].loadStart;
      const t2 = _libraries.get(key2).firstLibraryValue[_metrics].loadStart;
      return t1 - t2;
    }

    // Convenience method to print the metrics in the browser console
    // in CSV format.
    function metricsCsv() {
      let buffer =
        'Module, JS Size, Dart Size, Load Start, Load End, Cumulative JS Size\n';
      const keys = Array.from(_libraries.keys());
      keys.sort(_sortFn);
      let cumulativeJsSize = 0;
      for (const key of keys) {
        const lib = _libraries.get(key);
        const jsSize = lib.firstLibraryValue[_metrics].jsSize;
        cumulativeJsSize += jsSize;
        const dartSize = lib.firstLibraryValue[_metrics].dartSize;
        const loadStart = lib.firstLibraryValue[_metrics].loadStart;
        const loadEnd = lib.firstLibraryValue[_metrics].loadEnd;
        buffer += '"' + lib._name + '", ' + jsSize + ', ' + dartSize + ', ' +
          loadStart + ', ' + loadEnd + ', ' + cumulativeJsSize + '\n';
      }
      return buffer;
    }
    self.dart_library.metricsCsv = metricsCsv;

    // Module support.  This is a simplified module system for Dart.
    // Longer term, we can easily migrate to an existing JS module system:
    // ES6, AMD, RequireJS, ....

    // Returns a proxy that delegates to the underlying loader.
    // This defers loading of a module until a library is actually used.
    const loadedModule = Symbol('loadedModule');
    self.dart_library.defer = function (module, name, patch) {
      let done = false;
      function loadDeferred() {
        done = true;
        let mod = module[loadedModule];
        let lib = mod[name];
        // Install unproxied module and library in caller's context.
        patch(mod, lib);
      }
      // The deferred library object.  Note, the only legal operations on a Dart
      // library object should be get (to read a top-level variable, method, or
      // Class) or set (to write a top-level variable).
      return new Proxy({}, {
        get: function (o, p) {
          if (!done) loadDeferred();
          return module[name][p];
        },
        set: function (o, p, value) {
          if (!done) loadDeferred();
          module[name][p] = value;
          return true;
        },
      });
    };

    let _reverseImports = new Map();

    // App name to set of libraries that were not only loaded on the page but
    // also executed.
    const _executedLibraries = new Map();
    self.dart_library.executedLibraryCount = function () {
      let count = 0;
      _executedLibraries.forEach(function (executedLibraries, _) {
        count += executedLibraries.size;
      });
      return count;
    };

    // Library instance that is going to be loaded or has been loaded.
    class LibraryInstance {
      constructor(libraryValue) {
        this.libraryValue = libraryValue;
        // Cyclic import detection
        this.loadingState = LibraryLoader.NOT_LOADED;
      }

      get isNotLoaded() {
        return this.loadingState == LibraryLoader.NOT_LOADED;
      }
    }

    class LibraryLoader {
      constructor(name, defaultLibraryValue, imports, loader, data) {
        imports.forEach(function (i) {
          let deps = _reverseImports.get(i);
          if (!deps) {
            deps = new Set();
            _reverseImports.set(i, deps);
          }
          deps.add(name);
        });
        this._name = name;
        this._defaultLibraryValue =
          defaultLibraryValue ? defaultLibraryValue : {};
        this._imports = imports;
        this._loader = loader;
        data.jsSize = loader.toString().length;
        data.loadStart = NaN;
        data.loadEnd = NaN;
        this._metrics = data;

        // First loaded instance for supporting logic that assumes there is only
        // one app.
        // TODO(b/204209941): Remove _firstLibraryInstance after debugger and
        // metrics support multiple apps.
        this._firstLibraryInstance =
          new LibraryInstance(this._deepCopyDefaultValue());
        this._firstLibraryInstanceUsed = false;

        // App name to instance map.
        this._instanceMap = new Map();
      }

      /// First loaded value for supporting logic that assumes there is only
      /// one app.
      get firstLibraryValue() {
        return this._firstLibraryInstance.libraryValue;
      }

      /// The loaded instance value for the given `appName`.
      libraryValueInApp(appName) {
        return this._instanceMap.get(appName).libraryValue;
      }

      load(appName) {
        let instance = this._instanceMap.get(appName);
        if (!instance && !this._firstLibraryInstanceUsed) {
          // If `_firstLibraryInstance` is already assigned to an app, creates a
          // new instance clone (with deep copy) and assigns it the given app.
          // Otherwise, reuse `_firstLibraryInstance`.
          instance = this._firstLibraryInstance;
          this._firstLibraryInstanceUsed = true;
          this._instanceMap.set(appName, instance);
        }
        if (!instance) {
          instance = new LibraryInstance(this._deepCopyDefaultValue());
          this._instanceMap.set(appName, instance);
        }

        // Check for cycles
        if (instance.loadingState == LibraryLoader.LOADING) {
          throwLibraryError('Circular dependence on library: ' + this._name);
        } else if (instance.loadingState >= LibraryLoader.READY) {
          return instance.libraryValue;
        }
        if (!_executedLibraries.has(appName)) {
          _executedLibraries.set(appName, new Set());
        }
        _executedLibraries.get(appName).add(this._name);
        instance.loadingState = LibraryLoader.LOADING;

        // Handle imports
        let args = this._loadImports(appName);

        // Load the library
        let loader = this;
        let library = instance.libraryValue;

        library[libraryImports] = this._imports;
        library[loadedModule] = library;
        library[_metrics] = this._metrics;
        args.unshift(library);

        if (this._name == 'dart_sdk') {
          // Eagerly load the SDK.
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadStart = self.performance.now();
          }
          this._loader.apply(null, args);
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadEnd = self.performance.now();
          }
        } else {
          // Load / parse other modules on demand.
          let done = false;
          instance.libraryValue = new Proxy(library, {
            get: function (o, name) {
              if (name == _metrics) {
                return o[name];
              }
              if (!done) {
                done = true;
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadStart = self.performance.now();
                }
                loader._loader.apply(null, args);
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadEnd = self.performance.now();
                }
              }
              return o[name];
            }
          });
        }

        instance.loadingState = LibraryLoader.READY;
        return instance.libraryValue;
      }

      _loadImports(appName) {
        let results = [];
        for (let name of this._imports) {
          results.push(import_(name, appName));
        }
        return results;
      }

      _deepCopyDefaultValue() {
        return JSON.parse(JSON.stringify(this._defaultLibraryValue));
      }
    }
    LibraryLoader.NOT_LOADED = 0;
    LibraryLoader.LOADING = 1;
    LibraryLoader.READY = 2;

    // Map from name to LibraryLoader
    let _libraries = new Map();
    self.dart_library.libraries = function () {
      return _libraries.keys();
    };
    self.dart_library.debuggerLibraries = function () {
      let debuggerLibraries = [];
      _libraries.forEach(function (value, key, map) {
        debuggerLibraries.push(value.load(_firstStartedAppName));
      });
      Object.setPrototypeOf(debuggerLibraries, null);
      return debuggerLibraries;
    };

    // Invalidate a library and all things that depend on it
    function _invalidateLibrary(name) {
      let lib = _libraries.get(name);
      if (lib._instanceMap.size === 0) return;
      lib._firstLibraryInstance =
        new LibraryInstance(lib._deepCopyDefaultValue());
      lib._firstLibraryInstanceUsed = false;
      lib._instanceMap.clear();
      let deps = _reverseImports.get(name);
      if (!deps) return;
      deps.forEach(_invalidateLibrary);
    }

    function library(name, defaultLibraryValue, imports, loader, data = {}) {
      let result = _libraries.get(name);
      if (result) {
        console.log('Re-loading ' + name);
        _invalidateLibrary(name);
      }
      result =
        new LibraryLoader(name, defaultLibraryValue, imports, loader, data);
      _libraries.set(name, result);
      return result;
    }
    self.dart_library.library = library;

    // Local storage may be blocked by a browser policy in which case even
    // trying to access it will throw.
    function isLocalStorageAvailable() {
      try {
        !!self.localStorage;
        return true;
      } catch (e) {
        return false;
      }
    }

    // Store executed modules upon reload.
    if (!!self.addEventListener && isLocalStorageAvailable()) {
      self.addEventListener('beforeunload', function (event) {
        _nameToApp.forEach(function (_, appName) {
          if (!_executedLibraries.get(appName)) {
            return;
          }
          let libraryCache = {
            'time': new Date().getTime(),
            'modules': Array.from(_executedLibraries.get(appName).keys()),
          };
          self.localStorage.setItem(
            `dartLibraryCache:${appName}`, JSON.stringify(libraryCache));
        });
      });
    }

    // Map from module name to corresponding app to proxy library map.
    let _proxyLibs = new Map();

    /**
     * Returns an instantiated module given its module name.
     *
     * Note: this method is not meant to be used outside DDC generated code,
     * however it is currently being used in many places because DDC lacks an
     * Embedding API. This API will be removed in the future once the Embedding
     * API is established.
     */
    function import_(name, appName) {
      // For backward compatibility.
      if (!appName && _lastStartedSubapp) {
        appName = _lastStartedSubapp.appName;
      }

      let proxy;
      if (_proxyLibs.has(name)) {
        proxy = _proxyLibs.get(name).get(appName);
      }
      if (proxy) return proxy;
      let proxyLib = new Proxy({}, {
        get: function (o, p) {
          let lib = _libraries.get(name);
          if (self.$dartJITModules) {
            // The backing module changed so update the reference
            if (!lib) {
              let xhr = new XMLHttpRequest();
              let sourceURL = self.$dartLoader.moduleIdToUrl.get(name);
              xhr.open('GET', sourceURL, false);
              xhr.withCredentials = true;
              xhr.send();
              // Add inline policy to make eval() call Trusted Types compatible
              // when running in a TT compatible browser
              let policy = {
                createScript: function (script) {
                  return script;
                }
              };
              if (self.trustedTypes && self.trustedTypes.createPolicy) {
                policy = self.trustedTypes.createPolicy(
                  'dartDdcModuleLoading#dart_library', policy);
              }
              // Append sourceUrl so the resource shows up in the Chrome
              // console.
              eval(policy.createScript(
                xhr.responseText + '//@ sourceURL=' + sourceURL));
              lib = _libraries.get(name);
            }
          }
          if (!lib) {
            throwLibraryError('Module ' + name + ' not loaded in the browser.');
          }
          // Always load the library before accessing a property as it may have
          // been invalidated.
          return lib.load(appName)[p];
        }
      });
      if (!_proxyLibs.has(name)) {
        _proxyLibs.set(name, new Map());
      }
      _proxyLibs.get(name).set(appName, proxyLib);
      return proxyLib;
    }
    self.dart_library.import = import_;

    // Removes the corresponding library and invalidates all things that
    // depend on it.
    function _invalidateImport(name) {
      let lib = _libraries.get(name);
      if (!lib) return;
      _invalidateLibrary(name);
      _libraries.delete(name);
    }
    self.dart_library.invalidateImport = _invalidateImport;

    let _debuggerInitialized = false;

    // Caches the last N runIds to prevent hot reload requests from the same
    // runId from executing more than once.
    const _hotRestartRunIdCache = new Array();

    // Called to initiate a hot restart of the application for a given uuid. If
    // it is not set, the last started application will be hot restarted.
    //
    // "Hot restart" means all application state is cleared, the newly compiled
    // modules are loaded, and `main()` is called.
    //
    // Note: `onReloadEnd()` can be provided, and if so will be used instead of
    // `main()` for hot restart.
    //
    // This happens in the following sequence:
    //
    // 1. Look for `onReloadStart()` in the same library that has `main()`, and
    //    call it if present. This function is implemented by the application to
    //    ensure any global browser/DOM state is cleared, so the application can
    //    restart.
    // 2. Wait for `onReloadStart()` to complete (either synchronously, or async
    //    if it returned a `Future`).
    // 3. Call dart:_runtime's `hotRestart()` function to clear any state that
    //    `dartdevc` is tracking, such as initialized static fields and type
    //    caches.
    // 4. Call `self.$dartReloadModifiedModules()` (provided by the HTML page)
    //    to reload the relevant JS modules, passing a callback that will invoke
    //    `main()`.
    // 5. `$dartReloadModifiedModules` calls the callback to rerun main.
    //
    async function hotRestart(config) {
      if (!self || !self.$dartReloadModifiedModules) {
        console.warn('Hot restart not supported in this environment.');
        return;
      }

      // If `config.runId` is set (e.g. a unique build ID that represent the
      // current build and shared by multiple subapps), skip the following runs
      // with the same id.
      if (config && config.runId) {
        if (_hotRestartRunIdCache.indexOf(config.runId) >= 0) {
          // The run has already started (by other subapp or app)
          return;
        }
        _hotRestartRunIdCache.push(config.runId);

        // Only cache the runIds for the last N runs. We assume that there are
        // less than N requests with different runId can happen in a very short
        // period of time (e.g. 1 second).
        if (_hotRestartRunIdCache.length > 10) {
          _hotRestartRunIdCache.shift();
        }
      }

      self.console.clear();
      const sdk = _libraries.get('dart_sdk');

      // Finds out what apps and their subapps should be hot restarted in
      // their starting order.
      const dirtyAppNames = new Array();
      const dirtySubapps = new Array();
      if (config && config.runId) {
        _nameToApp.forEach(function (app, appName) {
          dirtySubapps.push(...app.uuidToSubapp.values());
          dirtyAppNames.push(appName);
        });
      } else {
        dirtySubapps.push(_lastStartedSubapp);
        dirtyAppNames.push(_lastStartedSubapp.appName);
      }

      // Invokes onReloadStart for each subapp in reversed starting order.
      const onReloadStartPromises = new Array();
      for (const subapp of dirtySubapps.reverse()) {
        // Call the application's `onReloadStart()` function, if provided.
        if (subapp.library && subapp.library.onReloadStart) {
          const result = subapp.library.onReloadStart();
          if (result && result.then) {
            let resolve;
            onReloadStartPromises.push(new Promise(function (res, _) {
              resolve = res;
            }));
            const dart = sdk.libraryValueInApp(subapp.appName).dart;
            result.then(dart.dynamic, function () {
              resolve();
            });
          }
        }
      }
      // Reverse the subapps back to starting order.
      dirtySubapps.reverse();

      await Promise.all(onReloadStartPromises);

      // Invokes SDK `hotRestart` to reset all initialized fields and clears
      // type caches and other temporary data structures used by the
      // compiler/SDK.
      for (const appName of dirtyAppNames) {
        sdk.libraryValueInApp(appName).dart.hotRestart();
      }

      // Invoke `hotRestart` for the deferred loader to clear load ids and
      // other temporary state.
      if (self.deferred_loader) {
        self.deferred_loader.hotRestart();
      }

      // Starts the subapps in their starting order.
      for (const subapp of dirtySubapps) {
        // Call the module loader to reload the necessary modules.
        self.$dartReloadModifiedModules(subapp.appName, async function () {
          // If the promise `readyToRunMain` is provided, then wait for
          // it. This gives the debugging clients time to set any breakpoints.
          if (!!(config && config.readyToRunMain)) {
            await config.readyToRunMain;
          }
          // Once the modules are loaded, rerun `main()`.
          start(
            subapp.appName, subapp.uuid, subapp.moduleName,
            subapp.libraryName, true);
        });
      }
    }
    self.dart_library.reload = hotRestart;

    // Creates a script with the proper nonce value for strict CSP or noops on
    // invalid platforms.
    self.dart_library.createScript = (function () {
      // Exit early if we aren't modifying an HtmlElement (such as in D8).
      if (self.dart_library.isD8) return;
      // Find the nonce value. (Note, this is only computed once.)
      const scripts = Array.from(document.getElementsByTagName('script'));
      let nonce;
      scripts.some(
        script => (nonce = script.nonce || script.getAttribute('nonce')));
      // If present, return a closure that automatically appends the nonce.
      if (nonce) {
        return function () {
          let script = document.createElement('script');
          script.nonce = nonce;
          return script;
        };
      } else {
        return function () {
          return document.createElement('script');
        };
      }
    })();

    /// An App contains one or multiple Subapps, all of the subapps share the
    /// same memory copy of library instances, and as a result they share state
    /// in Dart statics and top-level fields. There can be one or multiple Apps
    /// in a browser window, all of the Apps are isolated from each other
    /// (i.e. they create different instances even for the same module).
    class App {
      constructor(name) {
        this.name = name;

        // Subapp's uuid to subapps in initial starting order.
        // (ES6 preserves iteration order)
        this.uuidToSubapp = new Map();
      }
    }

    class Subapp {
      constructor(uuid, appName, moduleName, libraryName, library) {
        this.uuid = uuid;
        this.appName = appName;
        this.moduleName = moduleName;
        this.libraryName = libraryName;
        this.library = library;

        this.originalBody = null;
      }
    }

    // App name to App map in initial starting order.
    // (ES6 preserves iteration order)
    const _nameToApp = new Map();
    let _firstStartedAppName;
    let _lastStartedSubapp;

    /**
     * Runs a Dart program's main method.
     *
     * Intended to be invoked by the bootstrapping code where the application
     * is being embedded.
     *
     * Because multiple programs can be part of a single application on a page
     * at once, we identify the entrypoint using multiple keys: `appName`
     * denotes the parent application, this program within that application
     * (aka. the subapp) is identified by an `uuid`. Finally the entrypoint
     * method is located from the `moduleName` and `libraryName`.
     *
     * Often, when a page contains a single app, the uuid is a fixed trivial
     * value like '00000000-0000-0000-0000-000000000000'.
     *
     * This is one of the current public Embedding APIs exposed by DDC.
     * Note: this API will be replaced by `dartDevEmbedder.runMain` in the
     * future.
     */
    function start(appName, uuid, moduleName, libraryName, isReload) {
      console.info(
        `DDC: Subapp Module [${appName}:${moduleName}:${uuid}] is starting`);
      if (libraryName == null) libraryName = moduleName;
      const library = import_(moduleName, appName)[libraryName];

      let app = _nameToApp.get(appName);
      if (!isReload) {
        if (!app) {
          app = new App(appName);
          _nameToApp.set(appName, app);
        }

        let subapp = app.uuidToSubapp.get(uuid);
        if (!subapp) {
          subapp = new Subapp(uuid, appName, moduleName, libraryName, library);
          app.uuidToSubapp.set(uuid, subapp);
        }

        _lastStartedSubapp = subapp;
        if (!_firstStartedAppName) {
          _firstStartedAppName = appName;
        }
      }

      const subapp = app.uuidToSubapp.get(uuid);
      const sdk = import_('dart_sdk', appName);

      if (!_debuggerInitialized) {
        // This import is only needed for chrome debugging. We should provide an
        // option to compile without it.
        sdk._debugger.registerDevtoolsFormatter();

        // Create isolate.
        _debuggerInitialized = true;
      }
      if (isReload) {
        // subapp may have been modified during reload, `subapp.library` needs
        // to always point to the latest data.
        subapp.library = library;

        if (library.onReloadEnd) {
          library.onReloadEnd();
          return;
        } else {
          if (!!self.document) {
            // Note: we expect originalBody to be undefined in non-browser
            // environments, but in that case so is the body.
            if (!subapp.originalBody && !!self.document.body) {
              self.console.warn('No body saved to update on reload');
            } else {
              self.document.body = subapp.originalBody;
            }
          }
        }
      } else {
        // If not a reload and `onReloadEnd` is not defined, store the initial
        // html to reset it on reload.
        if (!library.onReloadEnd && !!self.document && !!self.document.body) {
          subapp.originalBody = self.document.body.cloneNode(true);
        }
      }
      library.main([]);
    }
    dart_library.start = start;


    /**
     * Configure the DDC runtime.
     *
     * Must be called before invoking [start].
     *
     * The configuration parameter is an object that may provide any of the
     * following keys:
     *
     *   - weakNullSafetyErrors: throw errors when types violate sound null
     *        safety (deprecated).
     *
     *   - nonNullAsserts: insert non-null assertions no non-nullable method
     *        parameters (deprecated, was used to aid in null safety
     *        migrations).
     *
     *   - nativeNonNullAsserts: inject non-null assertions checks to validate
     *        that browser APIs are sound. This is helpful because browser APIs
     *        are generated from IDLs and cannot be proven to be correct
     *        statically.
     *
     *   - jsInteropNonNullAsserts: inject non-null assertiosn to check
     *        nullability of `package:js` JS-interop APIs. The new
     *        `dart:js_interop` always includes non-null assertions.
     *
     *   - dynamicModuleLoader: provide the implementation of dynamic module
     *        loading. Dynamic modules is an experimental feature.
     *        The DDC runtime delegates to the embedder how code for dynamic
     *        modules is downloaded. This entry in the configuration must be a
     *        function with the signature:
     *            `function(String, onLoad)`
     *        It accepts a `String` containing a Uri that denotes the module to
     *        be loaded. When the load completes, the loader must invoke
     *        `onLoad` and provide the module name of the dynamic module to it.
     *
     *        Note: eventually we may want to make the loader return a promise.
     *        We avoided that for now because it interfereres with our testing
     *        in d8.
     */
    dart_library.configure = function configure(appName, configuration) {
      let runtimeLibrary = dart_library.import("dart_sdk", appName).dart;
      if (!!configuration.weakNullSafetyErrors) {
        runtimeLibrary.weakNullSafetyErrors(configuration.weakNullSafetyErrors);
      }
      if (!!configuration.nonNullAsserts) {
        runtimeLibrary.nonNullAsserts(configuration.nonNullAsserts);
      }
      if (!!configuration.nativeNonNullAsserts) {
        runtimeLibrary.nativeNonNullAsserts(configuration.nativeNonNullAsserts);
      }
      if (!!configuration.jsInteropNonNullAsserts) {
        runtimeLibrary.jsInteropNonNullAsserts(
          configuration.jsInteropNonNullAsserts);
      }
      if (!!configuration.dynamicModuleLoader) {
        let loader = configuration.dynamicModuleLoader;
        runtimeLibrary.setDynamicModuleLoader(loader, (moduleName) => {
          //  As mentioned in the docs above, loader will not invoke the
          //  entrypoint, but just return the moduleName to find where to call
          //  it.  By using the module name, we don't need to expose the
          //  `import` as part of the embedding API.
          //  In the future module system, this will change to a library name,
          //  rather than a module name.
          return import_(moduleName, appName).__dynamic_module_entrypoint__();
        });
      }
    };
  })(dart_library);
}

// Initialize the DDC module loader.
//
// Scripts are JS objects with the following structure:
//   {"src": "path/to/script.js", "id": "lookup_id_for_script"}
(function () {
  let _currentDirectory = (function () {
    let _url = document.currentScript.src;
    let lastSlash = _url.lastIndexOf('/');
    if (lastSlash == -1) return _url;
    let currentDirectory = _url.substring(0, lastSlash + 1);
    return currentDirectory;
  })();

  let trimmedDirectory = _currentDirectory.endsWith("/") ?
    _currentDirectory.substring(0, _currentDirectory.length - 1)
    : _currentDirectory;

  if (!self.$dartLoader) {
    self.$dartLoader = {
      // Maps cosmetic (but stable) module names to their fully resolved URL.
      //
      // TODO(markzipan): Multi-app scripts can have module name conflicts.
      // This should ideally be separated per-app.
      moduleIdToUrl: new Map(),
      // Contains root directories below which scripts are resolved.
      rootDirectories: new Array(),
      // This mapping is required for proper translation of stack traces.
      urlToModuleId: new Map(),
      // The DDCLoader used for this app. Should not be used in multi-app
      // scenarios.
      loader: null,
      // The LoadConfiguration used for this app's DDCLoader. Should not be used
      // in multi-app scenarios.
      loadConfig: null
    };

    // Every distinct DDC app requires its own load configuration.
    self.$dartLoader.LoadConfiguration = class LoadConfiguration {
      constructor() {
        // Identifies the bootstrap script.
        // This should be set by bootstrappers for bootstrap-specific hooks.
        this.bootstrapScript = null;

        // True if the bootstrap script should be loaded on the this attempt.
        this.tryLoadBootstrapScript = false;

        // The underlying function that loads scripts.
        //
        // @param {function(!DDCLoader)}
        this.loadScriptFn = (_) => { };

        // The root for script URLs. Defaults to the root of this file.
        //
        // TODO(markzipan): Using the default is not safe in a multi-app scenario
        // due to apps clobbering state on dartLoader. Move this to the local
        // DDCLoader, which is unique per-app.
        this.root = trimmedDirectory;

        this.isWindows = false;

        // Optional event handlers.
        // Called when modules begin loading.
        this.onLoadStart = () => { };
        // Called when the app fails to load after retrying.
        this.onLoadError = () => { };
        // Called if loading the bootstrap script is successful.
        this.onBootstrapSuccess = () => { };
        // Called if the bootstrap script fails to load.
        this.onBootstrapError = () => { };

        this.maxRequestPoolSize = 1000;

        // Max retry to prevent from load failing scripts forever.
        this.maxAttempts = 6;
      }
    };
  }

  /**
   * Loads [jsFile] onto this instance's DDC app's page, then invokes
   * [onLoad].
   * @param {string} jsFile
   * @param {?function()} onLoad Callback after a successful load
   */
  self.$dartLoader.forceLoadScript = function (jsFile, onLoad) {
    // A head element won't be created for D8, so just load synchronously.
    if (self.dart_library.isD8) {
      self.load(jsFile);
      onLoad?.();
      return;
    }
    let script = self.dart_library.createScript();
    let policy = {
      createScriptURL: function (src) { return src; }
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.setAttribute('src', policy.createScriptURL(jsFile));
    script.async = false;
    script.defer = true;
    if (onLoad !== void 0) {
      script.onload = onLoad;
    } else {
      script.onload = function () {
        console.log(`Loaded ${jsFile} in forceLoadScript`);
      }
    }
    self.document.head.appendChild(script);
  };

  self.$dartLoader.forceLoadModule = function (moduleName) {
    let modulePathScript = _currentDirectory + moduleName + '.js';
    self.$dartLoader.forceLoadScript(modulePathScript);
  };

  // Handles JS script downloads and evaluation for a DDC app.
  //
  // Every DDC application requires exactly one DDCLoader.
  self.$dartLoader.DDCLoader = class DDCLoader {
    constructor(loadConfig) {
      this.attemptCount = 0;

      this.loadConfig = loadConfig;

      // Scripts that await to be loaded.
      this.queue = new Array();

      // These refer to scripts already added to the document (as script tag).
      this.numToLoad = 0;
      this.numLoaded = 0;
      this.numFailed = 0;

      // Resets all the fields and makes a load attempt.
      this.nextAttempt = function () {
        if (this.attemptCount == 0) {
          this.loadConfig.onLoadStart();
        }
        this.attemptCount++;
        this.queue = new Array();
        this.numToLoad = 0;
        this.numLoaded = 0;
        this.numFailed = 0;

        this.loadConfig.loadScriptFn(this);
      };

      // The current 'intended' hot restart generation.
      //
      // 0-indexed and increases by 1 on every successful hot restart.
      // Unlike `hotRestartGeneration`, this is incremented when the intent to
      // perform a hot restart is established.
      // This is used to synchronize D8 timers and lookup files to load in
      // each generation for hot restart testing.
      this.intendedHotRestartGeneration = 0;
    }

    // True if we are still processing scripts from the script queue.
    // 'Processing' means the script is 1) currently being downloaded/parsed
    // or 2) the script failed to download and is being retried.
    scriptsActivelyBeingLoaded() {
      return this.numToLoad > this.numLoaded + this.numFailed;
    };

    // Joins path segments from the root directory to [script]'s path to get a
    // complete URL.
    getScriptUrl(script) {
      let pathSlash = this.loadConfig.isWindows ? "\\" : "/";
      // Get path segments for src
      let splitSrc = script.src.toString().split(pathSlash);
      let j = 0;
      // Count number of relative path segments
      while (splitSrc[j] == "..") {
        j++;
      }
      // Get path segments for root directory
      let splitDir = !this.loadConfig.root
        || this.loadConfig.root == pathSlash ? []
        : this.loadConfig.root.split(pathSlash);
      // Account for relative path from the root directory
      let splitPath = splitDir
        .slice(0, splitDir.length - j)
        .concat(splitSrc.slice(j));
      // Join path segments to get a complete path
      return splitPath.join(pathSlash);
    };

    // Adds [script] to the dartLoader's internals as if it had been loaded and
    // returns its fully resolved source path.
    //
    // Should be called when scripts are loaded on the page externally from
    // dartLoader's API.
    registerScript(script) {
      const src = this.getScriptUrl(script);
      // TODO(markzipan): moduleIdToUrl and urlToModuleId may conflict in
      // multi-app scenarios. Fix this by moving them into the DDCLoader.
      self.$dartLoader.moduleIdToUrl.set(script.id, src);
      self.$dartLoader.urlToModuleId.set(src, script.id);
      return src;
    };

    // Adds [scripts] to [queue] according to validation function [allowScriptFn].
    //
    // Scripts aren't loaded until loadEnqueuedModules is called.
    addScriptsToQueue(scripts, allowScriptFn) {
      for (let i = 0; i < scripts.length; i++) {
        const script = scripts[i];
        console.log(`Adding script to queue: ${script.src} ${script.id}`);

        // Only load the bootstrap script after every other script has finished loading.
        if (script.src == this.loadConfig.bootstrapScript.src) {
          console.log('Found bootstrap script, will try later');
          this.loadConfig.tryLoadBootstrapScript = true;
          continue;
        }
        // Skip loading already-loaded scripts.
        if (script.id == null || self.$dartLoader.moduleIdToUrl.has(script.id)) {
          console.log(`Skipping script: ${script.src}`);
          continue;
        }

        // Register this script's resolved URL.
        let resolvedSrc = this.registerScript(script);

        // Deferred scripts should be registered but not added during bootstrap.
        if (self.$dartLoader.bootstrapModules !== void 0 &&
          !self.$dartLoader.bootstrapModules.has(script.id)) {
          continue;
        }

        if (!allowScriptFn || allowScriptFn(script)) {
          this.queue.push({ id: script.id, src: resolvedSrc });
        }
      }

      if (this.queue.length > 0) {
        console.info(
          `DDC is about to load ${this.queue.length}/${scripts.length} scripts with pool size = ${this.loadConfig.maxRequestPoolSize}`);
      }
    };

    // Creates a script element to be loaded into the provided container.
    createAndLoadScript(src, id, container, onError, onLoad) {
      console.log(`About to load ${src} in createAndLoadScript`);
      let el = self.dart_library.createScript();
      el.src = policy.createScriptURL(src);
      el.async = false;
      el.defer = true;
      el.id = id;
      el.onerror = onError;
      el.onload = onLoad;
      container.appendChild(el);
    };

    // Retrieves scripts from the loader queue, with at most [maxRequests]
    // outgoing requests.
    //
    // TODO(markzipan): Rewrite this with a promise pool.
    loadMore(maxRequests) {
      console.log(`Loading ${this.queue.length} files in loadMore`);
      let fragment = document.createDocumentFragment();
      let inflightRequests = 0;
      while (this.queue.length > 0 && inflightRequests++ < maxRequests) {
        const script = this.queue.shift();
        this.numToLoad++;
        this.createAndLoadScript(
          script.src.toString(),
          script.id,
          fragment,
          this.onError.bind(this),
          this.onLoad.bind(this)
        );
      }
      if (inflightRequests > 0) {
        document.head.appendChild(fragment);
      } else if (!this.scriptsActivelyBeingLoaded()) {
        this.loadBootstrapJs();
      }
    };

    loadOneMore() {
      if (this.queue.length > 0) {
        this.loadMore(1);
      }
    };

    // Loads modules when running with Chrome.
    loadEnqueuedModules() {
      this.loadMore(this.loadConfig.maxRequestPoolSize);
    };

    // Loads modules when running with d8.
    loadEnqueuedModulesForD8() {
      if (!self.dart_library.isD8) {
        throw Error("'loadEnqueuedModulesForD8' is only supported in D8.");
      }
      // Load all enqueued scripts sequentially.
      for (let i = 0; i < this.queue.length; i++) {
        const script = this.queue[i];
        self.load(script.src.toString());
      }
      this.queue.length = 0;
      // Load the bootstrapper script if it wasn't already loaded.
      if (this.loadConfig.tryLoadBootstrapScript) {
        const script = this.loadConfig.bootstrapScript;
        const src = this.registerScript(script);
        self.load(src);
        this.loadConfig.tryLoadBootstrapScript = false;
      }
      return;
    };

    // Loads just the bootstrap script.
    //
    // The bootstrapper is loaded only after all other scripts are loaded.
    loadBootstrapJs() {
      if (!this.loadConfig.tryLoadBootstrapScript) {
        return;
      }
      const script = this.loadConfig.bootstrapScript;
      const src = this.registerScript(script);
      this.createAndLoadScript(src, script.id, document.head, null, function () {
        // console.log('Loaded bootstrap script');
      });
      this.loadConfig.tryLoadBootstrapScript = false;
    };

    // Loads/retries compiled JS scripts.
    //
    // Should always be called after a script is loaded or errors.
    processAfterLoadOrErrorEvent() {
      if (this.scriptsActivelyBeingLoaded()) {
        if (this.numFailed == 0) {
          this.loadOneMore();
        } else if (this.attemptCount > this.maxAttempts) {
          console.log(`Some scripts have failed to load, going to load the rest. numFailed: ${numFailed}`);
          // Some scripts have failed to load. Continue loading the rest.
          this.loadOneMore();
        } else {
          // Some scripts have failed to load, but we can still make another
          // load attempt. Wait for scheduled scripts to finish.
        }
        return;
      }

      // Retry failed scripts to a limit, then load the bootstrap script.
      if (this.numFailed == 0) {
        console.log('No failed scripts, trying bootstrap');
        this.loadBootstrapJs();
        return;
      }
      // Reload whatever failed if maxAttempts is not reached.
      if (this.numFailed > 0) {
        if (this.attemptCount <= this.loadConfig.maxAttempts) {
          console.log('numFailed is greater than 0, but we still have more attempts');
          this.nextAttempt();
        } else {
          console.error(
            `Failed to load DDC scripts after ${this.loadConfig.maxAttempts} tries`);
          this.loadConfig.onLoadError();
          this.loadBootstrapJs();
        }
      }
    };

    onLoad(e) {
      console.log(`Loaded ${e.target.src} in onLoad function as part of createAndLoadScript`);
      this.numLoaded++;
      if (e.target.src == this.loadConfig.bootstrapScript.src) {
        this.loadConfig.onBootstrapSuccess();
      }
      this.processAfterLoadOrErrorEvent();
    };

    onError(e) {
      this.numFailed++;
      const target = e.target;
      self.$dartLoader.moduleIdToUrl.delete(target.id);
      self.$dartLoader.urlToModuleId.delete(target.src);
      self.deferred_loader.clearModule(target.id);

      console.log(`Failed to load ${target.src}`);

      if (target.src == this.loadConfig.bootstrapScript.src) {
        this.loadConfig.onBootstrapError();
      }
      this.processAfterLoadOrErrorEvent();
    };
  };

  let policy = {
    createScriptURL: function (src) { return src; }
  };

  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy("dartDdcModuleUrl", policy);
  }

  self.$dartLoader.loadScripts = function (scripts, loader) {
    loader.loadConfig.loadScriptFn = function (loader) {
      loader.addScriptsToQueue(scripts, null);
      loader.loadEnqueuedModules();
    };
    loader.nextAttempt();
  };
})();

if (!self.deferred_loader) {
  self.deferred_loader = {
    // Module IDs already loaded on the page (e.g., during bootstrap or after
    // loadLibrary is called).
    loadedModules: new Set(),
    // An import graph of all direct imports (not deferred).
    moduleGraph: new Map(),
    // Maps module IDs to their resolved urls.
    moduleToUrl: new Map(),
    // Module IDs mapped to their resolved or resolving promises.
    moduleToPromise: new Map(),
    // Deferred libraries on which 'loadLibrary' have already been called.
    // Load Ids are a composite of the URI of originating load's library and
    // the target library name.
    loadIds: new Set(),
  };

  /**
   * Must be called before 'main' to initialize the deferred loader.
   * @param {!Map<string, string>} moduleToUrlMapping
   * @param {!Map<string, !Array<string>>} moduleGraph non-deferred import graph
   * @param {!Array<string>} loadedModules moduled loaded during bootstrap
   */
  self.deferred_loader.initDeferredLoader = function (
    moduleToUrlMapping, moduleGraph, loadedModules) {
    self.deferred_loader.moduleToUrl = moduleToUrlMapping;
    self.deferred_loader.moduleGraph = moduleGraph;
    for (let i = 0; i < loadedModules.length; i++) {
      let module = loadedModules[i];
      self.deferred_loader.loadedModules.add(module);
      self.deferred_loader.moduleToPromise.set(module, Promise.resolve());
    }
  };

  /**
   * Returns all modules downstream of [moduleId] that are visible
   * (i.e., not deferred) and have not already been loaded.
   * @param {string} moduleId
   * @return {!Array<string>} module IDs that must be loaded with [moduleId]
   */
  let dependenciesToLoad = function (moduleId) {
    let stack = [moduleId];
    let seen = new Set();
    while (stack.length > 0) {
      let module = stack.pop();
      if (seen.has(module)) continue;
      seen.add(module);
      stack = stack.concat(self.deferred_loader.moduleGraph.get(module));
    }
    let dependencies = [];
    seen.forEach(module => {
      if (self.deferred_loader.loadedModules.has(module)) return;
      dependencies.push(module);
    });
    return dependencies;
  };

  /**
   * Loads [moduleUrl] onto this instance's DDC app's page, then invokes
   * [onLoad].
   * @param {string} moduleUrl
   * @param {function()} onLoad Callback after a successful load
   */
  let loadScript = function (moduleUrl, onLoad) {
    // A head element won't be created for D8, so just load synchronously.
    if (self.dart_library.isD8) {
      self.load(moduleUrl);
      onLoad();
      return;
    }
    let script = dart_library.createScript();
    let policy = {
      createScriptURL: function (src) {
        return src;
      }
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.setAttribute('src', policy.createScriptURL(moduleUrl));
    script.async = false;
    script.defer = true;
    script.onload = onLoad;
    self.document.head.appendChild(script);
  };

  /**
   * Performs a deferred load, calling [onSuccess] or [onError] callbacks when
   * the deferred load completes or fails, respectively.
   * @param {string} loadId {library URI}:{resource name being loaded}
   * @param {string} targetModule moduleId of the resource requested by [loadId]
   * @param {function(function())} onSuccess callback after a successful load
   * @param {function(!Error)} onError callback after a failed load
   */
  self.deferred_loader.loadDeferred = function (
    loadId, targetModule, onSuccess, onError) {
    // loadLibrary had already been called, and its module has already been
    // loaded, so just complete the future.
    if (self.deferred_loader.loadIds.has(loadId)) {
      onSuccess();
      return;
    }

    // The module's been loaded, so mark this import as loaded and finish.
    if (self.deferred_loader.loadedModules.has(targetModule)) {
      self.deferred_loader.loadIds.add(loadId);
      onSuccess();
      return;
    }

    // The import's module has not been loaded, so load it and its dependencies
    // before completing the callback.
    let modulesToLoad = dependenciesToLoad(targetModule);
    Promise
      .all(modulesToLoad.map(module => {
        let url = self.deferred_loader.moduleToUrl.get(module);
        if (url === void 0) {
          console.log('Unable to find URL for module: ' + module);
          return;
        }
        let promise = self.deferred_loader.moduleToPromise.get(module);
        if (promise !== void 0) return promise;
        self.deferred_loader.moduleToPromise.set(
          module,
          new Promise((resolve) => loadScript(url, () => {
            self.deferred_loader.loadedModules.add(module);
            resolve();
          })));
        return self.deferred_loader.moduleToPromise.get(module);
      }))
      .then(() => {
        onSuccess(() => self.deferred_loader.loadIds.add(loadId));
      })
      .catch((error) => {
        onError(error.message);
      });
  };

  /**
   * Returns whether or not the module containing [loadId] has finished loading.
   * @param {string} loadId library URI concatenated with the resource being
   *     loaded
   * @return {boolean}
   */
  self.deferred_loader.isLoaded = function (loadId) {
    return self.deferred_loader.loadIds.has(loadId);
  };

  /**
   * Removes references to [moduleId] in the deferred loader.
   * @param {string} moduleId
   *
   * TODO(markzipan): Determine how deep we should clear moduleId's references.
   */
  self.deferred_loader.clearModule = function (moduleId) {
    self.deferred_loader.loadedModules.delete(moduleId);
    self.deferred_loader.moduleToUrl.delete(moduleId);
    self.deferred_loader.moduleToPromise.delete(moduleId);
  };

  /**
   * Clears state required for hot restart.
   */
  self.deferred_loader.hotRestart = function () {
    self.deferred_loader.loadIds = new Set();
  };
}

(function (dartDevEmbedder) {
  'use strict';

  if (dartDevEmbedder) {
    console.warn('Dart Development Embedder is already defined.');
    return;
  }

  /**
   * Manager for the state of libraries that orchestrates loading and reloading
   * of libraries.
   *
   * A library moves through multiple phases from the start of the application:
   *  - Definition Phase: A library defines itself by declaring it's existence
   *    to the library manager and provides an initialization function. At this
   *    point the library is known to exist but is not yet usable. It is an
   *    error to import a library that has not been defined.
   *  - Initialization Phase: The library's initialization function is evaluated
   *    to create a library object containing all of its members. After
   *    initialization a library is ready to be linked.
   *  - Link Phase: The link function (a library member synthesized by the
   *    compiler) is called to connect class hierarchies of the classes defined
   *    by the library. This can trigger the initialization and linking of
   *    dependency libraries. After a library has been linked it is ready for
   *    use in the application.
   */
  class LibraryManager {
    // A growable mapping of library names to their initialization functions.
    libraryInitializers = Object.create(null);

    // A growable mapping of library names to their initialized library objects.
    //
    // These are the result of calling a library's initialization function.
    libraries = Object.create(null);

    pendingHotReloadLibraryNames = null;
    pendingHotReloadFileUrls = null;
    pendingHotReloadLibraryInitializers = Object.create(null);

    pendingHotRestartLibraryInitializers = Object.create(null);

    // The name of the entrypoint module. Set when the application starts for
    // the first time and used during a hot restart.
    savedEntryPointLibraryName = null;

    // The current hot restart generation.
    //
    // 0-indexed and increases by 1 on every successful hot restart.
    // This value is read to determine the 'current' hot restart generation
    // in our hot restart tests. This closely tracks but is not the same as
    // `hotRestartIteration` in DDC's runtime.
    // TODO(nshahan): This value should become shared across the embedder and
    // the runtime.
    hotRestartGeneration = 0;

    hotRestartInProgress = false;

    // TODO(nshahan): Set to true at the start of the hot reload process.
    hotReloadInProgress = false;

    // The current hot reload generation.
    //
    // 0-indexed and increases by 1 on every successful hot reload.
    hotReloadGeneration = 0;

    // The name of the entrypoint module. Set when the application starts for
    // the first time and used during a hot restart.
    savedEntryPointLibraryName = null;
    savedDartSdkRuntimeOptions = null;

    // Whether we've initialized the necessary SDK libraries before any code or
    // debugging APIs can execute.
    //
    // This should be reset whenever we recreate `libraries`, like during a hot
    // restart.
    triggeredSDKLibrariesWithSideEffects = false;

    createEmptyLibrary() {
      return Object.create(null);
    }

    // See docs on `DartDevEmbedder.runMain`.
    defineLibrary(libraryName, initializer) {
      console.log(`Defined library ${libraryName} in defineLibrary`);
      // TODO(nshahan): Make this test stronger and check for generations. A
      // library that is part of a pending hot reload could also be defined as
      // part of the previous generation.
      if (this.hotReloadInProgress) {
        if (this.pendingHotReloadLibraryNames.includes(libraryName)) {
          // If this is a library we're expecting to hot reload then collect the
          // initializer.
          this.pendingHotReloadLibraryInitializers[libraryName] = initializer;
        } else if (!(libraryName in this.libraryInitializers)) {
          // Otherwise if this is a new library (added via a new import), then
          // add the initializer to the base set of libraries.
          this.libraryInitializers[libraryName] = initializer;
        }
        // Otherwise this library is not expected to be hot reload so ignore it.
      } else if (libraryManager.hotRestartInProgress) {
        // TODO(srujzs): We should have a `pendingHotRestartLibraryNames` set
        // like we do with hot reload, but that requires a change to the
        // `hotRestart` API. This would prevent libraries that have different
        // names from the ones we expect to be compiled during a hot restart
        // from being accidentally treated as part of the hot restart.
        this.pendingHotRestartLibraryInitializers[libraryName] = initializer;
      } else if (libraryName in this.libraryInitializers) {
        throw 'Library ' + libraryName +
        ' was previously defined but DDC is not currently executing a hot ' +
        ' reload or a hot restart. Failed to define the library.';
      } else {
        this.libraryInitializers[libraryName] = initializer;
      }
    }

    /**
     * Initializes and links a library.
     *
     * @param {string} libraryName Name of the library to be initialized and
     *   linked.
     * @param {?function (Object)} installFn A function to call to install the
     *   initialized library object into the context of an import. See
     *   `importLibrary` for more details.
     */
    initializeAndLinkLibrary(libraryName, installFn) {
      if (!this.triggeredSDKLibrariesWithSideEffects) {
        this.triggerSDKLibrariesWithSideEffects();
      }
      let currentLibrary = this.libraries[libraryName];
      if (currentLibrary == null) {
        currentLibrary = this.createEmptyLibrary();
        // Run the initialization logic.
        let initializer = this.libraryInitializers[libraryName];
        if (initializer == null) {
          throw 'Library not defined: ' + libraryName + '. Failed to initialize.';
        }
        initializer(currentLibrary);
        // We make the library available in the map before linking to break out
        // of cycles in library dependencies.
        // Invariant: during linking a library dependency can be read in a state
        // where it is initialized but may not be linked.
        this.libraries[libraryName] = currentLibrary;
        // Link the library. This action will trigger the initialization and
        // linking of dependency libraries as needed.
        currentLibrary[linkSymbol]();
      }
      if (installFn != null) {
        installFn(currentLibrary);
      }
      // Invariant: at this point the library and all of its recursive
      // dependencies are fully initialized and linked.
      return currentLibrary;
    }

    // See docs on `DartDevEmbedder.runMain`.
    importLibrary(libraryName, installFn) {
      let currentLibrary = this.libraries[libraryName];
      if (currentLibrary != null) {
        // Library has already been initialized and linked.
        return currentLibrary;
      }
      // If there is no install function, the library must be initialized and
      // linked immediately.
      if (installFn == null) {
        // TODO(nshahan): Should we make this a separate API only used for the
        // SDK imports?
        return this.initializeAndLinkLibrary(libraryName);
      }

      // Library initialization is lazy and only performed on the first access.
      return new Proxy(Object.create(null), {
        get: function (_, property) {
          let library = libraryManager.initializeAndLinkLibrary(libraryName, installFn);
          return library[property];
        },
        set: function (_, property, value) {
          let library = libraryManager.initializeAndLinkLibrary(libraryName, installFn);
          library[property] = value;
          return true;
        },
      });
    }

    /**
     * Forces the SDK libraries with side effects on the JavaScript side to be
     * initialized and linked.
     *
     * These side effects could be required for correct Dart semantics
     * (ex: dart:_interceptors) or observable from a carefully crafted user
     * program (ex: dart:html). In either case, the dependencies on the side
     * effects are not expressed through a Dart import so the libraries need
     * to be loaded manually before the user program starts running or before
     * any debugging API is used.
     */
    triggerSDKLibrariesWithSideEffects() {
      this.triggeredSDKLibrariesWithSideEffects = true;
      this.initializeAndLinkLibrary('dart:_runtime');
      this.initializeAndLinkLibrary('dart:_interceptors');
      this.initializeAndLinkLibrary('dart:_native_typed_data');
      this.initializeAndLinkLibrary('dart:html');
      this.initializeAndLinkLibrary('dart:indexed_db');
      this.initializeAndLinkLibrary('dart:svg');
      this.initializeAndLinkLibrary('dart:web_audio');
      this.initializeAndLinkLibrary('dart:web_gl');
    }

    // Runs the 'main' method on `entryPointLibrary` while attaching
    // `capturedMainHandler` and `mainErrorCallback`.
    _runMain(entryPointLibrary, args = []) {
      // TODO(35113): Provide the ability to pass arguments in a type safe way.
      let runMainAndHandleErrors = () => {
        try {
          let mainValue = entryPointLibrary.main(args);
          // Attach the error callback to main's future if it's async.
          if (dartDevEmbedderConfig.mainErrorCallback != null && mainValue != null &&
            mainValue.catchError != null) {
            mainValue.catchError((e) => {
              dartDevEmbedderConfig.mainErrorCallback();
              throw e;
            });
          }
        } catch (e) {
          // Invoke the error callback if main is sync. This doesn't conflict
          // with the rethrow in the async path since DDC catches async errors
          // in a separate code path.
          if (dartDevEmbedderConfig.mainErrorCallback != null) {
            dartDevEmbedderConfig.mainErrorCallback();
          }
          throw e;
        }
      };
      if (dartDevEmbedderConfig.capturedMainHandler) {
        dartDevEmbedderConfig.capturedMainHandler(runMainAndHandleErrors);
      } else {
        runMainAndHandleErrors();
      }
    }

    // See docs on `DartDevEmbedder.runMain`.
    runMain(entryPointLibraryName, dartSdkRuntimeOptions) {
      this.setDartSDKRuntimeOptions(dartSdkRuntimeOptions);
      console.log('Starting application from main method in: ' + entryPointLibraryName + '.');
      let entryPointLibrary = this.initializeAndLinkLibrary(entryPointLibraryName);
      this.savedEntryPointLibraryName = entryPointLibraryName;
      this.savedDartSdkRuntimeOptions = dartSdkRuntimeOptions;
      this._runMain(entryPointLibrary);
    }

    setDartSDKRuntimeOptions(options) {
      let dartRuntimeLibrary = this.importLibrary('dart:_runtime');
      // TODO(nshahan) Use a single method in the Dart SDK to set all options?
      // Or assign the single JS object and read it from the SDK?
      if (options.weakNullSafetyErrors != null) {
        dartRuntimeLibrary.weakNullSafetyErrors(options.weakNullSafetyErrors);
      }
      if (options.nonNullAsserts != null) {
        dartRuntimeLibrary.nonNullAsserts(options.nonNullAsserts);
      }
      if (options.nativeNonNullAsserts != null) {
        dartRuntimeLibrary.nativeNonNullAsserts(options.nativeNonNullAsserts);
      }
      if (options.jsInteropNonNullAsserts != null) {
        dartRuntimeLibrary.jsInteropNonNullAsserts(options.jsInteropNonNullAsserts);
      }
    }

    /**
     * Begins a hot reload operation.
     *
     * @param {Array<String>} filesToLoad The urls of the files that contain
     * the libraries to hot reload.
     * @param {Array<String>} librariesToReload The names of the libraries to
     * hot reload.
     */
    async hotReloadStart(filesToLoad, librariesToReload) {
      // TODO(60842): When deferred loading is implemented, block hot reloads
      //   until all active deferred loads have completed.
      this.hotReloadInProgress = true;
      this.pendingHotReloadFileUrls ??= filesToLoad;
      this.pendingHotReloadLibraryNames ??= librariesToReload;
      // Trigger download of the new library versions.
      let reloadFilePromises = [];
      for (let file of this.pendingHotReloadFileUrls) {
        reloadFilePromises.push(
          new Promise((resolve) => {
            self.$dartLoader.forceLoadScript(file, resolve);
          })
        );
      }
      await Promise.all(reloadFilePromises).then((_) => {
        if (dartDevEmbedderConfig.capturedHotReloadEndHandler != null) {
          // Let the app decide when to update the libraries.
          dartDevEmbedderConfig.capturedHotReloadEndHandler(() => {
            this.hotReloadEnd();
          });
        } else {
          this.hotReloadEnd();
        }
      });
    }

    /**
     * Completes a hot reload operation.
     *
     * This method runs synchronously to guarantee that all libraries
     * are in a consistent state before yielding control back to the
     * application.
     */
    hotReloadEnd() {
      // Clear RTI subtype caches before initializing libraries.
      // These needs to be done before hot reload completes (and any new
      // libraries initialize) in case subtype hierarchies updated.
      let dartRtiLibrary = this.importLibrary('dart:_rti');
      dartRtiLibrary.resetRtiSubtypeCaches();

      // On a hot reload, we reuse the existing library objects to ensure all
      // references remain valid and continue to be unique. We track in
      // `previouslyLoaded` which libraries already exist in the system, so we
      // can properly initialize and link them with the new version of the code.
      let previouslyLoaded = Object.create(null);
      for (let name of this.pendingHotReloadLibraryNames) {
        previouslyLoaded[name] = (this.libraries[name] != null);
      }

      // All initializers are updated, but only libraries that were previously
      // loaded need to be reinitialized.
      for (let name of this.pendingHotReloadLibraryNames) {
        let initializer = this.pendingHotReloadLibraryInitializers[name];
        this.libraryInitializers[name] = initializer;
        if (previouslyLoaded[name]) {
          initializer(this.libraries[name]);
        }
      }

      // Then we link the existing libraries. Note this may trigger initializing
      // and linking new library dependencies that were not present before and
      // requires for all library initializers to be up to date.
      for (let name in this.pendingHotReloadLibraryInitializers) {
        if (previouslyLoaded[name]) {
          this.libraries[name][linkSymbol]();
        }
      }
      // Cleanup.
      this.pendingHotReloadLibraryInitializers = Object.create(null);
      this.pendingHotReloadLibraryNames = null;
      this.pendingHotReloadFileUrls = null;
      this.hotReloadInProgress = false;
      this.hotReloadGeneration += 1;
    }

    /**
     * Completes a hot restart operation.
     */
    hotRestart() {
      if (!this.savedEntryPointLibraryName) {
        throw "Error: Hot restart requested before application started.";
      }
      // Clear all libraries.
      this.libraries = Object.create(null);
      this.triggeredSDKLibrariesWithSideEffects = false;
      this.setDartSDKRuntimeOptions(this.savedDartSdkRuntimeOptions);
      // Update initializers. They'll be invoked later at some point after we
      // call main.
      for (let name in this.pendingHotRestartLibraryInitializers) {
        let initializer = this.pendingHotRestartLibraryInitializers[name];
        this.libraryInitializers[name] = initializer;
      }
      let entryPointLibrary = this.initializeAndLinkLibrary(this.savedEntryPointLibraryName);
      // TODO(nshahan): Start sharing a single source of truth for the restart
      // generation between the dart:_runtime and this module system.
      this.hotRestartGeneration += 1;
      console.log('Hot restarting application from main method in: ' +
        this.savedEntryPointLibraryName + ' (generation: ' +
        this.hotRestartGeneration + ').');
      // Cleanup.
      this.hotRestartInProgress = false;
      this.pendingHotRestartLibraryInitializers = Object.create(null);

      this._runMain(entryPointLibrary);
    }
  }

  // This is closed-upon to avoid exposing it through the `dartDevEmbedder`.
  const libraryManager = new LibraryManager();

  function dartDebuggerLibrary() {
    return libraryManager.initializeAndLinkLibrary('dart:_debugger');
  }

  function dartDeveloperLibrary() {
    return libraryManager.initializeAndLinkLibrary('dart:developer');
  }

  function dartRuntimeLibrary() {
    return libraryManager.initializeAndLinkLibrary('dart:_runtime');
  }

  // Map from Dart file path to its stringified source map. It should only be
  // set or accessed through the `Debugger`.
  const sourceMaps = {};

  /**
     * Common debugging APIs that may be useful for metadata, invocations,
     * developer extensions, bootstrapping, and more.
   */
  // TODO(56966): A number of APIs in this class consume and return Dart
  // objects, nested or otherwise. We should replace them with some kind of
  // metadata instead so users don't accidentally rely on the object's
  // representation. For now, we warn users to not do so in the APIs below.
  class Debugger {
    /**
     * Returns a JavaScript array of all class names in a Dart library.
     *
     * @param {string} libraryUri URI of the Dart library.
     * @returns {Array<string>} Array containing the class names in the library.
     */
    getClassesInLibrary(libraryUri) {
      libraryManager.initializeAndLinkLibrary(libraryUri);
      return dartRuntimeLibrary().getLibraryMetadata(libraryUri, libraryManager.libraries);
    }

    /**
     * Returns a JavaScript object containing metadata of a class in a given
     * Dart library.
     *
     * The object will be formatted as such:
     * ```
     * {
     *   'className': <dart class name>,
     *   'superClassName': <super class name, if any>
     *   'superClassLibraryId': <super class library ID, if any>
     *   'fields': {
     *     <name>: {
     *       'isConst': <true if the member is const>,
     *       'isFinal': <true if the member is final>,
     *       'isStatic':  <true if the member is final>,
     *       'className': <class name for a field type>,
     *       'classLibraryId': <library id for a field type>,
     *     }
     *   },
     *   'methods': {
     *     <name>: {
     *       'isConst': <true if the member is const>,
     *       'isStatic':  <true if the member is static>,
     *       'isSetter" <true if the member is a setter>,
     *       'isGetter" <true if the member is a getter>,
     *     }
     *   },
     * }
     * ```
     *
     * @param {string} libraryUri URI of the Dart library that the class is in.
     * @param {string} name Name of the Dart class.
     * @param {any} objectInstance Optional instance of the Dart class that's
     * needed to determine the type of any generic members.
     * @returns {Object<String, any>} Object containing the metadata in the
     * above format.
     */
    getClassMetadata(libraryUri, name, objectInstance) {
      libraryManager.initializeAndLinkLibrary(libraryUri);
      return dartRuntimeLibrary().getClassMetadata(libraryUri, name, objectInstance, libraryManager.libraries);
    }

    /**
     * Returns a JavaScript object containing metadata about a Dart value.
     *
     * The object will be formatted as such:
     * ```
     * {
     *   'className': <dart class name>,
     *   'libraryId': <library URI for the object type>,
     *   'runtimeKind': <kind of the object for display purposes>,
     *   'length': <length of the object if applicable>,
     *   'typeName': <name of the type represented if object is a Type>,
     * }
     * ```
     *
     * @param {Object} value Dart value for which metadata is computed.
     * @returns {Object<String, any>} Object containing the metadata in the
     * above format.
     */
    getObjectMetadata(value) {
      return dartRuntimeLibrary().getObjectMetadata(value);
    }

    /**
     * Returns the name of the given function. If it's bound to an object of
     * class `C`, returns `C.<name>` instead.
     *
     * @param {Object} fun Dart function for which the name is returned.
     * @returns {string} Name of the given function in the above format.
     */
    getFunctionName(fun) {
      return dartRuntimeLibrary().getFunctionMetadata(fun);
    }

    /**
     * Returns an array of all the field names in the Dart object.
     *
     * @param {Object} object Dart object whose field names are collected.
     * @returns {Array<string>} Array of field names.
     */
    getObjectFieldNames(object) {
      return dartRuntimeLibrary().getObjectFieldNames(object);
    }

    /**
     * If given a Dart `Set`, `List`, or `Map`, returns a sub-range array of at
     * most the given number of elements starting at the given offset. If given
     * any other Dart value, returns the original value. Any Dart values
     * returned from this API should be treated as opaque pointers and should
     * not be interacted with.
     *
     * @param {Object} object Dart object for which the sub-range is computed.
     * @param {number} offset Integer index at which the sub-range should start.
     * @param {number} count Integer number of values in the sub-range.
     * @returns {any} Either the sub-range or the original object.
     */
    getSubRange(object, offset, count) {
      return dartRuntimeLibrary().getSubRange(object, offset, count);
    }

    /**
     * Returns a JavaScript object containing the entries for a given Dart `Map`
     * that will be formatted as:
     *
     * ```
     * {
     *   'keys': [ <key>, ...],
     *   'values': [ <value>, ...],
     * }
     * ```
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {Object} map Dart `Map` whose entries will be copied.
     * @returns {Object<String, Array>} Object containing the entries in
     * the above format.
     */
    getMapElements(map) {
      return dartRuntimeLibrary().getMapElements(map);
    }

    /**
     * Returns a JavaScript object containing the entries for a given Dart `Set`
     * that will be formatted as:
     *
     * ```
     * {
     *   'entries': [ <entry>, ...],
     * }
     * ```
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {Object} set Dart `Set` whose entries will be copied.
     * @returns {Object<String, Array} Object containing the entries in the
     * above format.
     */
    getSetElements(set) {
      return dartRuntimeLibrary().getSetElements(set);
    }

    /**
     * Returns a JavaScript object containing metadata for a given Dart `Record`
     * that will be formatted as:
     *
     * ```
     * {
     *   'positionalCount': <number of positional elements>,
     *   'named': [ <name>, ...],
     *   'values': [ <positional value>, ..., <named value>, ... ],
     * }
     * ```
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {Object} record Dart `Record` whose metadata will be computed.
     * @returns {Object<String, any>} Object containing the metadata in the
     * above format.
     */
    getRecordFields(record) {
      return dartRuntimeLibrary().getRecordFields(record);
    }

    /**
     * Returns a JavaScript object containing metadata for a given Dart
     * `Record`'s runtime type that will be formatted as:
     *
     * ```
     * {
     *   'positionalCount': <number of positional types>,
     *   'named': [ <name>, ...],
     *   'types': [ <positional type>, ..., <named type>, ... ],
     * }
     * ```
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {Object} recordType Dart `Type` of a `Record` whose metadata will
     * be computed.
     * @returns {Object<String, any>} Object containing the metadata in the
     * above format.
     */
    getRecordTypeFields(recordType) {
      return dartRuntimeLibrary().getRecordTypeFields(recordType);
    }

    /**
     * Given a Dart instance, calls the method with the given name in that
     * instance and returns the result.
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {Object} instance Dart instance whose method will be called.
     * @param {string} name Name of the method.
     * @param {Array} args Array of arguments passed to the method.
     * @returns {any} Result of calling the method.
     */
    callInstanceMethod(instance, name, args) {
      return dartRuntimeLibrary().dsendRepl(instance, name, args);
    }

    /**
     * Given a Dart library URI, calls the method with the given name in that
     * library and returns the result.
     *
     * Any Dart values returned from this API should be treated as opaque
     * pointers and should not be interacted with.
     *
     * @param {any} libraryUri Dart library URI in which the method exists.
     * @param {string} name Name of the method.
     * @param {Array} args Array of arguments passed to the method.
     * @returns {any} Result of calling the method.
     */
    callLibraryMethod(libraryUri, name, args) {
      let library = libraryManager.initializeAndLinkLibrary(libraryUri);
      return library[name].apply(library, args);
    }

    /**
     * Register the DDC Chrome DevTools custom formatter into the global
     * `devtoolsFormatters` property.
     */
    registerDevtoolsFormatter() {
      dartDebuggerLibrary().registerDevtoolsFormatter();
    }

    /**
     * Invoke a registered extension with the given name and encoded map.
     *
     * @param {String} methodName The name of the registered extension.
     * @param {String} encodedJson The encoded string map that will be passed as
     * a parameter to the invoked method.
     * @returns {Promise} Promise that will await the invocation of the
     * extension.
     */
    invokeExtension(methodName, encodedJson) {
      return dartDeveloperLibrary().invokeExtension(methodName, encodedJson);
    }

    /**
     * Returns a JavaScript array containing the names of the extensions
     * registered in `dart:developer`.
     *
     * @returns {Array<string>} Array containing the extension names.
     */
    get extensionNames() {
      return dartDeveloperLibrary()._extensions.keys.toList();
    }

    /**
     * Returns a Dart stack trace string given an error caught in JS. If the
     * error is a Dart error or JS `Error`, we use the built-in stack. If the
     * error is neither, we try to construct a stack trace if possible.
     *
     * @param {any} error The error for which a stack trace will be produced.
     * @returns {String} The stringified stack trace.
     */
    stackTrace(error) {
      return dartRuntimeLibrary().stackTrace(error).toString();
    }

    /**
     * Entrypoint for DDC-generated code to set a source map for a given
     * library bundle name.
     *
     * @param {String} libraryBundleName The name of a compiled Dart library bundle.
     * @param {String} sourceMap The stringified source map.
     */
    // TODO(srujzs): If users shouldn't ever need to use this, can we make this
    // not accessible for them?
    setSourceMap(libraryBundleName, sourceMap) {
      sourceMaps[libraryBundleName] = sourceMap;
    }

    /**
     * Returns the source map path for a given library bundle name, if one was
     * registered.
     *
     * @param {String} libraryBundleName The name of a compiled Dart library bundle.
     * @returns {?String} The stringified source map if it was registered.
     */
    getSourceMap(libraryBundleName) {
      return sourceMaps[libraryBundleName];
    }
  }

  const debugger_ = new Debugger();

  /** Holds public configurations for the `DartDevEmbedder`.
   *  These properties may be modified during the runtime of the app.
   */
  class DartDevEmbedderConfiguration {
    /*
     * An optional handler that acts as a wrapper around the invocation of the
     * Dart program's 'main' method. Passed an opaque function as an argument
     * that invokes 'main' when called.
     * @type {?function(function())}
     */
    capturedMainHandler = null;

    /*
     * An optional callback that is invoked when 'main' throws.
     * @type {?function()}
     */
    mainErrorCallback = null;

    /*
     * An optional handler that acts as a wrapper around the push of the hot
     * reloaded libraries into the Dart runtime which completes the hot reload.
     * Passed an opaque function as an argument that pushes the libraries that
     * were previously loaded into the page during a call to
     * `DartDevEmbedder.hotReload` when called.
     * @type {?function(function())}
     */
    capturedHotReloadEndHandler = null;
  }

  const dartDevEmbedderConfig = new DartDevEmbedderConfiguration();

  /**
   * A symbol used to store the 'link' function on libraries.
   */
  const linkSymbol = Symbol('link');

  /** The API for embedding a Dart application in the page at development time
   *  that supports stateful hot reloading.
   */
  class DartDevEmbedder {
    /**
     * Expose the DartDevEmbedderConfig publicly.
     */
    get config() {
      return dartDevEmbedderConfig;
    }

    /**
     * Expose the 'link' symbol for library compilation.
     */
    get linkSymbol() {
      return linkSymbol;
    }

    /**
     * Runs the Dart main method.
     *
     * Intended to be invoked by the bootstrapping code where the application is
     * being embedded.
     *
     * @param {string} entryPointLibraryName The name of the library that
     * contains an entry point main method.
     * @param {Object<String, boolean>} dartSdkRuntimeOptions An options bag for
     * setting the runtime options in the Dart SDK.
     */
    runMain(entryPointLibraryName, dartSdkRuntimeOptions) {
      libraryManager.runMain(entryPointLibraryName, dartSdkRuntimeOptions);
    }

    /**
     * Declares the existence of a library identified by the `libraryName` and
     * initialized by `initFn`.
     *
     * Should only be called from DDC compiled code.
     *
     * The initialization function may be called lazily when needed.
     *
     * @param {string} libraryName Name for referencing the library being
     *   defined.
     * @param {function (Object): Object} initializer Function called to
     *   initialize the library. This callback takes a library object and
     *   installs the library members into it.
     */
    defineLibrary(libraryName, initializer) {
      libraryManager.defineLibrary(libraryName, initializer);
    }

    /**
     * Imports a library to make it available in the context of the import.
     *
     * Should only be called from DDC compiled code.
     *
     * The imported library may be initialized and linked lazily at the time of
     * the first member access.
     *
     * @param {string} libraryName Name of the library to import.
     * @param {?function (Object)} installFn A callback invoked with the library
     *  object after the library has been initialized and linked. This
     *  notification is used to improve performance. Callers may use this
     *  callback to replace the proxy object with the real library object and,
     *  in doing so, remove the overhead of jumping through an indirect proxy on
     *  every property access.
     * @return A library object or a proxy to a library object.
     */
    importLibrary(libraryName, installFn) {
      return libraryManager.importLibrary(libraryName, installFn);
    }

    /**
     * DDC's entrypoint for triggering a hot reload.
     *
     * Previous generations may continue to run until all specified files
     * have been loaded and initialized.
     *
     * @param {Array<String>} filesToLoad The urls of the files that contain
     * the libraries to hot reload.
     * @param {Array<String>} librariesToReload The names of the libraries to
     * hot reload.
     */
    async hotReload(filesToLoad, librariesToReload) {
      await libraryManager.hotReloadStart(filesToLoad, librariesToReload);
    }

    /**
     * Immediately triggers a hot restart of the application losing all state
     * and running the main method again.
     */
    async hotRestart() {
      libraryManager.hotRestartInProgress = true;
      await self.$dartReloadModifiedModules(
        libraryManager.savedEntryPointLibraryName,
        () => { libraryManager.hotRestart(); });
    }


    /**
     * @return {Number} The current hot reload generation of the running
     * application.
     */
    get hotReloadGeneration() {
      return libraryManager.hotReloadGeneration;
    }

    /**
     * @return {Number} The current hot restart generation of the running
     *  application.
     */
    get hotRestartGeneration() {
      return libraryManager.hotRestartGeneration;
    }

    /**
     * @return {Debugger} Common debugging APIs that may be useful for metadata,
     * invocations, developer extensions, bootstrapping, and more.
     */
    get debugger() {
      return debugger_;
    }
  }

  self.dartDevEmbedder = new DartDevEmbedder();
})(self.dartDevEmbedder);
''';
