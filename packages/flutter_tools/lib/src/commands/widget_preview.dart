// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/deferred_component.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../flutter_manifest.dart';
import '../linux/build_linux.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';
import '../widget_preview/dtd_services.dart';
import '../widget_preview/preview_code_generator.dart';
import '../widget_preview/preview_detector.dart';
import '../widget_preview/preview_manifest.dart';
import '../windows/build_windows.dart';
import 'create_base.dart';
import 'daemon.dart';

class WidgetPreviewCommand extends FlutterCommand {
  WidgetPreviewCommand({
    required bool verboseHelp,
    required Logger logger,
    required FileSystem fs,
    required FlutterProjectFactory projectFactory,
    required Cache cache,
    required Platform platform,
    required ShutdownHooks shutdownHooks,
    required OperatingSystemUtils os,
    required ProcessManager processManager,
    required Artifacts artifacts,
  }) {
    addSubcommand(
      WidgetPreviewStartCommand(
        verboseHelp: verboseHelp,
        logger: logger,
        fs: fs,
        projectFactory: projectFactory,
        cache: cache,
        platform: platform,
        shutdownHooks: shutdownHooks,
        os: os,
        processManager: processManager,
        artifacts: artifacts,
      ),
    );
    addSubcommand(
      WidgetPreviewCleanCommand(logger: logger, fs: fs, projectFactory: projectFactory),
    );
  }

  @override
  String get description => 'Manage the widget preview environment.';

  @override
  String get name => 'widget-preview';

  @override
  String get category => FlutterCommandCategory.tools;

  // TODO(bkonyi): show when --verbose is not provided when this feature is
  // ready to ship.
  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract base class WidgetPreviewSubCommandBase extends FlutterCommand {
  FileSystem get fs;
  Logger get logger;
  FlutterProjectFactory get projectFactory;

  FlutterProject getRootProject() {
    final ArgResults results = argResults!;
    final Directory projectDir;
    if (results.rest case <String>[final String directory]) {
      projectDir = fs.directory(directory);
      if (!projectDir.existsSync()) {
        throwToolExit('Could not find ${projectDir.path}.');
      }
    } else if (results.rest.length > 1) {
      throwToolExit('Only one directory should be provided.');
    } else {
      projectDir = fs.currentDirectory;
    }
    return validateFlutterProjectForPreview(projectDir);
  }

  FlutterProject validateFlutterProjectForPreview(Directory directory) {
    logger.printTrace('Verifying that ${directory.path} is a Flutter project.');
    final FlutterProject flutterProject = projectFactory.fromDirectory(directory);
    if (!flutterProject.dartTool.existsSync()) {
      throwToolExit('${flutterProject.directory.path} is not a valid Flutter project.');
    }
    return flutterProject;
  }
}

final class WidgetPreviewStartCommand extends WidgetPreviewSubCommandBase with CreateBase {
  WidgetPreviewStartCommand({
    this.verboseHelp = false,
    required this.logger,
    required this.fs,
    required this.projectFactory,
    required this.cache,
    required this.platform,
    required this.shutdownHooks,
    required this.os,
    required this.processManager,
    required this.artifacts,
  }) {
    addPubOptions();
    argParser
      ..addFlag(
        kLaunchPreviewer,
        defaultsTo: true,
        help: 'Launches the widget preview environment.',
        // Should only be used for testing.
        hide: !verboseHelp,
      )
      ..addFlag(
        kUseFlutterDesktop,
        help: '(deprecated) Launches the widget preview environment using Flutter Desktop.',
        hide: !verboseHelp,
      )
      ..addFlag(
        kHeadlessWeb,
        help: 'Launches Chrome in headless mode for testing.',
        hide: !verboseHelp,
      )
      ..addOption(
        kWidgetPreviewScaffoldOutputDir,
        help:
            'Generated the widget preview environment scaffolding at a given location '
            'for testing purposes.',
      );
  }

  static const String kWidgetPreviewScaffoldName = 'widget_preview_scaffold';
  static const String kLaunchPreviewer = 'launch-previewer';
  static const String kUseFlutterDesktop = 'desktop';
  static const String kHeadlessWeb = 'headless-web';
  static const String kWidgetPreviewScaffoldOutputDir = 'scaffold-output-dir';

