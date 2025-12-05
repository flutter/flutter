// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../convert.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../isolated/resident_web_runner.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import '../web/web_device.dart';
import '../widget_preview/analytics.dart';
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
    @visibleForTesting WidgetPreviewDtdServices? dtdServicesOverride,
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
        dtdServicesOverride: dtdServicesOverride,
      ),
    );
    addSubcommand(
      WidgetPreviewCleanCommand(logger: logger, fs: fs, projectFactory: projectFactory),
    );
  }

  @override
  String get description => 'Manage the widget preview environment.';

  @override
  String get name => kWidgetPreview;
  static const kWidgetPreview = 'widget-preview';

  @override
  String get category => FlutterCommandCategory.tools;

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
    if (!flutterProject.pubspecFile.existsSync()) {
      throwToolExit('${flutterProject.directory.path} is not a valid Flutter project.');
    }
    return flutterProject;
  }
}

final class WidgetPreviewStartCommand extends WidgetPreviewSubCommandBase with CreateBase {
  WidgetPreviewStartCommand({
    this.verbose = false,
    required Logger logger,
    required this.fs,
    required this.projectFactory,
    required this.cache,
    required this.platform,
    required this.shutdownHooks,
    required this.os,
    required this.processManager,
    required this.artifacts,
    @visibleForTesting WidgetPreviewDtdServices? dtdServicesOverride,
  }) : _logger = logger {
    if (dtdServicesOverride != null) {
      _dtdService = dtdServicesOverride;
    }
    addPubOptions();
    addMachineOutputFlag(verboseHelp: verbose);
    addDevToolsOptions(verboseHelp: verbose);
    argParser
      ..addFlag(
        kWebServer,
        help:
            'Serve the widget preview environment using the web-server device instead of the '
            'browser.',
      )
      ..addOption(
        kDtdUrl,
        help:
            'The address of an existing Dart Tooling Daemon instance to be used by the Flutter CLI.',
        hide: !verbose,
      )
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
        hide: !verbose,
      );
  }

  static const kDtdUrl = 'dtd-url';
  static const kWidgetPreviewScaffoldName = 'widget_preview_scaffold';
  static const kLaunchPreviewer = 'launch-previewer';
  static const kHeadless = 'headless';
  static const kWebServer = 'web-server';
  static const kWidgetPreviewScaffoldOutputDir = 'scaffold-output-dir';

  /// Environment variable used to pass the DTD URI to the widget preview scaffold.
  static const kWidgetPreviewDtdUriEnvVar = 'WIDGET_PREVIEW_DTD_URI';

  @visibleForTesting
  static const kBrowserNotFoundErrorMessage =
      'Failed to locate browser. Make sure you are using an up-to-date Chrome or Edge. '
      'Otherwise, consider running with --$kWebServer instead.';

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
  WidgetPreviewMachineAwareLogger get logger => _logger as WidgetPreviewMachineAwareLogger;
  final Logger _logger;

  @override
  final FlutterProjectFactory projectFactory;

  final Cache cache;

  final Platform platform;

  final ShutdownHooks shutdownHooks;

  final OperatingSystemUtils os;

  final ProcessManager processManager;

  final Artifacts artifacts;

  late final previewAnalytics = WidgetPreviewAnalytics(analytics: analytics);

  late final FlutterProject rootProject = getRootProject();

  late final _previewPubspecBuilder = PreviewPubspecBuilder(
    logger: logger,
    verbose: verbose,
    offline: offline,
    rootProject: rootProject,
    previewManifest: _previewManifest,
  );

  late final _previewDetector = PreviewDetector(
    platform: platform,
    previewAnalytics: previewAnalytics,
    project: rootProject,
    logger: logger,
    fs: fs,
    onChangeDetected: onChangeDetected,
    onPubspecChangeDetected: _previewPubspecBuilder.onPubspecChangeDetected,
  );

  late final PreviewCodeGenerator _previewCodeGenerator;
  late final _previewManifest = PreviewManifest(
    logger: logger,
    rootProject: rootProject,
    fs: fs,
    cache: cache,
  );

  late var _dtdService = WidgetPreviewDtdServices(
    previewAnalytics: previewAnalytics,
    fs: fs,
    logger: logger,
    shutdownHooks: shutdownHooks,
    onHotRestartPreviewerRequest: onHotRestartRequest,
    dtdLauncher: DtdLauncher(logger: logger, artifacts: artifacts, processManager: processManager),
    project: rootProject.widgetPreviewScaffoldProject,
  );

  /// The currently running instance of the widget preview scaffold.
  ResidentRunner? _widgetPreviewApp;

  /// The location of the widget_preview_scaffold for the current execution of the command.
  ///
  /// This is only meant for testing as there's no simple mapping from the target project to the
  /// scaffold project.
  // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/179036 is resolved.
  @visibleForTesting
  static late Directory widgetPreviewScaffold;

  @override
  Future<FlutterCommandResult> runCommand() async {
    assert(_logger is WidgetPreviewMachineAwareLogger);

    // Start the timer tracking how long it takes to launch the preview environment.
    previewAnalytics.initializeLaunchStopwatch();
    logger.sendInitializingEvent();

    final String? customPreviewScaffoldOutput = stringArg(kWidgetPreviewScaffoldOutputDir);
    widgetPreviewScaffold = customPreviewScaffoldOutput != null
        ? fs.directory(customPreviewScaffoldOutput)
        : rootProject.widgetPreviewScaffold;

    // Check to see if a preview scaffold has already been generated. If not,
    // generate one.
    final bool generateScaffoldProject =
        customPreviewScaffoldOutput != null || _previewManifest.shouldGenerateProject();
    // TODO(bkonyi): can this be moved?
    widgetPreviewScaffold.createSync(recursive: true);
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

      // Make the analytics instance aware that we generated the widget preview scaffold as part of
      // launching the previewer.
      previewAnalytics.generatedProject();
    }

    // WARNING: this access of widgetPreviewScaffoldProject needs to happen
    // after we generate the scaffold project as invoking the getter triggers
    // lazy initialization of the preview scaffold's FlutterManifest before
    // the scaffold project's pubspec has been generated.
    final FlutterProject widgetPreviewScaffoldProject = rootProject.widgetPreviewScaffoldProject;
    _previewCodeGenerator = PreviewCodeGenerator(
      widgetPreviewScaffoldProject: widgetPreviewScaffoldProject,
      fs: fs,
    );

    if (generateScaffoldProject || _previewManifest.shouldRegeneratePubspec()) {
      if (!generateScaffoldProject) {
        logger.printStatus(
          'Detected changes in pubspec.yaml. Regenerating pubspec.yaml for the '
          'widget preview scaffold.',
        );
      }
      await _previewPubspecBuilder.populatePreviewPubspec(rootProject: rootProject);
    }

    if (!widgetPreviewScaffoldProject.dartTool.existsSync()) {
      await _previewPubspecBuilder.generatePackageConfig(
        widgetPreviewScaffoldProject: widgetPreviewScaffoldProject,
      );
    }

    shutdownHooks.addShutdownHook(() async {
      await _widgetPreviewApp?.exitApp();
      await _previewDetector.dispose();
    });

    final PreviewDependencyGraph graph = await _previewDetector.initialize();
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(graph);

    await configureDtd();
    final int result = await runPreviewEnvironment(
      widgetPreviewScaffoldProject: widgetPreviewScaffoldProject,
    );
    if (result != 0) {
      throwToolExit('Failed to launch the widget previewer.', exitCode: result);
    }

    return FlutterCommandResult.success();
  }

  void onChangeDetected(PreviewDependencyGraph previews) {
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(previews);
    logger.printStatus('Triggering reload based on change to preview set: $previews');
    _widgetPreviewApp?.restart();
  }

  void onHotRestartRequest() {
    logger.printStatus('Triggering restart based on request from preview environment.');
    _widgetPreviewApp?.restart(fullRestart: true);
  }

  /// Configures the Dart Tooling Daemon connection.
  ///
  /// If --dtd-uri is provided, the existing DTD instance will be used. If the tool fails to
  /// connect to this URI, it will start its own DTD instance.
  ///
  /// If --dtd-uri is not provided, a DTD instance managed by the tool will be started.
  Future<void> configureDtd() async {
    final String? existingDtdUriStr = stringArg(kDtdUrl);
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

  Future<int> runPreviewEnvironment({required FlutterProject widgetPreviewScaffoldProject}) async {
    try {
      // In the rare case that Flutter Web is disabled, the device manager will not return any web
      // devices which will cause us to crash.
      if (!featureFlags.isWebEnabled) {
        throwToolExit(
          'Widget Previews requires Flutter Web to be enabled. Please run '
          "'flutter config --enable-web' to enable Flutter Web and try again.",
        );
      }
      final Device device;
      if (boolArg(kWebServer)) {
        final List<Device> devices;
        try {
          // The web-server device is hidden by default, make it visible before trying to look it up.
          WebServerDevice.showWebServerDevice = true;
          devices = await deviceManager!.getDevicesById(WebServerDevice.kWebServerDeviceId);
        } finally {
          // Reset the flag to false to avoid affecting other commands.
          WebServerDevice.showWebServerDevice = false;
        }
        assert(devices.length == 1);
        device = devices.single;
      } else {
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

        if (devices.isEmpty) {
          throwToolExit(kBrowserNotFoundErrorMessage);
        }
        if (devices.length > 1) {
          // Prefer Google Chrome as the target browser.
          device =
              devices.firstWhereOrNull((device) => device is GoogleChromeDevice) ?? devices.first;

          logger.printTrace(
            'Detected ${devices.length} web devices (${devices.map((e) => e.displayName).join(', ')}). '
            'Defaulting to ${device.displayName}.',
          );
        } else {
          device = devices.single;
        }
      }

      // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
      logger.printStatus('Launching the Widget Preview Scaffold on ${device.displayName}...');

      final debuggingOptions = DebuggingOptions.enabled(
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
          trackWidgetCreation: true,
          // Don't try and download canvaskit from the CDN.
          useLocalCanvasKit: true,
          webEnableHotReload: true,
        ),
        webEnableExposeUrl: false,
        webEnableExpressionEvaluation: true,
        webRunHeadless: boolArg(kHeadless),
        devToolsServerAddress: devToolsServerAddress,
      );
      final String target = bundle.defaultMainPath;
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        device,
        target: target,
        buildInfo: debuggingOptions.buildInfo,
        platform: platform,
      );

      if (boolArg(kLaunchPreviewer)) {
        final appStarted = Completer<void>();
        final connectionInfo = Completer<DebugConnectionInfo>();
        _widgetPreviewApp = ResidentWebRunner(
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
          // Explicitly provide the project root path rather than relying on the current directory
          // as the current directory exists within $TMP. At least on MacOS, when setting the
          // current directory to the widget_preview_scaffold project created under
          // `/var/folders/...`, the underlying chdir call actually changes the directory to
          // `/private/var/folders/...`. These directories are identical, but confuse the package
          // config resolution logic.
          // TODO(bkonyi): consider removing if we stop placing the scaffold in $TMP.
          // See https://github.com/flutter/flutter/issues/179036
          projectRootPath: widgetPreviewScaffoldProject.directory.absolute.path,
        );
        unawaited(
          _widgetPreviewApp!.run(
            appStartedCompleter: appStarted,
            connectionInfoCompleter: connectionInfo,
          ),
        );
        await appStarted.future;
        logger.sendStartedEvent(applicationUrl: flutterDevice.devFS!.baseUri!);
        final DebugConnectionInfo debugConnection = await connectionInfo.future;
        final Uri? devToolsUri = devToolsServerAddress ?? debugConnection.devToolsUri;
        if (devToolsUri == null) {
          throwToolExit('Could not determine DevTools server address for the widget inspector.');
        }
        _dtdService.setDevToolsServerAddress(
          devToolsServerAddress: devToolsServerAddress ?? debugConnection.devToolsUri!,
          applicationUri: debugConnection.wsUri!,
        );
      }
    } on Exception catch (error) {
      throwToolExit(error.toString());
    }

    // WARNING: this log message is used by test/integration.shard/widget_preview_test.dart
    logger.printStatus('Done loading previews.');

    // Send an analytics event reporting how long it took for the widget previewer to start.
    previewAnalytics.reportLaunchTiming();

    // If _widgetPreviewApp is null --no-launch-previewer was provided so return success.
    return _widgetPreviewApp?.waitForAppToFinish() ?? 0;
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

