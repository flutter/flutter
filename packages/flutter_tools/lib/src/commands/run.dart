// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.



import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import '../android/android_device.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../daemon.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../tracing.dart';
import '../vmservice.dart';
import '../web/web_runner.dart';
import 'daemon.dart';

/// Shared logic between `flutter run` and `flutter drive` commands.
abstract class RunCommandBase extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  RunCommandBase({ required bool verboseHelp }) {
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false);
    usesDartDefineOption();
    usesFlavorOption();
    usesWebRendererOption();
    addNativeNullAssertions(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    usesApplicationBinaryOption();
    argParser
      ..addFlag('trace-startup',
        negatable: false,
        help: 'Trace application startup, then exit, saving the trace to a file. '
              'By default, this will be saved in the "build" directory. If the '
              'FLUTTER_TEST_OUTPUTS_DIR environment variable is set, the file '
              'will be written there instead.',
      )
      ..addFlag('cache-startup-profile',
        help: 'Caches the CPU profile collected before the first frame for startup '
              'analysis.',
      )
      ..addFlag('verbose-system-logs',
        negatable: false,
        help: 'Include verbose logging from the Flutter engine.',
      )
      ..addFlag('cache-sksl',
        negatable: false,
        help: 'Cache the shader in the SkSL format instead of in binary or GLSL formats.',
      )
      ..addFlag('dump-skp-on-shader-compilation',
        negatable: false,
        help: 'Automatically dump the skp that triggers new shader compilations. '
              'This is useful for writing custom ShaderWarmUp to reduce jank. '
              'By default, this is not enabled as it introduces significant overhead. '
              'This is only available in profile or debug builds.',
      )
      ..addFlag('purge-persistent-cache',
        negatable: false,
        help: 'Removes all existing persistent caches. This allows reproducing '
              'shader compilation jank that normally only happens the first time '
              'an app is run, or for reliable testing of compilation jank fixes '
              '(e.g. shader warm-up).',
      )
      ..addOption('route',
        help: 'Which route to load when running the app.',
      )
      ..addOption('vmservice-out-file',
        help: 'A file to write the attached vmservice URL to after an '
              'application is started.',
        valueHelp: 'project/example/out.txt',
        hide: !verboseHelp,
      )
      ..addFlag('disable-service-auth-codes',
        negatable: false,
        hide: !verboseHelp,
        help: '(deprecated) Allow connections to the VM service without using authentication codes. '
              '(Not recommended! This can open your device to remote code execution attacks!)'
      )
      ..addFlag('start-paused',
        defaultsTo: startPausedDefault,
        help: 'Start in a paused mode and wait for a debugger to connect.',
      )
      ..addOption('dart-flags',
        hide: !verboseHelp,
        help: 'Pass a list of comma separated flags to the Dart instance at '
              'application startup. Flags passed through this option must be '
              'present on the allowlist defined within the Flutter engine. If '
              'a disallowed flag is encountered, the process will be '
              'terminated immediately.\n\n'
              'This flag is not available on the stable channel and is only '
              'applied in debug and profile modes. This option should only '
              'be used for experiments and should not be used by typical users.'
      )
      ..addFlag('endless-trace-buffer',
        negatable: false,
        help: 'Enable tracing to an infinite buffer, instead of a ring buffer. '
              'This is useful when recording large traces. To use an endless buffer to '
              'record startup traces, combine this with "--trace-startup".',
      )
      ..addFlag('trace-systrace',
        negatable: false,
        help: 'Enable tracing to the system tracer. This is only useful on '
              'platforms where such a tracer is available (Android, iOS, '
              'macOS and Fuchsia).',
      )
      ..addFlag('trace-skia',
        negatable: false,
        help: 'Enable tracing of Skia code. This is useful when debugging '
              'the raster thread (formerly known as the GPU thread). '
              'By default, Flutter will not log Skia code, as it introduces significant '
              'overhead that may affect recorded performance metrics in a misleading way.',
      )
      ..addOption('trace-allowlist',
        hide: !verboseHelp,
        help: 'Filters out all trace events except those that are specified in '
              'this comma separated list of allowed prefixes.',
        valueHelp: 'foo,bar',
      )
      ..addOption('trace-skia-allowlist',
        hide: !verboseHelp,
        help: 'Filters out all Skia trace events except those that are specified in '
              'this comma separated list of allowed prefixes.',
        valueHelp: 'skia.gpu,skia.shaders',
      )
      ..addFlag('enable-dart-profiling',
        defaultsTo: true,
        help: 'Whether the Dart VM sampling CPU profiler is enabled. This flag '
              'is only meaningnful in debug and profile builds.',
      )
      ..addFlag('enable-software-rendering',
        negatable: false,
        help: 'Enable rendering using the Skia software backend. '
            'This is useful when testing Flutter on emulators. By default, '
            'Flutter will attempt to either use OpenGL or Vulkan and fall back '
            'to software when neither is available.',
      )
      ..addFlag('skia-deterministic-rendering',
        negatable: false,
        help: 'When combined with "--enable-software-rendering", this should provide completely '
            'deterministic (i.e. reproducible) Skia rendering. This is useful for testing purposes '
            '(e.g. when comparing screenshots).',
      )
      ..addMultiOption('dart-entrypoint-args',
        abbr: 'a',
        help: 'Pass a list of arguments to the Dart entrypoint at application '
              'startup. By default this is main(List<String> args). Specify '
              'this option multiple times each with one argument to pass '
              'multiple arguments to the Dart entrypoint. Currently this is '
              'only supported on desktop platforms.',
      )
      ..addFlag('uninstall-first',
        hide: !verboseHelp,
        help: 'Uninstall previous versions of the app on the device '
              'before reinstalling. Currently only supported on iOS.',
    );
    usesWebOptions(verboseHelp: verboseHelp);
    usesTargetOption();
    usesPortOptions(verboseHelp: verboseHelp);
    usesIpv6Flag(verboseHelp: verboseHelp);
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesDeviceUserOption();
    usesDeviceTimeoutOption();
    addDdsOptions(verboseHelp: verboseHelp);
    addDevToolsOptions(verboseHelp: verboseHelp);
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
    usesFatalWarningsOption(verboseHelp: verboseHelp);
    addEnableImpellerFlag(verboseHelp: verboseHelp);
  }

  bool get traceStartup => boolArgDeprecated('trace-startup');
  bool get enableDartProfiling => boolArgDeprecated('enable-dart-profiling');
  bool get cacheSkSL => boolArgDeprecated('cache-sksl');
  bool get dumpSkpOnShaderCompilation => boolArgDeprecated('dump-skp-on-shader-compilation');
  bool get purgePersistentCache => boolArgDeprecated('purge-persistent-cache');
  bool get disableServiceAuthCodes => boolArgDeprecated('disable-service-auth-codes');
  bool get cacheStartupProfile => boolArgDeprecated('cache-startup-profile');
  bool get runningWithPrebuiltApplication => argResults![FlutterOptions.kUseApplicationBinary] != null;
  bool get trackWidgetCreation => boolArgDeprecated('track-widget-creation');
  bool get enableImpeller => boolArgDeprecated('enable-impeller');
  bool get uninstallFirst => boolArgDeprecated('uninstall-first');

  @override
  bool get reportNullSafety => true;

  /// Whether to start the application paused by default.
  bool get startPausedDefault;

  String? get route => stringArgDeprecated('route');

  String? get traceAllowlist => stringArgDeprecated('trace-allowlist');

  /// Create a debugging options instance for the current `run` or `drive` invocation.
  @visibleForTesting
  @protected
  Future<DebuggingOptions> createDebuggingOptions(bool webMode) async {
    final BuildInfo buildInfo = await getBuildInfo();
    final int? webBrowserDebugPort = featureFlags.isWebEnabled && argResults!.wasParsed('web-browser-debug-port')
      ? int.parse(stringArgDeprecated('web-browser-debug-port')!)
      : null;
    final List<String> webBrowserFlags = featureFlags.isWebEnabled
        ? stringsArg(FlutterOptions.kWebBrowserFlag)
        : const <String>[];
    if (buildInfo.mode.isRelease) {
      return DebuggingOptions.disabled(
        buildInfo,
        dartEntrypointArgs: stringsArg('dart-entrypoint-args'),
        hostname: featureFlags.isWebEnabled ? stringArgDeprecated('web-hostname') : '',
        port: featureFlags.isWebEnabled ? stringArgDeprecated('web-port') : '',
        webUseSseForDebugProxy: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-protocol') == 'sse',
        webUseSseForDebugBackend: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-backend-protocol') == 'sse',
        webUseSseForInjectedClient: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-injected-client-protocol') == 'sse',
        webEnableExposeUrl: featureFlags.isWebEnabled && boolArgDeprecated('web-allow-expose-url'),
        webRunHeadless: featureFlags.isWebEnabled && boolArgDeprecated('web-run-headless'),
        webBrowserDebugPort: webBrowserDebugPort,
        webBrowserFlags: webBrowserFlags,
        enableImpeller: enableImpeller,
        uninstallFirst: uninstallFirst,
        enableDartProfiling: enableDartProfiling,
      );
    } else {
      return DebuggingOptions.enabled(
        buildInfo,
        startPaused: boolArgDeprecated('start-paused'),
        disableServiceAuthCodes: boolArgDeprecated('disable-service-auth-codes'),
        cacheStartupProfile: cacheStartupProfile,
        enableDds: enableDds,
        dartEntrypointArgs: stringsArg('dart-entrypoint-args'),
        dartFlags: stringArgDeprecated('dart-flags') ?? '',
        useTestFonts: argParser.options.containsKey('use-test-fonts') && boolArgDeprecated('use-test-fonts'),
        enableSoftwareRendering: argParser.options.containsKey('enable-software-rendering') && boolArgDeprecated('enable-software-rendering'),
        skiaDeterministicRendering: argParser.options.containsKey('skia-deterministic-rendering') && boolArgDeprecated('skia-deterministic-rendering'),
        traceSkia: boolArgDeprecated('trace-skia'),
        traceAllowlist: traceAllowlist,
        traceSkiaAllowlist: stringArgDeprecated('trace-skia-allowlist'),
        traceSystrace: boolArgDeprecated('trace-systrace'),
        endlessTraceBuffer: boolArgDeprecated('endless-trace-buffer'),
        dumpSkpOnShaderCompilation: dumpSkpOnShaderCompilation,
        cacheSkSL: cacheSkSL,
        purgePersistentCache: purgePersistentCache,
        deviceVmServicePort: deviceVmservicePort,
        hostVmServicePort: hostVmservicePort,
        disablePortPublication: disablePortPublication,
        ddsPort: ddsPort,
        devToolsServerAddress: devToolsServerAddress,
        verboseSystemLogs: boolArgDeprecated('verbose-system-logs'),
        hostname: featureFlags.isWebEnabled ? stringArgDeprecated('web-hostname') : '',
        port: featureFlags.isWebEnabled ? stringArgDeprecated('web-port') : '',
        webUseSseForDebugProxy: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-protocol') == 'sse',
        webUseSseForDebugBackend: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-backend-protocol') == 'sse',
        webUseSseForInjectedClient: featureFlags.isWebEnabled && stringArgDeprecated('web-server-debug-injected-client-protocol') == 'sse',
        webEnableExposeUrl: featureFlags.isWebEnabled && boolArgDeprecated('web-allow-expose-url'),
        webRunHeadless: featureFlags.isWebEnabled && boolArgDeprecated('web-run-headless'),
        webBrowserDebugPort: webBrowserDebugPort,
        webBrowserFlags: webBrowserFlags,
        webEnableExpressionEvaluation: featureFlags.isWebEnabled && boolArgDeprecated('web-enable-expression-evaluation'),
        webLaunchUrl: featureFlags.isWebEnabled ? stringArgDeprecated('web-launch-url') : null,
        vmserviceOutFile: stringArgDeprecated('vmservice-out-file'),
        fastStart: argParser.options.containsKey('fast-start')
          && boolArgDeprecated('fast-start')
          && !runningWithPrebuiltApplication,
        nullAssertions: boolArgDeprecated('null-assertions'),
        nativeNullAssertions: boolArgDeprecated('native-null-assertions'),
        enableImpeller: enableImpeller,
        uninstallFirst: uninstallFirst,
        enableDartProfiling: enableDartProfiling,
      );
    }
  }
}