  /// Environment variable used to pass the DTD URI to the widget preview scaffold.
  static const String kWidgetPreviewDtdUriEnvVar = 'WIDGET_PREVIEW_DTD_URI';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    // Ensure the Flutter Web SDK is installed.
    DevelopmentArtifact.web,
  };

  @override
  String get description => 'Starts the widget preview environment.';

  @override
  String get name => 'start';

  final bool verboseHelp;

  bool get isWeb => !boolArg(kUseFlutterDesktop);

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final FlutterProjectFactory projectFactory;

  final Cache cache;

  final Platform platform;

  final ShutdownHooks shutdownHooks;

  final OperatingSystemUtils os;

  final ProcessManager processManager;

  final Artifacts artifacts;

  late final FlutterProject rootProject = getRootProject();

  late final PreviewDetector _previewDetector = PreviewDetector(
    projectRoot: rootProject.directory,
    logger: logger,
    fs: fs,
    onChangeDetected: onChangeDetected,
    onPubspecChangeDetected: onPubspecChangeDetected,
  );

  late final PreviewCodeGenerator _previewCodeGenerator;
  late final PreviewManifest _previewManifest = PreviewManifest(
    logger: logger,
    rootProject: rootProject,
    fs: fs,
    cache: cache,
  );

  late final WidgetPreviewDtdServices _dtdService = WidgetPreviewDtdServices(
    logger: logger,
    shutdownHooks: shutdownHooks,
    dtdLauncher: DtdLauncher(logger: logger, artifacts: artifacts, processManager: processManager),
  );

  /// The currently running instance of the widget preview scaffold.
  AppInstance? _widgetPreviewApp;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? customPreviewScaffoldOutput = stringArg(kWidgetPreviewScaffoldOutputDir);
    final Directory widgetPreviewScaffold =
        customPreviewScaffoldOutput != null
            ? fs.directory(customPreviewScaffoldOutput)
            : rootProject.widgetPreviewScaffold;

    // Check to see if a preview scaffold has already been generated. If not,
    // generate one.
    final bool generateScaffoldProject =
        customPreviewScaffoldOutput != null || _previewManifest.shouldGenerateProject();
    // TODO(bkonyi): can this be moved?
    widgetPreviewScaffold.createSync();

    if (generateScaffoldProject) {
      // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
      logger.printStatus(
        'Creating widget preview scaffolding at: ${widgetPreviewScaffold.absolute.path}',
      );
      await generateApp(
        <String>['app', kWidgetPreviewScaffoldName],
        widgetPreviewScaffold,
        createTemplateContext(
          organization: 'flutter',
          projectName: kWidgetPreviewScaffoldName,
          titleCaseProjectName: 'Widget Preview Scaffold',
          flutterRoot: Cache.flutterRoot!,
          dartSdkVersionBounds: '^${cache.dartSdkBuild}',
          linux: platform.isLinux && !isWeb,
          macos: platform.isMacOS && !isWeb,
          windows: platform.isWindows && !isWeb,
          web: isWeb,
        ),
        overwrite: true,
        generateMetadata: false,
      );
      if (customPreviewScaffoldOutput != null) {
        return FlutterCommandResult.success();
      }
      _previewManifest.generate();

      // WARNING: this access of widgetPreviewScaffoldProject needs to happen
      // after we generate the scaffold project as invoking the getter triggers
      // lazy initialization of the preview scaffold's FlutterManifest before
      // the scaffold project's pubspec has been generated.
      // TODO(bkonyi): add logic to rebuild after SDK updates
      await initialBuild(widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject);
    }

    _previewCodeGenerator = PreviewCodeGenerator(
      widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject,
      fs: fs,
    );

    if (generateScaffoldProject || _previewManifest.shouldRegeneratePubspec()) {
      if (!generateScaffoldProject) {
        logger.printStatus(
          'Detected changes in pubspec.yaml. Regenerating pubspec.yaml for the '
          'widget preview scaffold.',
        );
      }
      // TODO(matanlurey): Remove this comment once flutter_gen is removed.
      //
      // Tracking removal: https://github.com/flutter/flutter/issues/102983.
      //
      // Populate the pubspec after the initial build to avoid blowing away the package_config.json
      // which may have manual changes for flutter_gen support.
      await _populatePreviewPubspec(rootProject: rootProject);
    }

