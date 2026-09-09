// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart' as analytics;
import 'package:vm_service/vm_service.dart';

import '../android/android_device.dart';
import '../android/android_workflow.dart' as android_workflow;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../hook_runner.dart' show hookRunner;
import '../ios/devices.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart';
import '../tracing.dart';
import '../web/compile.dart';
import '../web/devfs_config.dart';
import '../web/web_options.dart';
import '../web/web_runner.dart';
import 'daemon.dart';

/// Shared logic between `flutter run` and `flutter drive` commands.
abstract class RunCommandBase extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  RunCommandBase({required bool verboseHelp}) {
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false);
    usesDartDefineOption();
    usesWebDefineOption();
    usesFlavorOption();
    usesWebResourcesCdnFlag();
    addNativeNullAssertions(hide: !verboseHelp);
    usesApplicationBinaryOption();
    argParser.addDescriptors(<OptionDescriptor<Object?>>[
      DebuggingOptionDescriptors.traceStartup,
      DebuggingOptionDescriptors.cacheStartupProfile,
      DebuggingOptionDescriptors.verboseSystemLogs,
      DebuggingOptionDescriptors.purgePersistentCache,
      DebuggingOptionDescriptors.route,
      DebuggingOptionDescriptors.vmserviceOutFile,
      DebuggingOptionDescriptors.disableServiceAuthCodes,
      DebuggingOptionDescriptors.disableServiceOriginCheck,
      DebuggingOptionDescriptors.startPaused(defaultsTo: startPausedDefault),
      DebuggingOptionDescriptors.dartFlags,
      DebuggingOptionDescriptors.endlessTraceBuffer,
      DebuggingOptionDescriptors.traceSystrace,
      DebuggingOptionDescriptors.traceToFile,
      DebuggingOptionDescriptors.profileMicrotasks,
      DebuggingOptionDescriptors.traceSkia,
      DebuggingOptionDescriptors.traceAllowlist,
      DebuggingOptionDescriptors.traceSkiaAllowlist,
      DebuggingOptionDescriptors.enableDartProfiling,
      DebuggingOptionDescriptors.profileStartup,
      DebuggingOptionDescriptors.enableSoftwareRendering,
      DebuggingOptionDescriptors.skiaDeterministicRendering,
      DebuggingOptionDescriptors.dartEntrypointArgs,
      DebuggingOptionDescriptors.uninstallFirst,
      WebOptions.wasm,
      DebuggingOptionDescriptors.iosProfileDebugger,
    ], verboseHelp: verboseHelp);
    usesWebOptions(verboseHelp: verboseHelp);
    usesTargetOption();
    usesPortOptions(verboseHelp: verboseHelp);
    usesIpv6Flag(verboseHelp: verboseHelp);
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    usesDeviceUserOption();
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
    addDdsOptions(verboseHelp: verboseHelp);
    addDevToolsOptions(verboseHelp: verboseHelp);
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
    usesFatalWarningsOption(verboseHelp: verboseHelp);
    addEnableImpellerFlag(verboseHelp: verboseHelp);
    addEnableFlutterGpuFlag(verboseHelp: verboseHelp);
    addEnableVulkanValidationFlag(verboseHelp: verboseHelp);
    addEnableEmbedderApiFlag(verboseHelp: verboseHelp);
    addEnableHcppFlag(verboseHelp: verboseHelp);
    addTestFlag(verboseHelp: verboseHelp);
    usesAdbLogFilteringOption(hide: !verboseHelp);
  }

  bool get traceStartup => getValue(DebuggingOptionDescriptors.traceStartup);
  bool get traceSystrace => getValue(DebuggingOptionDescriptors.traceSystrace);
  bool get enableDartProfiling => getValue(DebuggingOptionDescriptors.enableDartProfiling);
  bool get purgePersistentCache => getValue(DebuggingOptionDescriptors.purgePersistentCache);
  bool get disableServiceAuthCodes => getValue(DebuggingOptionDescriptors.disableServiceAuthCodes);
  bool get disableServiceOriginCheck =>
      getValue(DebuggingOptionDescriptors.disableServiceOriginCheck);
  bool get cacheStartupProfile => getValue(DebuggingOptionDescriptors.cacheStartupProfile);
  bool get runningWithPrebuiltApplication => prebuiltApplicationBinaryPath != null;
  String? get prebuiltApplicationBinaryPath => stringArg(FlutterOptions.kUseApplicationBinary);
  bool get trackWidgetCreation => boolArg('track-widget-creation');
  ImpellerStatus get enableImpeller =>
      ImpellerStatus.fromBool(getValue(DebuggingOptionDescriptors.enableImpeller));
  bool get enableFlutterGpu => getValue(DebuggingOptionDescriptors.enableFlutterGpu) ?? false;
  bool get enableVulkanValidation => getValue(DebuggingOptionDescriptors.enableVulkanValidation);
  bool get uninstallFirst => getValue(DebuggingOptionDescriptors.uninstallFirst);
  bool get enableEmbedderApi => getValue(DebuggingOptionDescriptors.enableEmbedderApi);
  bool get testFlag => getValue(DebuggingOptionDescriptors.testFlag);

  @override
  bool get refreshWirelessDevices => true;

  /// Whether to start the application paused by default.
  bool get startPausedDefault;

  String? get route => getValue(DebuggingOptionDescriptors.route);

  String? get traceAllowlist => getValue(DebuggingOptionDescriptors.traceAllowlist);

  bool get useWasm => getValue(WebOptions.wasm);

  // Keep in sync with the [TestCommand.webRenderer] getter.
  WebRendererMode get webRenderer {
    final List<String> dartDefines = extractDartDefines(
      defineConfigJsonMap: extractDartDefineConfigJsonMap(),
    );
    return WebRendererMode.fromDartDefines(dartDefines, useWasm: useWasm);
  }

  /// Create a debugging options instance for the current `run` or `drive` invocation.
  @visibleForTesting
  @protected
  Future<DebuggingOptions> createDebuggingOptions({WebDevServerConfig? webDevServerConfig}) async {
    final BuildInfo buildInfo = await getBuildInfo();
    final int? webBrowserDebugPort =
        featureFlags.isWebEnabled && wasParsed(WebOptions.webBrowserDebugPort)
        ? int.parse(getValue(WebOptions.webBrowserDebugPort)!)
        : null;
    final List<String> webBrowserFlags = featureFlags.isWebEnabled
        ? getValue(WebOptions.webBrowserFlags)
        : const <String>[];

    final bool? webCrossOriginIsolation = wasParsed(WebOptions.crossOriginIsolation)
        ? getValue(WebOptions.crossOriginIsolation)
        : null;
    final bool? iosProfileDebugger = wasParsed(DebuggingOptionDescriptors.iosProfileDebugger)
        ? getValue(DebuggingOptionDescriptors.iosProfileDebugger)
        : null;
    if (buildInfo.mode.isRelease) {
      return DebuggingOptions.disabled(
        buildInfo,
        dartEntrypointArgs: getValue(DebuggingOptionDescriptors.dartEntrypointArgs),
        webUseSseForDebugProxy:
            featureFlags.isWebEnabled && getValue(WebOptions.webServerDebugProtocol) == 'sse',
        webUseSseForDebugBackend:
            featureFlags.isWebEnabled &&
            getValue(WebOptions.webServerDebugBackendProtocol) == 'sse',
        webUseSseForInjectedClient:
            featureFlags.isWebEnabled &&
            getValue(WebOptions.webServerDebugInjectedClientProtocol) == 'sse',
        webEnableExposeUrl: featureFlags.isWebEnabled && getValue(WebOptions.webAllowExposeUrl),
        webRunHeadless: featureFlags.isWebEnabled && getValue(WebOptions.webRunHeadless),
        webBrowserDebugPort: webBrowserDebugPort,
        webBrowserFlags: webBrowserFlags,
        webCrossOriginIsolation: webCrossOriginIsolation,
        webRenderer: webRenderer,
        webUseWasm: useWasm,
        enableImpeller: enableImpeller,
        enableFlutterGpu: enableFlutterGpu,
        enableVulkanValidation: enableVulkanValidation,
        uninstallFirst: uninstallFirst,
        enableDartProfiling: enableDartProfiling,
        enableEmbedderApi: enableEmbedderApi,
        usingCISystem: usingCISystem,
        debugLogsDirectoryPath: debugLogsDirectoryPath,
        webDevServerConfig: webDevServerConfig,
        enableHcpp: explicitEnableHcpp,
        testFlag: testFlag,
        iosProfileDebugger: iosProfileDebugger,
        traceSystrace: traceSystrace,
      );
    } else {
      return DebuggingOptions.enabled(
        buildInfo,
        startPaused: getValue(DebuggingOptionDescriptors.startPausedOption),
        disableServiceAuthCodes: disableServiceAuthCodes,
        disableServiceOriginCheck: disableServiceOriginCheck,
        cacheStartupProfile: cacheStartupProfile,
        enableDds: enableDds,
        adbLogFiltering:
            hasOption(DebuggingOptionDescriptors.adbLogFiltering) &&
            getValue(DebuggingOptionDescriptors.adbLogFiltering),
        dartEntrypointArgs: getValue(DebuggingOptionDescriptors.dartEntrypointArgs),
        dartFlags: getValue(DebuggingOptionDescriptors.dartFlags) ?? '',
        useTestFonts:
            hasOption(DebuggingOptionDescriptors.useTestFonts) &&
            getValue(DebuggingOptionDescriptors.useTestFonts),
        enableSoftwareRendering:
            hasOption(DebuggingOptionDescriptors.enableSoftwareRendering) &&
            getValue(DebuggingOptionDescriptors.enableSoftwareRendering),
        skiaDeterministicRendering:
            hasOption(DebuggingOptionDescriptors.skiaDeterministicRendering) &&
            getValue(DebuggingOptionDescriptors.skiaDeterministicRendering),
        traceSkia: getValue(DebuggingOptionDescriptors.traceSkia),
        traceAllowlist: traceAllowlist,
        traceSkiaAllowlist: getValue(DebuggingOptionDescriptors.traceSkiaAllowlist),
        traceSystrace: traceSystrace,
        traceToFile: getValue(DebuggingOptionDescriptors.traceToFile),
        endlessTraceBuffer: getValue(DebuggingOptionDescriptors.endlessTraceBuffer),
        profileMicrotasks: getValue(DebuggingOptionDescriptors.profileMicrotasks),
        purgePersistentCache: purgePersistentCache,
        deviceVmServicePort: deviceVmservicePort,
        hostVmServicePort: hostVmservicePort,
        disablePortPublication: await disablePortPublication,
        ddsPort: ddsPort,
        devToolsServerAddress: devToolsServerAddress,
        verboseSystemLogs: getValue(DebuggingOptionDescriptors.verboseSystemLogs),
        webUseSseForDebugProxy:
            featureFlags.isWebEnabled && getValue(WebOptions.webServerDebugProtocol) == 'sse',
        webUseSseForDebugBackend:
            featureFlags.isWebEnabled &&
            getValue(WebOptions.webServerDebugBackendProtocol) == 'sse',
        webUseSseForInjectedClient:
            featureFlags.isWebEnabled &&
            getValue(WebOptions.webServerDebugInjectedClientProtocol) == 'sse',
        webEnableExposeUrl: featureFlags.isWebEnabled && getValue(WebOptions.webAllowExposeUrl),
        webRunHeadless: featureFlags.isWebEnabled && getValue(WebOptions.webRunHeadless),
        webBrowserDebugPort: webBrowserDebugPort,
        webBrowserFlags: webBrowserFlags,
        webEnableExpressionEvaluation:
            featureFlags.isWebEnabled && getValue(WebOptions.webEnableExpressionEvaluation),
        webLaunchUrl: featureFlags.isWebEnabled ? getValue(WebOptions.webLaunchUrl) : null,
        webCrossOriginIsolation: webCrossOriginIsolation,
        webRenderer: webRenderer,
        webUseWasm: useWasm,
        vmserviceOutFile: getValue(DebuggingOptionDescriptors.vmserviceOutFile),
        nativeNullAssertions: getValue(CommonOptions.nativeNullAssertions),
        enableImpeller: enableImpeller,
        enableFlutterGpu: enableFlutterGpu,
        enableVulkanValidation: enableVulkanValidation,
        uninstallFirst: uninstallFirst,
        enableDartProfiling: enableDartProfiling,
        profileStartup: getValue(DebuggingOptionDescriptors.profileStartup),
        enableEmbedderApi: enableEmbedderApi,
        usingCISystem: usingCISystem,
        debugLogsDirectoryPath: debugLogsDirectoryPath,
        enableDevTools: getValue(DebuggingOptionDescriptors.enableDevTools),
        ipv6: getValue(DebuggingOptionDescriptors.ipv6),
        printDtd: boolArg(FlutterGlobalOptions.kPrintDtd, global: true),
        enableHcpp: explicitEnableHcpp,
        webDevServerConfig: webDevServerConfig,
        testFlag: testFlag,
        iosProfileDebugger: iosProfileDebugger,
      );
    }
  }

  Future<WebDevServerConfig> webDevServerConfigCore() async {
    final WebDevServerConfig fileConfig = await WebDevServerConfig.loadFromFile(
      fileSystem: globals.fs,
      logger: globals.logger,
    );

    final String? webPortArg = getValue(WebOptions.webPort);
    final int? webPort = webPortArg != null ? int.tryParse(webPortArg) : null;

    // Determine HTTPS config with CLI > file precedence
    final HttpsConfig? httpsConfig = HttpsConfig.parse(
      getValue(WebOptions.webTlsCertPath) ?? fileConfig.https?.certPath,
      getValue(WebOptions.webTlsCertKeyPath) ?? fileConfig.https?.certKeyPath,
    );

    final String? baseHref = getValue(WebOptions.baseHref) ?? fileConfig.baseHref;
    if (baseHref != null && !(baseHref.startsWith('/') && baseHref.endsWith('/'))) {
      throwToolExit(
        'Received a --base-href value of "$baseHref"\n'
        '--base-href should start and end with /',
      );
    }

    final WebDevServerConfig webDevServerConfig = fileConfig.copyWith(
      host: getValue(WebOptions.webHostname),
      port: webPort,
      https: httpsConfig,
      headers: extractWebHeaders(),
      baseHref: baseHref,
    );
    return webDevServerConfig;
  }
}