/// A custom logger for the widget-preview commands that disables non-event output to stdio when
/// machine mode is enabled.
final class WidgetPreviewMachineAwareLogger extends DelegatingLogger {
  WidgetPreviewMachineAwareLogger(super.delegate, {required this.machine, required this.verbose});

  final bool machine;
  final bool verbose;

  @override
  void printError(
    String message, {
    StackTrace? stackTrace,
    bool? emphasis,
    TerminalColor? color,
    int? indent,
    int? hangingIndent,
    bool? wrap,
  }) {
    if (machine) {
      sendEvent('logMessage', <String, Object?>{
        'level': 'error',
        'message': message,
        'stackTrace': ?stackTrace?.toString(),
      });
      return;
    }
    super.printError(
      message,
      stackTrace: stackTrace,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printWarning(
    String message, {
    bool? emphasis,
    TerminalColor? color,
    int? indent,
    int? hangingIndent,
    bool? wrap,
    bool fatal = true,
  }) {
    if (machine) {
      sendEvent('logMessage', <String, Object?>{'level': 'warning', 'message': message});
      return;
    }
    super.printWarning(
      message,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
      fatal: fatal,
    );
  }

  @override
  void printStatus(
    String message, {
    bool? emphasis,
    TerminalColor? color,
    bool? newline,
    int? indent,
    int? hangingIndent,
    bool? wrap,
  }) {
    if (machine) {
      sendEvent('logMessage', <String, Object?>{'level': 'status', 'message': message});
      return;
    }
    super.printStatus(
      message,
      emphasis: emphasis,
      color: color,
      newline: newline,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printBox(String message, {String? title}) {
    if (machine) {
      return;
    }
    super.printBox(message, title: title);
  }

  @override
  void printTrace(String message) {
    if (!verbose) {
      return;
    }
    if (machine) {
      sendEvent('logMessage', <String, Object?>{'level': 'trace', 'message': message});
      return;
    }
    super.printTrace(message);
  }

  /// Notifies tooling that the widget previewer is initializing.
  void sendInitializingEvent() {
    sendEvent('initializing', {'pid': pid});
  }

  /// Notifies tooling that the widget previewer has started and is being
  /// served at [applicationUrl].
  void sendStartedEvent({required Uri applicationUrl}) {
    sendEvent('started', {'url': applicationUrl.toString()});
  }

  @override
  void sendEvent(String name, [Map<String, dynamic>? args]) {
    if (!machine) {
      return;
    }
    // Don't call super.printStatus as it will result in a prefix being printed when --verbose is
    // provided.
    globals.stdio.stdout.writeln(
      json.encode([
        {'event': 'widget_preview.$name', 'params': ?args},
      ]),
    );
  }

  @override
  Status startProgress(
    String message, {
    String? progressId,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    if (machine) {
      printStatus(message);
      return SilentStatus(stopwatch: Stopwatch());
    }
    return super.startProgress(
      message,
      progressId: progressId,
      progressIndicatorPadding: progressIndicatorPadding,
    );
  }

  @override
  Status startSpinner({
    VoidCallback? onFinish,
    Duration? timeout,
    SlowWarningCallback? slowWarningCallback,
    TerminalColor? warningColor,
  }) {
    if (machine) {
      return SilentStatus(stopwatch: Stopwatch());
    }
    return super.startSpinner(
      onFinish: onFinish,
      timeout: timeout,
      slowWarningCallback: slowWarningCallback,
      warningColor: warningColor,
    );
  }
}