    final PreviewMapping initialPreviews = await _previewDetector.initialize();
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(initialPreviews);

    if (boolArg(kLaunchPreviewer)) {
      shutdownHooks.addShutdownHook(() async {
        await _widgetPreviewApp?.stop();
      });
      await configureDtd();
      _widgetPreviewApp = await runPreviewEnvironment(
        widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject,
      );
      final int result = await _widgetPreviewApp!.runner.waitForAppToFinish();
      if (result != 0) {
        throwToolExit('Failed to launch the widget previewer.', exitCode: result);
      }
    }

    await _previewDetector.dispose();
    return FlutterCommandResult.success();
  }

  void onChangeDetected(PreviewMapping previews) {
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(previews);
    logger.printStatus('Triggering reload based on change to preview set: $previews');
    _widgetPreviewApp?.restart();
  }

  void onPubspecChangeDetected() {
    // TODO(bkonyi): trigger hot reload or restart?
    logger.printStatus('Changes to pubspec.yaml detected.');
    _populatePreviewPubspec(rootProject: rootProject);
  }

  /// Configures the Dart Tooling Daemon connection.
  ///
  /// If --dtd-uri is provided, the existing DTD instance will be used. If the tool fails to
  /// connect to this URI, it will start its own DTD instance.
  ///
  /// If --dtd-uri is not provided, a DTD instance managed by the tool will be started.
  Future<void> configureDtd() async {
    final String? existingDtdUriStr = stringArg(FlutterGlobalOptions.kDtdUrl, global: true);
    Uri? existingDtdUri;
    try {
      if (existingDtdUriStr != null) {
        existingDtdUri = Uri.parse(existingDtdUriStr);
      }
    } on FormatException {
      logger.printWarning('Failed to parse value of --dtd-uri: $existingDtdUriStr.');
    }
    if (existingDtdUri == null) {
      logger.printTrace('Launching a fresh DTD instance...');
      await _dtdService.launchAndConnect();
    } else {
      logger.printTrace('Connecting to existing DTD instance at: $existingDtdUri...');
      await _dtdService.connect(dtdWsUri: existingDtdUri);
    }
  }

  /// Builds the application binary for the widget preview scaffold the first
  /// time the widget preview command is run.
  ///
  /// The resulting binary is used to speed up subsequent widget previewer launches
  /// by acting as a basic scaffold to load previews into using hot reload / restart.
  Future<void> initialBuild({required FlutterProject widgetPreviewScaffoldProject}) async {
    // Generate initial package_config.json, otherwise the build will fail.
    await pub.get(
      context: PubContext.create,
      project: widgetPreviewScaffoldProject,
      offline: offline,
      outputMode: PubOutputMode.summaryOnly,
    );

    // TODO(bkonyi): handle error case where desktop device isn't enabled.
    await widgetPreviewScaffoldProject.ensureReadyForPlatformSpecificTooling(
      releaseMode: false,
      linuxPlatform: platform.isLinux && !isWeb,
      macOSPlatform: platform.isMacOS && !isWeb,
      windowsPlatform: platform.isWindows && !isWeb,
      webPlatform: isWeb,
    );

    if (isWeb) {
      return;
    }

    // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
    logger.printStatus('Performing initial build of the Widget Preview Scaffold...');

    final BuildInfo buildInfo = BuildInfo(
      BuildMode.debug,
      null,
      treeShakeIcons: false,
      packageConfigPath: widgetPreviewScaffoldProject.packageConfig.path,
    );

    if (platform.isMacOS) {
      await buildMacOS(
        flutterProject: widgetPreviewScaffoldProject,
        buildInfo: buildInfo,
        verboseLogging: false,
      );
    } else if (platform.isLinux) {
      await buildLinux(
        widgetPreviewScaffoldProject.linux,
        buildInfo,
        targetPlatform:
            os.hostPlatform == HostPlatform.linux_x64
                ? TargetPlatform.linux_x64
                : TargetPlatform.linux_arm64,
        logger: logger,
      );
    } else if (platform.isWindows) {
      await buildWindows(
        widgetPreviewScaffoldProject.windows,
        buildInfo,
        os.hostPlatform == HostPlatform.windows_x64
            ? TargetPlatform.windows_x64
            : TargetPlatform.windows_arm64,
      );
    } else {
      throw UnimplementedError();
    }
    // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
    logger.printStatus('Widget Preview Scaffold initial build complete.');
  }

  /// Returns the path to a prebuilt widget_preview_scaffold application binary.
  String prebuiltApplicationBinaryPath({required FlutterProject widgetPreviewScaffoldProject}) {
    assert(platform.isLinux || platform.isMacOS || platform.isWindows);
    String path;
    if (platform.isMacOS) {
      path = fs.path.join(
        getMacOSBuildDirectory(),
        'Build/Products/Debug/widget_preview_scaffold.app',
      );
    } else if (platform.isLinux) {
      path = fs.path.join(
        getLinuxBuildDirectory(
          os.hostPlatform == HostPlatform.linux_x64
              ? TargetPlatform.linux_x64
              : TargetPlatform.linux_arm64,
        ),
        'debug/bundle/widget_preview_scaffold',
      );
    } else if (platform.isWindows) {
      path = fs.path.join(
        getWindowsBuildDirectory(
          os.hostPlatform == HostPlatform.windows_x64
              ? TargetPlatform.windows_x64
              : TargetPlatform.windows_arm64,
        ),
        'runner/Debug/widget_preview_scaffold.exe',
      );
    } else {
      throw StateError('Unknown OS');
    }
    path = fs.path.join(widgetPreviewScaffoldProject.directory.path, path);
    if (fs.typeSync(path) == FileSystemEntityType.notFound) {
      logger.printStatus(fs.currentDirectory.toString());
      throw StateError('Could not find prebuilt application binary at $path.');
    }
    return path;
  }

  Future<AppInstance> runPreviewEnvironment({
    required FlutterProject widgetPreviewScaffoldProject,
  }) async {
    final AppInstance app;
    try {
      // Since the only target supported by the widget preview scaffold is the host's desktop
      // device, only a single desktop device should be returned.
      final List<Device> devices = await deviceManager!.getDevices(
        filter: DeviceDiscoveryFilter(
          supportFilter: DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProject(
            flutterProject: widgetPreviewScaffoldProject,
          ),
          deviceConnectionInterface: DeviceConnectionInterface.attached,
        ),
      );
      assert(devices.length == 1);
      final Device device = devices.first;

      // We launch from a prebuilt widget preview scaffold instance to reduce launch times after
      // the first run.
      File? prebuiltApplicationBinary;
      if (!isWeb) {
        prebuiltApplicationBinary = fs.file(
          prebuiltApplicationBinaryPath(widgetPreviewScaffoldProject: widgetPreviewScaffoldProject),
        );
      }
      const String? kEmptyRoute = null;
      const bool kEnableHotReload = true;

      // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
      logger.printStatus('Launching the Widget Preview Scaffold...');

      app = await Daemon.createMachineDaemon().appDomain.startApp(
        device,
        widgetPreviewScaffoldProject.directory.path,
        bundle.defaultMainPath,
        kEmptyRoute, // route
        DebuggingOptions.enabled(
          BuildInfo(
            BuildMode.debug,
            null,
            treeShakeIcons: false,
            // Provide the DTD connection information directly to the preview scaffold.
            // This could, in theory, be provided via a follow up call to a service extension
            // registered by the preview scaffold, but there's some uncertainty around how service
            // extensions will work with Flutter web embedded in VSCode without a Chrome debugger
            // connection.
            dartDefines: <String>['$kWidgetPreviewDtdUriEnvVar=${_dtdService.dtdUri}'],
            extraFrontEndOptions:
                isWeb ? <String>['--dartdevc-canary', '--dartdevc-module-format=ddc'] : null,
            packageConfigPath: widgetPreviewScaffoldProject.packageConfig.path,
            packageConfig: PackageConfig.parseBytes(
              widgetPreviewScaffoldProject.packageConfig.readAsBytesSync(),
              widgetPreviewScaffoldProject.packageConfig.uri,
            ),
            // Don't try and download canvaskit from the CDN.
            useLocalCanvasKit: true,
          ),
          webEnableExposeUrl: false,
          webRunHeadless: boolArg(kHeadlessWeb),
        ),
        kEnableHotReload, // hot mode
        applicationBinary: prebuiltApplicationBinary,
        trackWidgetCreation: true,
        projectRootPath: widgetPreviewScaffoldProject.directory.path,
      );
    } on Exception catch (error) {
      throwToolExit(error.toString());
    }

    if (!isWeb) {
      // Immediately perform a hot restart to ensure new previews are loaded into the prebuilt
      // application.
      // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
      logger.printStatus('Loading previews into the Widget Preview Scaffold...');
      await app.restart(fullRestart: true);
    }
    // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
    logger.printStatus('Done loading previews.');
    return app;
  }

  @visibleForTesting
  static const Map<String, String> flutterGenPackageConfigEntry = <String, String>{
    'name': 'flutter_gen',
    'rootUri': '../../flutter_gen',
    'languageVersion': '2.12',
  };

  /// Maps asset URIs to relative paths for the widget preview project to
  /// include.
  @visibleForTesting
  static Uri transformAssetUri(Uri uri) {
    // Assets provided by packages always start with 'packages' and do not
    // require their URIs to be updated.
    if (uri.path.startsWith('packages')) {
      return uri;
    }
    // Otherwise, the asset is contained within the root project and needs
    // to be referenced from the widget preview scaffold project's pubspec.
    return Uri(path: '../../${uri.path}');
  }

  @visibleForTesting
  static AssetsEntry transformAssetsEntry(AssetsEntry asset) {
    return AssetsEntry(
      uri: transformAssetUri(asset.uri),
      flavors: asset.flavors,
      transformers: asset.transformers,
    );
  }

  @visibleForTesting
  static FontAsset transformFontAsset(FontAsset asset) {
    return FontAsset(transformAssetUri(asset.assetUri), weight: asset.weight, style: asset.style);
  }

  @visibleForTesting
  static DeferredComponent transformDeferredComponent(DeferredComponent component) {
    return DeferredComponent(
      name: component.name,
      // TODO(bkonyi): verify these library paths are always package: paths from the parent project.
      libraries: component.libraries,
      assets: component.assets.map(transformAssetsEntry).toList(),
    );
  }

  @visibleForTesting
  FlutterManifest buildPubspec({
    required FlutterManifest rootManifest,
    required FlutterManifest widgetPreviewManifest,
  }) {
    final List<AssetsEntry> assets = rootManifest.assets.map(transformAssetsEntry).toList();

    final List<Font> fonts = <Font>[
      ...widgetPreviewManifest.fonts,
      ...rootManifest.fonts.map((Font font) {
        return Font(font.familyName, font.fontAssets.map(transformFontAsset).toList());
      }),
    ];

    final List<Uri> shaders = rootManifest.shaders.map(transformAssetUri).toList();

    final List<DeferredComponent>? deferredComponents =
        rootManifest.deferredComponents?.map(transformDeferredComponent).toList();

    return widgetPreviewManifest.copyWith(
      logger: logger,
      assets: assets,
      fonts: fonts,
      shaders: shaders,
      deferredComponents: deferredComponents,
    );
  }

  Future<void> _populatePreviewPubspec({required FlutterProject rootProject}) async {
    final FlutterProject widgetPreviewScaffoldProject = rootProject.widgetPreviewScaffoldProject;

    // Overwrite the pubspec for the preview scaffold project to include assets
    // from the root project.
    widgetPreviewScaffoldProject.replacePubspec(
      buildPubspec(
        rootManifest: rootProject.manifest,
        widgetPreviewManifest: widgetPreviewScaffoldProject.manifest,
      ),
    );

    // Adds a path dependency on the parent project so previews can be
    // imported directly into the preview scaffold.
    const String pubAdd = 'add';
    // Use `json.encode` to handle escapes correctly.
    final String pathDescriptor = json.encode(<String, Object?>{
      // `pub add` interprets relative paths relative to the current directory.
      'path': rootProject.directory.fileSystem.path.relative(rootProject.directory.path),
    });

    await pub.interactively(
      <String>[
        pubAdd,
        if (offline) '--offline',
        '--directory',
        widgetPreviewScaffoldProject.directory.path,
        // Ensure the path using POSIX separators, otherwise the "path_not_posix" check will fail.
        '${rootProject.manifest.appName}:$pathDescriptor',
      ],
      context: PubContext.pubAdd,
      command: pubAdd,
      touchesPackageConfig: true,
    );

    // Adds dependencies on:
    //   - dtd, which is used to connect to the Dart Tooling Daemon to establish communication
    //     with other developer tools.
    //   - flutter_lints, which is referenced by the analysis_options.yaml generated by the 'app'
    //     template.
    //   - stack_trace, which is used to generate terse stack traces for displaying errors thrown
    //     by widgets being previewed.
    //   - url_launcher, which is used to open a browser to the preview documentation.
    await pub.interactively(
      <String>[
        pubAdd,
        if (offline) '--offline',
        '--directory',
        widgetPreviewScaffoldProject.directory.path,
        'dtd',
        'flutter_lints',
        'stack_trace',
        'url_launcher',
      ],
      context: PubContext.pubAdd,
      command: pubAdd,
      touchesPackageConfig: true,
    );

    // Generate package_config.json.
    await pub.get(
      context: PubContext.create,
      project: widgetPreviewScaffoldProject,
      offline: offline,
      outputMode: PubOutputMode.summaryOnly,
    );

    maybeAddFlutterGenToPackageConfig(rootProject: rootProject);
    _previewManifest.updatePubspecHash();
  }

  /// Manually adds an entry for package:flutter_gen to the preview scaffold's
  /// package_config.json if the target project makes use of localization.
  ///
  /// The Flutter Tool does this when running a Flutter project with
  /// localization instead of modifying the user's pubspec.yaml to depend on it
  /// as a path dependency. Unfortunately, the preview scaffold still needs to
  /// add it directly to its package_config.json as the generated package name
  /// isn't actually flutter_gen, which pub doesn't really like, and using the
  /// actual package name will break applications which import
  /// package:flutter_gen.
  @visibleForTesting
  void maybeAddFlutterGenToPackageConfig({required FlutterProject rootProject}) {
    // TODO(matanlurey): Remove this once flutter_gen is removed.
    //
    // This is actually incorrect logic; the presence of a `generate: true`
    // does *NOT* mean that we need to add `flutter_gen` to the package config,
    // and never did, but the name of the manifest field was labeled and
    // described incorrectly.
    //
    // Tracking removal: https://github.com/flutter/flutter/issues/102983.
    if (!rootProject.manifest.generateLocalizations) {
      return;
    }
    final FlutterProject widgetPreviewScaffoldProject = rootProject.widgetPreviewScaffoldProject;
    final File packageConfig = widgetPreviewScaffoldProject.packageConfig;
    final String previewPackageConfigPath = packageConfig.path;
    if (!packageConfig.existsSync()) {
      throw StateError(
        "Could not find preview project's package_config.json at "
        '$previewPackageConfigPath',
      );
    }
    final Map<String, Object?> packageConfigJson =
        json.decode(packageConfig.readAsStringSync()) as Map<String, Object?>;
    (packageConfigJson['packages'] as List<dynamic>?)!.cast<Map<String, String>>().add(
      flutterGenPackageConfigEntry,
    );
    packageConfig.writeAsStringSync(json.encode(packageConfigJson));
    logger.printStatus('Added flutter_gen dependency to $previewPackageConfigPath');
  }
}

final class WidgetPreviewCleanCommand extends WidgetPreviewSubCommandBase {
  WidgetPreviewCleanCommand({required this.fs, required this.logger, required this.projectFactory});

  @override
  String get description => 'Cleans up widget preview state.';

  @override
  String get name => 'clean';

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final FlutterProjectFactory projectFactory;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory widgetPreviewScaffold = getRootProject().widgetPreviewScaffold;
    if (widgetPreviewScaffold.existsSync()) {
      final String scaffoldPath = widgetPreviewScaffold.path;
      logger.printStatus('Deleting widget preview scaffold at $scaffoldPath.');
      widgetPreviewScaffold.deleteSync(recursive: true);
    } else {
      logger.printStatus('Nothing to clean up.');
    }
    return FlutterCommandResult.success();
  }
}