class RunCommand extends RunCommandBase {
  RunCommand({bool verboseHelp = false}) : super(verboseHelp: verboseHelp) {
    requiresPubspecYaml();
    usesFilesystemOptions(hide: !verboseHelp);
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    usesFrontendServerStarterPathOption(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    usesInitializeFromDillOption(hide: !verboseHelp);
    usesNativeAssetsOption(hide: !verboseHelp);

    // By default, the app should to publish the VM service port over mDNS.
    // This will allow subsequent "flutter attach" commands to connect to the VM
    // without needing to know the port.
    addPublishPort(verboseHelp: verboseHelp);
    addIgnoreDeprecationOption();
    addMachineOutputFlag(verboseHelp: verboseHelp);
    argParser.addDescriptor(DebuggingOptionDescriptors.useTestFonts);
    argParser
      ..addFlag(
        'await-first-frame-when-tracing',
        defaultsTo: true,
        help:
            'Whether to wait for the first frame when tracing startup ("--trace-startup"), '
            'or just dump the trace as soon as the application is running. The first frame '
            'is detected by looking for a Timeline event with the name '
            '"${Tracing.firstUsefulFrameEventName}". '
            "By default, the widgets library's binding takes care of sending this event.",
      )
      ..addFlag(
        'build',
        defaultsTo: true,
        hide: !verboseHelp,
        help:
            '(deprecated) If necessary, build the app before running. To use an existing app, pass the "--${FlutterOptions.kUseApplicationBinary}" '
            'flag with an existing application artifact.',
      )
      ..addOption('project-root', hide: !verboseHelp, help: 'Specify the project root directory.')
      ..addFlag(
        'hot',
        defaultsTo: kHotReloadDefault,
        help:
            'Run with support for hot reloading. Only available for debug mode. Not available with "--trace-startup".',
      )
      ..addFlag(
        'resident',
        defaultsTo: true,
        hide: !verboseHelp,
        help:
            'Stay resident after launching the application. Not available with "--trace-startup".',
      )
      ..addOption(
        'pid-file',
        help:
            'Specify a file to write the process ID to. '
            'You can send SIGUSR1 to trigger a hot reload '
            'and SIGUSR2 to trigger a hot restart. '
            'The file is created when the signal handlers '
            'are hooked and deleted when they are removed.',
      )
      ..addFlag(
        'report-ready',
        help:
            'Print "ready" to the console after handling a keyboard command.\n'
            'This is primarily useful for tests and other automation, but consider '
            'using "--machine" instead.',
        hide: !verboseHelp,
      )
      ..addFlag(
        'benchmark',
        negatable: false,
        hide: !verboseHelp,
        help:
            'Enable a benchmarking mode. This will run the given application, '
            'measure the startup time and the app restart time, write the '
            'results out to "refresh_benchmark.json", and exit. This flag is '
            'intended for use in generating automated flutter benchmarks.',
      );
  }

  @override
  final name = 'run';

  @override
  DeprecationBehavior get deprecationBehavior =>
      boolArg('ignore-deprecation') ? DeprecationBehavior.ignore : _deviceDeprecationBehavior;
  DeprecationBehavior _deviceDeprecationBehavior = DeprecationBehavior.none;

  @override
  final description = 'Run your Flutter app on an attached device.';

  @override
  String get category => FlutterCommandCategory.project;

  List<Device>? devices;
  Future<WebDevServerConfig?> getWebDevServerConfig() async {
    // Only support "web mode" with a single web device due to resident runner
    // refactoring required otherwise.

    if (featureFlags.isWebEnabled &&
        devices != null &&
        devices!.length == 1 &&
        await devices!.single.targetPlatform == TargetPlatform.web_javascript) {
      final WebDevServerConfig webDevServerConfig = await webDevServerConfigCore();
      return webDevServerConfig;
    }
    return null;
  }

  String? get userIdentifier => stringArg(FlutterOptions.kDeviceUser);

  @override
  bool get startPausedDefault => false;

  @override
  Future<String?> get usagePath async {
    final String? command = await super.usagePath;

    if (devices == null) {
      return command;
    }
    if (devices!.length > 1) {
      return '$command/all';
    }
    return '$command/${(await devices![0].targetPlatform).getName()}';
  }

  @override
  Future<analytics.Event> unifiedAnalyticsUsageValues(String commandPath) async {
    final AnalyticsUsageValuesRecord record = await _sharedAnalyticsUsageValues;

    return analytics.Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      runIsEmulator: record.runIsEmulator,
      runTargetName: record.runTargetName,
      runTargetOsVersion: record.runTargetOsVersion,
      runModeName: record.runModeName,
      runProjectModule: record.runProjectModule,
      runProjectHostLanguage: record.runProjectHostLanguage,
      runAndroidEmbeddingVersion: record.runAndroidEmbeddingVersion,
      runEnableImpeller: record.runEnableImpeller,
      runIOSInterfaceType: record.runIOSInterfaceType,
      runIsTest: record.runIsTest,
      runEnableHcpp: record.runEnableHcpp,
    );
  }

