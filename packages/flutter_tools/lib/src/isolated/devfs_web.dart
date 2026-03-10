// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
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
import '../compile.dart';
import '../devfs.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../vmservice.dart';
import '../web/bootstrap.dart';
import '../web/chrome.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web_template.dart';
import 'web_asset_server.dart';

const kLuciEnvName = 'LUCI_CONTEXT';

/// A web server which handles serving JavaScript and assets.
///
/// This is only used in development mode.
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
    required this.packagesFilePath,
    required this.urlTunneller,
    required this.useSseForDebugProxy,
    required this.useSseForDebugBackend,
    required this.useSseForInjectedClient,
    required this.buildInfo,
    required this.enableDwds,
    required this.ddsConfig,
    required this.entrypoint,
    required this.expressionCompiler,
    required this.chromiumLauncher,
    required this.nativeNullAssertions,
    required this.ddcModuleSystem,
    required this.canaryFeatures,
    required this.webDevServerConfig,
    required this.webRenderer,
    required this.isWasm,
    required this.useLocalCanvasKit,
    required this.rootDirectory,
    this.useDwdsWebSocketConnection = false,
    required this.webCrossOriginIsolation,
    required this.fileSystem,
    required this.logger,
    required this.platform,
    this.testMode = false,
    Map<String, String> webDefines = const <String, String>{},
  }) : _webDefines = webDefines {
    // TODO(srujzs): Remove this assertion when the library bundle format is
    // supported without canary mode.
    if (ddcModuleSystem) {
      assert(canaryFeatures);
    }
  }

  final Uri entrypoint;
  final String packagesFilePath;
  final UrlTunneller? urlTunneller;
  final bool useSseForDebugProxy;
  final bool useSseForDebugBackend;
  final bool useSseForInjectedClient;
  final BuildInfo buildInfo;
  final bool enableDwds;
  final DartDevelopmentServiceConfiguration ddsConfig;
  final bool testMode;
  final bool ddcModuleSystem;
  final bool canaryFeatures;
  final ExpressionCompiler? expressionCompiler;
  final ChromiumLauncher? chromiumLauncher;
  final bool nativeNullAssertions;
  final WebRendererMode webRenderer;
  final bool isWasm;
  final bool useLocalCanvasKit;
  final WebDevServerConfig webDevServerConfig;
  final bool useDwdsWebSocketConnection;
  final bool webCrossOriginIsolation;
  final FileSystem fileSystem;
  final Logger logger;
  final Platform platform;
  final Map<String, String> _webDefines;

  late WebAssetServer webAssetServer;

  Dwds get dwds => webAssetServer.dwds;

  /// Whether middleware should be enabled for this web development server.
  /// Middleware is enabled when using Chrome device or DDC module system.
  bool get shouldEnableMiddleware => chromiumLauncher != null || ddcModuleSystem;

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
    final firstConnection = Completer<ConnectionResult>();
    // Note there is an asynchronous gap between this being set to true and
    // [firstConnection] completing; thus test the boolean to determine if
    // the current connection is the first.
    var foundFirstConnection = false;
    _connectedApps = dwds.connectedApps.listen(
      (AppConnection appConnection) async {
        try {
          final DebugConnection debugConnection = useDebugExtension
              ? await (_cachedExtensionFuture ??= dwds.extensionDebugConnections.stream.first)
              : await dwds.debugConnection(appConnection);
          if (foundFirstConnection) {
            appConnection.runMain();
          } else {
            foundFirstConnection = true;
            final vm_service.VmService vmService = await vmServiceFactory(
              Uri.parse(debugConnection.uri),
              logger: logger,
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
        logger.printError('Unknown error while waiting for debug connection:$error\n$stackTrace');
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
  Uri get baseUri => webAssetServer.baseUri;

  @override
  Future<Uri> create() async {
    webAssetServer = await WebAssetServer.start(
      chromiumLauncher,
      urlTunneller,
      useSseForDebugProxy,
      useSseForDebugBackend,
      useSseForInjectedClient,
      buildInfo,
      enableDwds,
      ddsConfig,
      entrypoint,
      expressionCompiler,
      webRenderer: webRenderer,
      isWasm: isWasm,
      useLocalCanvasKit: useLocalCanvasKit,
      testMode: testMode,
      ddcModuleSystem: ddcModuleSystem,
      canaryFeatures: canaryFeatures,
      webDevServerConfig: webDevServerConfig,
      useDwdsWebSocketConnection: useDwdsWebSocketConnection,
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      crossOriginIsolation: webCrossOriginIsolation,
      shouldEnableMiddleware: shouldEnableMiddleware,
      webDefines: _webDefines,
    );
    return baseUri;
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
    final File file = fileSystem.currentDirectory.childDirectory('web').childFile(filename);
    if (!await file.exists()) {
      return;
    }

    final template = WebTemplate(await file.readAsString());
    for (final WebTemplateWarning warning in template.getWarnings()) {
      logger.printWarning('Warning: In $filename:${warning.lineNumber}: ${warning.warningText}');
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
    final File mainFile = fileSystem.file(mainUri);
    final String outputDirectoryPath = mainFile.parent.path;

    if (bundleFirstUpload) {
      webAssetServer.entrypointCacheDirectory = fileSystem.directory(outputDirectoryPath);
      generator.addFileSystemRoot(outputDirectoryPath);
      final String entrypoint = fileSystem.path.basename(mainFile.path);
      webAssetServer.writeBytes(entrypoint, mainFile.readAsBytesSync());
      if (ddcModuleSystem) {
        webAssetServer.writeBytes('ddc_module_loader.js', ddcModuleLoaderJS.readAsBytesSync());
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
                generateLoadingIndicator: shouldEnableMiddleware,
                isWindows: platform.isWindows,
              )
            : generateBootstrapScript(
                requireUrl: 'require.js',
                mapperUrl: 'stack_trace_mapper.js',
                generateLoadingIndicator: shouldEnableMiddleware,
              ),
      );
      const onLoadEndBootstrap = 'on_load_end_bootstrap.js';
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
                isCi: platform.environment.containsKey(kLuciEnvName),
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
          fileSystem.directory(getAssetBuildDirectory()),
          bundle.entries,
          targetPlatform: TargetPlatform.web_javascript,
          impellerStatus: ImpellerStatus.disabled,
          processManager: globals.processManager,
          fileSystem: fileSystem,
          artifacts: globals.artifacts!,
          logger: logger,
          projectDir: rootDirectory,
          buildMode: buildInfo.mode,
        );
      }
    }
    await _validateTemplateFile('index.html');
    await _validateTemplateFile('flutter_bootstrap.js');
    final candidateCompileTime = DateTime.now();
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
      fs: fileSystem,
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
      final Directory parentDirectory = fileSystem.directory(outputDirectoryPath);
      codeFile = parentDirectory.childFile('${compilerOutput.outputFilename}.sources');
      manifestFile = parentDirectory.childFile('${compilerOutput.outputFilename}.json');
      sourcemapFile = parentDirectory.childFile('${compilerOutput.outputFilename}.map');
      metadataFile = parentDirectory.childFile('${compilerOutput.outputFilename}.metadata');
      modules = webAssetServer.webMemoryFS.write(
        codeFile,
        manifestFile,
        sourcemapFile,
        metadataFile,
      );
    } on FileSystemException catch (err) {
      throwToolExit('Failed to load recompiled sources:\n$err');
    }
    webAssetServer.updateModulesAndDigests(modules);
    if (!bundleFirstUpload && ddcModuleSystem) {
      webAssetServer.writeReloadedSources(modules);
    }
    return UpdateFSReport(
      success: true,
      syncedBytes: codeFile.lengthSync(),
      invalidatedSourcesCount: invalidatedFiles.length,
    );
  }

  @visibleForTesting
  File get requireJS => fileSystem.file(
    fileSystem.path.join(
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
  File get ddcModuleLoaderJS => fileSystem.file(
    fileSystem.path.join(
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
  File get flutterJs => fileSystem.file(
    fileSystem.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      'flutter.js',
    ),
  );

  @visibleForTesting
  File get stackTraceMapper => fileSystem.file(
    fileSystem.path.join(
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