class RunCommand extends RunCommandBase {
  RunCommand({ bool verboseHelp = false }) : super(verboseHelp: verboseHelp) {
    requiresPubspecYaml();
    usesFilesystemOptions(hide: !verboseHelp);
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    usesInitializeFromDillOption(hide: !verboseHelp);

    // By default, the app should to publish the VM service port over mDNS.
    // This will allow subsequent "flutter attach" commands to connect to the VM
    // without needing to know the port.
    addPublishPort(verboseHelp: verboseHelp);
    addMultidexOption();
    addIgnoreDeprecationOption();
    argParser
      ..addFlag('await-first-frame-when-tracing',
        defaultsTo: true,
        help: 'Whether to wait for the first frame when tracing startup ("--trace-startup"), '
              'or just dump the trace as soon as the application is running. The first frame '
              'is detected by looking for a Timeline event with the name '
              '"${Tracing.firstUsefulFrameEventName}". '
              "By default, the widgets library's binding takes care of sending this event.",
      )
      ..addFlag('use-test-fonts',
        help: 'Enable (and default to) the "Ahem" font. This is a special font '
              'used in tests to remove any dependencies on the font metrics. It '
              'is enabled when you use "flutter test". Set this flag when running '
              'a test using "flutter run" for debugging purposes. This flag is '
              'only available when running in debug mode.',
      )
      ..addFlag('build',
        defaultsTo: true,
        help: 'If necessary, build the app before running.',
      )
      ..addOption('project-root',
        hide: !verboseHelp,
        help: 'Specify the project root directory.',
      )
      ..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
              'and progress in machine friendly format.',
      )
      ..addFlag('hot',
        defaultsTo: kHotReloadDefault,
        help: 'Run with support for hot reloading. Only available for debug mode. Not available with "--trace-startup".',
      )
      ..addFlag('resident',
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Stay resident after launching the application. Not available with "--trace-startup".',
      )
      ..addOption('pid-file',
        help: 'Specify a file to write the process ID to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart. '
              'The file is created when the signal handlers '
              'are hooked and deleted when they are removed.',
      )..addFlag(
        'report-ready',
        help: 'Print "ready" to the console after handling a keyboard command.\n'
              'This is primarily useful for tests and other automation, but consider '
              'using "--machine" instead.',
        hide: !verboseHelp,
      )..addFlag('benchmark',
        negatable: false,
        hide: !verboseHelp,
        help: 'Enable a benchmarking mode. This will run the given application, '
              'measure the startup time and the app restart time, write the '
              'results out to "refresh_benchmark.json", and exit. This flag is '
              'intended for use in generating automated flutter benchmarks.',
      )
      // TODO(zanderso): Off by default with investigating whether this
      // is slower for certain use cases.
      // See: https://github.com/flutter/flutter/issues/49499
      ..addFlag('fast-start',
        help: 'Whether to quickly bootstrap applications with a minimal app. '
              'Currently this is only supported on Android devices. This option '
              'cannot be paired with "--${FlutterOptions.kUseApplicationBinary}".',
        hide: !verboseHelp,
      );
  }

  @override
  final String name = 'run';

  @override
  DeprecationBehavior get deprecationBehavior => boolArgDeprecated('ignore-deprecation') ? DeprecationBehavior.ignore : _deviceDeprecationBehavior;
  DeprecationBehavior _deviceDeprecationBehavior = DeprecationBehavior.none;

  @override
  final String description = 'Run your Flutter app on an attached device.';

  @override
  String get category => FlutterCommandCategory.project;

  List<Device>? devices;
  bool webMode = false;

  String? get userIdentifier => stringArgDeprecated(FlutterOptions.kDeviceUser);

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
    return '$command/${getNameForTargetPlatform(await devices![0].targetPlatform)}';
  }

  @override
  Future<CustomDimensions> get usageValues async {
    String deviceType, deviceOsVersion;
    bool isEmulator;
    bool anyAndroidDevices = false;
    bool anyIOSDevices = false;

    if (devices == null || devices!.isEmpty) {
      deviceType = 'none';
      deviceOsVersion = 'none';
      isEmulator = false;
    } else if (devices!.length == 1) {
      final TargetPlatform platform = await devices![0].targetPlatform;
      anyAndroidDevices = platform == TargetPlatform.android;
      anyIOSDevices = platform == TargetPlatform.ios;
      deviceType = getNameForTargetPlatform(platform);
      deviceOsVersion = await devices![0].sdkNameAndVersion;
      isEmulator = await devices![0].isLocalEmulator;
    } else {
      deviceType = 'multiple';
      deviceOsVersion = 'multiple';
      isEmulator = false;
      for (final Device device in devices!) {
        final TargetPlatform platform = await device.targetPlatform;
        anyAndroidDevices = anyAndroidDevices || (platform == TargetPlatform.android);
        anyIOSDevices = anyIOSDevices || (platform == TargetPlatform.ios);
        if (anyAndroidDevices && anyIOSDevices) {
          break;
        }
      }
    }

    String? androidEmbeddingVersion;
    final List<String> hostLanguage = <String>[];
    if (anyAndroidDevices) {
      final AndroidProject androidProject = FlutterProject.current().android;
      if (androidProject != null && androidProject.existsSync()) {
        hostLanguage.add(androidProject.isKotlin ? 'kotlin' : 'java');
        androidEmbeddingVersion = androidProject.getEmbeddingVersion().toString().split('.').last;
      }
    }
    if (anyIOSDevices) {
      final IosProject iosProject = FlutterProject.current().ios;
      if (iosProject != null && iosProject.exists) {
        final Iterable<File> swiftFiles = iosProject.hostAppRoot
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((File file) => globals.fs.path.extension(file.path) == '.swift');
        hostLanguage.add(swiftFiles.isNotEmpty ? 'swift' : 'objc');
      }
    }

    final BuildInfo buildInfo = await getBuildInfo();
    final String modeName = buildInfo.modeName;
    return CustomDimensions(
      commandRunIsEmulator: isEmulator,
      commandRunTargetName: deviceType,
      commandRunTargetOsVersion: deviceOsVersion,
      commandRunModeName: modeName,
      commandRunProjectModule: FlutterProject.current().isModule,
      commandRunProjectHostLanguage: hostLanguage.join(','),
      commandRunAndroidEmbeddingVersion: androidEmbeddingVersion,
      commandRunEnableImpeller: enableImpeller,
    );
  }

  @override
  bool get shouldRunPub {
    // If we are running with a prebuilt application, do not run pub.
    if (runningWithPrebuiltApplication) {
      return false;
    }

    return super.shouldRunPub;
  }

  bool shouldUseHotMode(BuildInfo buildInfo) {
    final bool hotArg = boolArgDeprecated('hot');
    final bool shouldUseHotMode = hotArg && !traceStartup;
    return buildInfo.isDebug && shouldUseHotMode;
  }

  bool get stayResident => boolArgDeprecated('resident');
  bool get awaitFirstFrameWhenTracing => boolArgDeprecated('await-first-frame-when-tracing');

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
    if (globals.deviceManager!.hasSpecifiedAllDevices && runningWithPrebuiltApplication) {
      throwToolExit('Using "-d all" with "--${FlutterOptions.kUseApplicationBinary}" is not supported');
    }

    if (userIdentifier != null
      && devices!.every((Device device) => device.platformType != PlatformType.android)) {
      throwToolExit(
        '--${FlutterOptions.kDeviceUser} is only supported for Android. At least one Android device is required.'
      );
    }

    if (devices!.any((Device device) => device is AndroidDevice)) {
      _deviceDeprecationBehavior = DeprecationBehavior.exit;
    }
    // Only support "web mode" with a single web device due to resident runner
    // refactoring required otherwise.
    webMode = featureFlags.isWebEnabled &&
      devices!.length == 1  &&
      await devices!.single.targetPlatform == TargetPlatform.web_javascript;
  }

  @visibleForTesting
  Future<ResidentRunner> createRunner({
    required bool hotMode,
    required List<FlutterDevice> flutterDevices,
    required String? applicationBinaryPath,
    required FlutterProject flutterProject,
  }) async {
    if (hotMode && !webMode) {
      return HotRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: await createDebuggingOptions(webMode),
        benchmarkMode: boolArgDeprecated('benchmark'),
        applicationBinary: applicationBinaryPath == null
            ? null
            : globals.fs.file(applicationBinaryPath),
        projectRootPath: stringArgDeprecated('project-root'),
        dillOutputPath: stringArgDeprecated('output-dill'),
        stayResident: stayResident,
        ipv6: ipv6 ?? false,
        multidexEnabled: boolArgDeprecated('multidex'),
      );
    } else if (webMode) {
      return webRunnerFactory!.createWebRunner(
        flutterDevices.single,
        target: targetFile,
        flutterProject: flutterProject,
        ipv6: ipv6,
        debuggingOptions: await createDebuggingOptions(webMode),
        stayResident: stayResident,
        fileSystem: globals.fs,
        usage: globals.flutterUsage,
        logger: globals.logger,
        systemClock: globals.systemClock,
      );
    }
    return ColdRunner(
      flutterDevices,
      target: targetFile,
      debuggingOptions: await createDebuggingOptions(webMode),
      traceStartup: traceStartup,
      awaitFirstFrameWhenTracing: awaitFirstFrameWhenTracing,
      applicationBinary: applicationBinaryPath == null
          ? null
          : globals.fs.file(applicationBinaryPath),
      ipv6: ipv6 ?? false,
      stayResident: stayResident,
      multidexEnabled: boolArgDeprecated('multidex'),
    );
  }

  @visibleForTesting
  Daemon createMachineDaemon() {
    final Daemon daemon = Daemon(
      DaemonConnection(
        daemonStreams: DaemonStreams.fromStdio(globals.stdio, logger: globals.logger),
        logger: globals.logger,
      ),
      notifyingLogger: (globals.logger is NotifyingLogger)
        ? globals.logger as NotifyingLogger
        : NotifyingLogger(verbose: globals.logger.isVerbose, parent: globals.logger),
      logToStdout: true,
    );
    return daemon;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Enable hot mode by default if `--no-hot` was not passed and we are in
    // debug mode.
    final BuildInfo buildInfo = await getBuildInfo();
    final bool hotMode = shouldUseHotMode(buildInfo);
    final String? applicationBinaryPath = stringArgDeprecated(FlutterOptions.kUseApplicationBinary);

    if (boolArgDeprecated('machine')) {
      if (devices!.length > 1) {
        throwToolExit('"--machine" does not support "-d all".');
      }
      final Daemon daemon = createMachineDaemon();
      late AppInstance app;
      try {
        app = await daemon.appDomain.startApp(
          devices!.first, globals.fs.currentDirectory.path, targetFile, route,
          await createDebuggingOptions(webMode), hotMode,
          applicationBinary: applicationBinaryPath == null
              ? null
              : globals.fs.file(applicationBinaryPath),
          trackWidgetCreation: trackWidgetCreation,
          projectRootPath: stringArgDeprecated('project-root'),
          packagesFilePath: globalResults!['packages'] as String?,
          dillOutputPath: stringArgDeprecated('output-dill'),
          ipv6: ipv6 ?? false,
          multidexEnabled: boolArgDeprecated('multidex'),
          userIdentifier: userIdentifier,
          enableDevTools: boolArgDeprecated(FlutterCommand.kEnableDevTools),
        );
      } on Exception catch (error) {
        throwToolExit(error.toString());
      }
      final DateTime appStartedTime = globals.systemClock.now();
      final int result = await app.runner!.waitForAppToFinish();
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
          '${sentenceCase(getFriendlyModeName(buildMode))} '
          'mode is not supported by ${device.name}.',
        );
      }
      if (hotMode) {
        if (!device.supportsHotReload) {
          throwToolExit('Hot reload is not supported by ${device.name}. Run with "--no-hot".');
        }
      }
      if (await device.isLocalEmulator && await device.supportsHardwareRendering) {
        if (boolArgDeprecated('enable-software-rendering')) {
          globals.printStatus(
            'Using software rendering with device ${device.name}. You may get better performance '
            'with hardware mode by configuring hardware rendering for your device.'
           );
        } else {
          globals.printStatus(
            'Using hardware rendering with device ${device.name}. If you notice graphics artifacts, '
            'consider enabling software rendering with "--enable-software-rendering".'
          );
        }
      }
    }

    List<String>? expFlags;
    if (argParser.options.containsKey(FlutterOptions.kEnableExperiment) &&
        stringsArg(FlutterOptions.kEnableExperiment).isNotEmpty) {
      expFlags = stringsArg(FlutterOptions.kEnableExperiment);
    }
    final FlutterProject flutterProject = FlutterProject.current();
    final List<FlutterDevice> flutterDevices = <FlutterDevice>[
      for (final Device device in devices!)
        await FlutterDevice.create(
          device,
          experimentalFlags: expFlags,
          target: targetFile,
          buildInfo: buildInfo,
          userIdentifier: userIdentifier,
          platform: globals.platform,
        ),
    ];

    final ResidentRunner runner = await createRunner(
      applicationBinaryPath: applicationBinaryPath,
      flutterDevices: flutterDevices,
      flutterProject: flutterProject,
      hotMode: hotMode,
    );

    DateTime? appStartedTime;
    // Sync completer so the completing agent attaching to the resident doesn't
    // need to know about analytics.
    //
    // Do not add more operations to the future.
    final Completer<void> appStartedTimeRecorder = Completer<void>.sync();

    TerminalHandler? handler;
    // This callback can't throw.
    unawaited(appStartedTimeRecorder.future.then<void>(
      (_) {
        appStartedTime = globals.systemClock.now();
        if (stayResident) {
          handler = TerminalHandler(
            runner,
            logger: globals.logger,
            terminal: globals.terminal,
            signals: globals.signals,
            processInfo: globals.processInfo,
            reportReady: boolArgDeprecated('report-ready'),
            pidFile: stringArgDeprecated('pid-file'),
          )
            ..registerSignalHandlers()
            ..setupTerminal();
        }
      }
    ));
    try {
      final int? result = await runner.run(
        appStartedCompleter: appStartedTimeRecorder,
        enableDevTools: stayResident && boolArgDeprecated(FlutterCommand.kEnableDevTools),
        route: route,
      );
      handler?.stop();
      if (result != 0) {
        throwToolExit(null, exitCode: result);
      }
    } on RPCError catch (error) {
      if (error.code == RPCErrorCodes.kServiceDisappeared) {
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
        getModeName(getBuildMode()),
        if (devices!.length == 1)
          getNameForTargetPlatform(await devices![0].targetPlatform)
        else
          'multiple',
        if (devices!.length == 1 && await devices![0].isLocalEmulator)
          'emulator'
        else
          null,
      ],
      endTimeOverride: appStartedTime,
    );
  }
}