  late final Future<AnalyticsUsageValuesRecord> _sharedAnalyticsUsageValues = (() async {
    String deviceType, deviceOsVersion;
    bool isEmulator;
    var anyAndroidDevices = false;
    var anyIOSDevices = false;
    var anyWirelessIOSDevices = false;

    if (devices == null || devices!.isEmpty) {
      deviceType = 'none';
      deviceOsVersion = 'none';
      isEmulator = false;
    } else if (devices!.length == 1) {
      final Device device = devices![0];
      final TargetPlatform platform = await device.targetPlatform;
      anyAndroidDevices = platform == TargetPlatform.android;
      anyIOSDevices = platform == TargetPlatform.ios;
      if (device is IOSDevice && device.isWirelesslyConnected) {
        anyWirelessIOSDevices = true;
      }
      deviceType = platform.getName();
      deviceOsVersion = await device.sdkNameAndVersion;
      isEmulator = await device.isLocalEmulator;
    } else {
      deviceType = 'multiple';
      deviceOsVersion = 'multiple';
      isEmulator = false;
      for (final Device device in devices!) {
        final TargetPlatform platform = await device.targetPlatform;
        anyAndroidDevices = anyAndroidDevices || (platform == TargetPlatform.android);
        anyIOSDevices = anyIOSDevices || (platform == TargetPlatform.ios);
        if (device is IOSDevice && device.isWirelesslyConnected) {
          anyWirelessIOSDevices = true;
        }
        if (anyAndroidDevices && anyIOSDevices) {
          break;
        }
      }
    }

    String? iOSInterfaceType;
    if (anyIOSDevices) {
      iOSInterfaceType = anyWirelessIOSDevices ? 'wireless' : 'usb';
    }

    String? androidEmbeddingVersion;
    final hostLanguage = <String>[];
    if (anyAndroidDevices) {
      final AndroidProject androidProject = FlutterProject.current().android;
      if (androidProject.existsSync()) {
        hostLanguage.add(androidProject.isKotlin ? 'kotlin' : 'java');
        androidEmbeddingVersion = androidProject.getEmbeddingVersion().toString().split('.').last;
      }
    }
    if (anyIOSDevices) {
      final IosProject iosProject = FlutterProject.current().ios;
      if (iosProject.exists) {
        final Iterable<File> swiftFiles = iosProject.hostAppRoot
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((File file) => globals.fs.path.extension(file.path) == '.swift');
        hostLanguage.add(swiftFiles.isNotEmpty ? 'swift' : 'objc');
      }
    }

    final BuildInfo buildInfo = await getBuildInfo();
    final String modeName = buildInfo.modeName;
    return (
      runIsEmulator: isEmulator,
      runTargetName: deviceType,
      runTargetOsVersion: deviceOsVersion,
      runModeName: modeName,
      runProjectModule: project.isModule,
      runProjectHostLanguage: hostLanguage.join(','),
      runAndroidEmbeddingVersion: androidEmbeddingVersion,
      runEnableImpeller: enableImpeller.asBool,
      runIOSInterfaceType: iOSInterfaceType,
      runIsTest: targetFile.endsWith('_test.dart'),
      // Best-effort estimate from the main manifest; does not account for build-type
      // or flavor overlay manifests (e.g. EnableHcpp set only in src/debug/).
      runEnableHcpp: anyAndroidDevices && project.android.existsSync()
          ? (explicitEnableHcpp ?? project.android.computeHcppEnabled(ifAbsent: enableHcpp))
          : null,
    );
  })();

