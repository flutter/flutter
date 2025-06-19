// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../isolated/resident_web_runner.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';
import '../widget_preview/dependency_graph.dart';
import '../widget_preview/dtd_services.dart';
import '../widget_preview/preview_code_generator.dart';
import '../widget_preview/preview_detector.dart';
import '../widget_preview/preview_manifest.dart';
import '../widget_preview/preview_pubspec_builder.dart';
import 'create_base.dart';

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
        verbose: verboseHelp,
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
    this.verbose = false,
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
        hide: !verbose,
      )
      ..addFlag(kHeadless, help: 'Launches Chrome in headless mode for testing.', hide: !verbose)
      ..addOption(
        kWidgetPreviewScaffoldOutputDir,
        help:
            'Generated the widget preview environment scaffolding at a given location '
            'for testing purposes.',
      );
  }

  static const String kWidgetPreviewScaffoldName = 'widget_preview_scaffold';
  static const String kLaunchPreviewer = 'launch-previewer';
  static const String kHeadless = 'headless';
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

  final bool verbose;

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

  late final PreviewPubspecBuilder _previewPubspecBuilder = PreviewPubspecBuilder(
    logger: logger,
    verbose: verbose,
    offline: offline,
    rootProject: rootProject,
    previewManifest: _previewManifest,
  );

  late final PreviewDetector _previewDetector = PreviewDetector(
    projectRoot: rootProject.directory,
    logger: logger,
    fs: fs,
    onChangeDetected: onChangeDetected,
    onPubspecChangeDetected: _previewPubspecBuilder.onPubspecChangeDetected,
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
  ResidentRunner? _widgetPreviewApp;

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
    fs.currentDirectory = widgetPreviewScaffold;

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
          web: true,
        ),
        overwrite: true,
        generateMetadata: false,
        printStatusWhenWriting: verbose,
      );
      if (customPreviewScaffoldOutput != null) {
        return FlutterCommandResult.success();
      }
      _previewManifest.generate();
    }

    // WARNING: this access of widgetPreviewScaffoldProject needs to happen
    // after we generate the scaffold project as invoking the getter triggers
    // lazy initialization of the preview scaffold's FlutterManifest before
    // the scaffold project's pubspec has been generated.
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
      await _previewPubspecBuilder.populatePreviewPubspec(rootProject: rootProject);
    }

    final PreviewDependencyGraph graph = await _previewDetector.initialize();
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(graph);

    if (boolArg(kLaunchPreviewer)) {
      shutdownHooks.addShutdownHook(() async {
        await _widgetPreviewApp?.exitApp();
      });
      await configureDtd();
      _widgetPreviewApp = await runPreviewEnvironment(
        widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject,
      );
      final int result = await _widgetPreviewApp!.waitForAppToFinish();
      if (result != 0) {
        throwToolExit('Failed to launch the widget previewer.', exitCode: result);
      }
    }

    await _previewDetector.dispose();
    return FlutterCommandResult.success();
  }

  void onChangeDetected(PreviewDependencyGraph previews) {
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(previews);
    logger.printStatus('Triggering reload based on change to preview set: $previews');
    _widgetPreviewApp?.restart();
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

  Future<ResidentRunner> runPreviewEnvironment({
    required FlutterProject widgetPreviewScaffoldProject,
  }) async {
    final ResidentWebRunner runner;
    try {
      // Since the only target supported by the widget preview scaffold is the web
      // device, only a single web device should be returned.
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

      // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
      logger.printStatus('Launching the Widget Preview Scaffold...');

      final DebuggingOptions debuggingOptions = DebuggingOptions.enabled(
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
          packageConfigPath: widgetPreviewScaffoldProject.packageConfig.path,
          packageConfig: PackageConfig.parseBytes(
            widgetPreviewScaffoldProject.packageConfig.readAsBytesSync(),
            widgetPreviewScaffoldProject.packageConfig.uri,
          ),
          // Don't try and download canvaskit from the CDN.
          useLocalCanvasKit: true,
        ),
        webEnableExposeUrl: false,
        webRunHeadless: boolArg(kHeadless),
      );
      final String target = bundle.defaultMainPath;
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        device,
        target: target,
        buildInfo: debuggingOptions.buildInfo,
        platform: platform,
      );

      runner = ResidentWebRunner(
        flutterDevice,
        target: target,
        debuggingOptions: debuggingOptions,
        analytics: analytics,
        flutterProject: widgetPreviewScaffoldProject,
        fileSystem: fs,
        logger: logger,
        terminal: globals.terminal,
        platform: platform,
        outputPreferences: globals.outputPreferences,
        systemClock: globals.systemClock,
      );
      final Completer<void> appStarted = Completer<void>();
      unawaited(runner.run(appStartedCompleter: appStarted));
      await appStarted.future;
    } on Exception catch (error) {
      throwToolExit(error.toString());
    }

    // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
    logger.printStatus('Done loading previews.');
    return runner;
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