  @override
  bool get shouldRunPub {
    // If we are running with a prebuilt application, do not run pub.
    if (runningWithPrebuiltApplication) {
      return false;
    }

    return super.shouldRunPub;
  }

  bool shouldUseHotMode(BuildInfo buildInfo) {
    final bool hotArg = boolArg('hot');
    final bool shouldUseHotMode = hotArg && !traceStartup;
    return buildInfo.isDebug && shouldUseHotMode;
  }

  bool get stayResident => boolArg('resident');
  bool get awaitFirstFrameWhenTracing => boolArg('await-first-frame-when-tracing');

  @override
  Future<void> validateCommand() async {
    // When running with a prebuilt application, no command validation is
    // necessary.
    if (!runningWithPrebuiltApplication) {
      await super.validateCommand();
    }

    devices = await findAllTargetDevices();
    if (devices == null) {
      throwToolExit(null);
    }
    final WebDevServerConfig? webDevServerConfig = await getWebDevServerConfig();
    final webMode = webDevServerConfig != null;
    if (globals.deviceManager!.hasSpecifiedAllDevices && runningWithPrebuiltApplication) {
      throwToolExit(
        'Using "-d all" with "--${FlutterOptions.kUseApplicationBinary}" is not supported',
      );
    }

    if (userIdentifier != null &&
        devices!.every((Device device) => device.platformType != PlatformType.android)) {
      throwToolExit(
        '--${FlutterOptions.kDeviceUser} is only supported for Android. At least one Android device is required.',
      );
    }

    if (devices!.any((Device device) => device is AndroidDevice)) {
      _deviceDeprecationBehavior = DeprecationBehavior.exit;
    }

    if (useWasm && !webMode) {
      throwToolExit('--wasm is only supported on the web platform');
    }

    if (webRenderer == WebRendererMode.skwasm && !useWasm) {
      throwToolExit('Skwasm renderer requires --wasm');
    }

    final String? flavor = stringArg('flavor');
    final bool flavorsSupportedOnEveryDevice = devices!.every(
      (Device device) => device.supportsFlavors,
    );
    if (flavor != null && !flavorsSupportedOnEveryDevice) {
      globals.printWarning(
        '--flavor is only supported for Android, Linux, macOS, iOS, and Windows devices. '
        'Flavor-related features may not function properly and could '
        'behave differently in a future release.',
      );
    }

    if (argResults!.wasParsed('build')) {
      if (boolArg('build')) {
        globals.printWarning(
          'The "--build" flag is deprecated and will be removed in a future release. '
          'Building is the default behavior, so this flag can be safely removed.',
        );
      } else {
        globals.printWarning(
          'The "--no-build" flag is deprecated and will be removed in a future release. '
          'To use a prebuilt application, pass "--${FlutterOptions.kUseApplicationBinary}".',
        );
      }
    }
  }

  @visibleForTesting
  Future<ResidentRunner> createRunner({
    required bool hotMode,
    required List<FlutterDevice> flutterDevices,
    required String? applicationBinaryPath,
    required FlutterProject flutterProject,
  }) async {
    final WebDevServerConfig? webDevServerConfig = await getWebDevServerConfig();
    final webMode = webDevServerConfig != null;
    final DebuggingOptions debuggingOptions = await createDebuggingOptions(
      webDevServerConfig: webDevServerConfig,
    );

    if (hotMode && !webMode) {
      return HotRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: debuggingOptions,
        benchmarkMode: boolArg('benchmark'),
        applicationBinary: applicationBinaryPath == null
            ? null
            : globals.fs.file(applicationBinaryPath),
        projectRootPath: stringArg('project-root'),
        dillOutputPath: stringArg('output-dill'),
        stayResident: stayResident,
        analytics: globals.analytics,
        nativeAssetsYamlFile: stringArg(FlutterOptions.kNativeAssetsYamlFile),
        dartBuilder: hookRunner,
        logger: globals.logger,
      );
    } else if (webMode) {
      return webRunnerFactory!.createWebRunner(
        flutterDevices.single,
        target: targetFile,
        flutterProject: flutterProject,
        debuggingOptions: debuggingOptions,
        stayResident: stayResident,
        fileSystem: globals.fs,
        analytics: globals.analytics,
        logger: globals.logger,
        terminal: globals.terminal,
        platform: globals.platform,
        outputPreferences: globals.outputPreferences,
        systemClock: globals.systemClock,
        webDefines: extractWebDefines(),
      );
    }
    return ColdRunner(
      flutterDevices,
      target: targetFile,
      debuggingOptions: debuggingOptions,
      traceStartup: traceStartup,
      awaitFirstFrameWhenTracing: awaitFirstFrameWhenTracing,
      applicationBinary: applicationBinaryPath == null
          ? null
          : globals.fs.file(applicationBinaryPath),
      stayResident: stayResident,
      dartBuilder: hookRunner,
    );
  }

  @visibleForTesting
  Daemon createMachineDaemon() {
    return Daemon.createMachineDaemon(
      analytics: globals.analytics,
      androidSdk: globals.androidSdk,
      androidWorkflow: android_workflow.androidWorkflow,
      deviceManager: globals.deviceManager,
      featureFlags: featureFlags,
      fileSystem: globals.fs,
      java: globals.java,
      logger: globals.logger,
      outputPreferences: globals.outputPreferences,
      platform: globals.platform,
      processManager: globals.processManager,
      stdio: globals.stdio,
      systemClock: globals.systemClock,
      terminal: globals.terminal,
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    // Enable hot mode by default if `--no-hot` was not passed and we are in
    // debug mode.
    final bool hotMode = shouldUseHotMode(buildInfo);
    final String? applicationBinaryPath = prebuiltApplicationBinaryPath;
    final WebDevServerConfig? webDevServerConfig = await getWebDevServerConfig();

    if (outputMachineFormat) {
      if (devices!.length > 1) {
        throwToolExit('"--machine" does not support "-d all".');
      }
      final Daemon daemon = createMachineDaemon();
      late AppInstance app;

      final DebuggingOptions debuggingOptions = await createDebuggingOptions(
        webDevServerConfig: webDevServerConfig,
      );
      try {
        app = await daemon.appDomain.startApp(
          devices!.first,
          globals.fs.currentDirectory.path,
          targetFile,
          route,
          debuggingOptions,
          hotMode,
          webDefines: extractWebDefines(),
          applicationBinary: applicationBinaryPath == null
              ? null
              : globals.fs.file(applicationBinaryPath),
          trackWidgetCreation: trackWidgetCreation,
          projectRootPath: stringArg('project-root'),
          packagesFilePath: globalResults![FlutterGlobalOptions.kPackagesOption] as String?,
          dillOutputPath: stringArg('output-dill'),
          userIdentifier: userIdentifier,
        );
      } on Exception catch (error) {
        throwToolExit(error.toString());
      }
      final DateTime appStartedTime = globals.systemClock.now();
      final int result = await app.runner.waitForAppToFinish();
      if (result != 0) {
        throwToolExit(null, exitCode: result);
      }
      return FlutterCommandResult(
        ExitStatus.success,
        timingLabelParts: <String>['daemon'],
        endTimeOverride: appStartedTime,
      );
    }
    globals.terminal.usesTerminalUi = true;

    final BuildMode buildMode = getBuildMode();
    for (final Device device in devices!) {
      if (!await device.supportsRuntimeMode(buildMode)) {
        throwToolExit(
          '${buildMode.uppercaseFriendlyName}'
          'mode is not supported by ${device.displayName}.',
        );
      }
      if (hotMode) {
        if (!device.supportsHotReload) {
          throwToolExit(
            'Hot reload is not supported by ${device.displayName}. '
            'Run with "--no-hot".',
          );
        }
      }
    }

    final flutterDevices = <FlutterDevice>[
      for (final Device device in devices!)
        await FlutterDevice.create(
          device,
          target: targetFile,
          buildInfo: buildInfo,
          userIdentifier: userIdentifier,
          platform: globals.platform,
        ),
    ];

    final ResidentRunner runner = await createRunner(
      applicationBinaryPath: applicationBinaryPath,
      flutterDevices: flutterDevices,
      flutterProject: project,
      hotMode: hotMode,
    );

    DateTime? appStartedTime;
    // Sync completer so the completing agent attaching to the resident doesn't
    // need to know about analytics.
    //
    // Do not add more operations to the future.
    final appStartedTimeRecorder = Completer<void>.sync();

    TerminalHandler? handler;
    // This callback can't throw.
    unawaited(
      appStartedTimeRecorder.future.then<void>((_) {
        appStartedTime = globals.systemClock.now();
        if (stayResident) {
          handler =
              TerminalHandler(
                  runner,
                  logger: globals.logger,
                  terminal: globals.terminal,
                  signals: globals.signals,
                  processInfo: globals.processInfo,
                  reportReady: boolArg('report-ready'),
                  pidFile: stringArg('pid-file'),
                )
                ..registerSignalHandlers()
                ..setupTerminal();
        }
      }),
    );
    try {
      final int result = await runner.run(
        appStartedCompleter: appStartedTimeRecorder,
        route: route,
      );
      handler?.stop();
      if (result != 0) {
        throwToolExit(null, exitCode: result);
      }
    } on RPCError catch (error) {
      if (error.code == RPCErrorKind.kServiceDisappeared.code ||
          error.code == RPCErrorKind.kConnectionDisposed.code ||
          error.message.contains('Service connection disposed')) {
        throwToolExit('Lost connection to device.');
      }
      rethrow;
    } finally {
      // However we exited from the runner, ensure the terminal has line mode
      // and echo mode enabled before we return the user to the shell.
      try {
        globals.terminal.singleCharMode = false;
      } on StdinException {
        // Do nothing, if the STDIN handle is no longer available, there is nothing actionable for us to do at this point
      }
    }
    return FlutterCommandResult(
      ExitStatus.success,
      timingLabelParts: <String?>[
        if (hotMode) 'hot' else 'cold',
        getBuildMode().cliName,
        if (devices!.length == 1) (await devices![0].targetPlatform).getName() else 'multiple',
        if (devices!.length == 1 && await devices![0].isLocalEmulator) 'emulator' else null,
      ],
      endTimeOverride: appStartedTime,
    );
  }
}

/// Schema for the usage values to send for analytics reporting.
typedef AnalyticsUsageValuesRecord = ({
  String? runAndroidEmbeddingVersion,
  bool? runEnableImpeller,
  String? runIOSInterfaceType,
  bool runIsEmulator,
  bool runIsTest,
  String runModeName,
  String runProjectHostLanguage,
  bool runProjectModule,
  String runTargetName,
  String runTargetOsVersion,
  bool? runEnableHcpp,
});
