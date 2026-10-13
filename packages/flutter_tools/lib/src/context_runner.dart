// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'android/android_builder.dart';
import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
import 'android/gradle.dart';
import 'android/gradle_utils.dart';
import 'android/java.dart';
import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/bot_detector.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'base/signals.dart';
import 'base/terminal.dart';
import 'base/time.dart';
import 'base/user_messages.dart';
import 'build_system/build_system.dart';
import 'cache.dart';
import 'context/tool_context.dart';
import 'custom_devices/custom_devices_config.dart';
import 'dart/pub.dart';
import 'devfs.dart';
import 'devtools_launcher.dart';
import 'doctor.dart';
import 'emulator.dart';
import 'features.dart';
import 'flutter_application_package.dart';
import 'flutter_cache.dart';
import 'flutter_features.dart';
import 'flutter_features_config.dart';
import 'flutter_manifest.dart';
import 'git.dart';
import 'globals.dart' as globals;
import 'ios/ios_workflow.dart';
import 'ios/iproxy.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcdevice.dart';
import 'macos/xcode.dart';
import 'mdns_discovery.dart';
import 'native_assets.dart';
import 'persistent_tool_state.dart';
import 'pre_run_validator.dart';
import 'project.dart';
import 'reporting/crash_reporting.dart';
import 'reporting/unified_analytics.dart';
import 'resident_runner.dart';
import 'run_hot.dart';
import 'runner/local_engine.dart';
import 'version.dart';
import 'web/workflow.dart';
import 'windows/visual_studio.dart';
import 'windows/visual_studio_validator.dart';
import 'windows/windows_workflow.dart';

Future<T> runInContext<T>(FutureOr<T> Function() runner, {Map<Type, Generator>? overrides}) async {
  // Wrap runner with any asynchronous initialization that should run with the
  // overrides and callbacks.
  late bool runningOnBot;
  FutureOr<T> runnerWrapper() async {
    runningOnBot = await globals.isRunningOnBot;
    return runner();
  }

  // TODO(ianh): We should split this into two, one for tests (which should be
  // in test/), and one for production (which should be in executable.dart).
  return context.run<T>(
    name: 'global fallbacks',
    body: runnerWrapper,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      Analytics: () => getAnalytics(
        runningOnBot: runningOnBot,
        flutterVersion: globals.flutterVersion,
        environment: globals.platform.environment,
        clientIde: globals.platform.environment['FLUTTER_HOST'],
        config: globals.config,
      ),
      AndroidBuilder: () => AndroidGradleBuilder(
        java: globals.java,
        logger: globals.logger,
        processManager: globals.processManager,
        fileSystem: globals.fs,
        artifacts: globals.artifacts!,
        analytics: globals.analytics,
        gradleUtils: globals.gradleUtils!,
        platform: globals.platform,
        androidStudio: globals.androidStudio,
        androidSdk: globals.androidSdk,
      ),
      AndroidLicenseValidator: () => AndroidLicenseValidator(
        platform: globals.platform,
        userMessages: globals.userMessages,
        processManager: globals.processManager,
        java: globals.java,
        androidSdk: globals.androidSdk,
        logger: globals.logger,
        stdio: globals.stdio,
      ),
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidValidator: () => AndroidValidator(
        java: globals.java,
        androidSdk: globals.androidSdk,
        logger: globals.logger,
        platform: globals.platform,
        userMessages: globals.userMessages,
        processManager: globals.processManager,
        osUtils: globals.os,
      ),
      AndroidWorkflow: () =>
          AndroidWorkflow(androidSdk: globals.androidSdk, featureFlags: featureFlags),
      ApplicationPackageFactory: () => FlutterApplicationPackageFactory(
        userMessages: globals.userMessages,
        processManager: globals.processManager,
        logger: globals.logger,
        fileSystem: globals.fs,
        androidSdk: globals.androidSdk,
      ),
      Artifacts: () => CachedArtifacts(
        fileSystem: globals.fs,
        cache: globals.cache,
        platform: globals.platform,
        operatingSystemUtils: globals.os,
      ),
      AssetBundleFactory: () {
        return AssetBundleFactory.defaultInstance(
          logger: globals.logger,
          fileSystem: globals.fs,
          platform: globals.platform,
        );
      },
      BuildSystem: () => FlutterBuildSystem(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      Cache: () => FlutterCache(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        osUtils: globals.os,
        projectFactory: globals.projectFactory,
        stdio: globals.stdio,
      ),
      CocoaPods: () => CocoaPods(
        fileSystem: globals.fs,
        processManager: globals.processManager,
        logger: globals.logger,
        platform: globals.platform,
        xcodeProjectInterpreter: globals.xcodeProjectInterpreter!,
        analytics: globals.analytics,
      ),
      CocoaPodsValidator: () => CocoaPodsValidator(globals.cocoaPods!, globals.userMessages),
      Config: () => Config(
        Config.kFlutterSettings,
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      CustomDevicesConfig: () => CustomDevicesConfig(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      CrashReporter: () => CrashReporter(
        fileSystem: globals.fs,
        logger: globals.logger,
        flutterProjectFactory: globals.projectFactory,
      ),
      DevFSConfig: () => DevFSConfig(),
      DevtoolsLauncher: () => DevtoolsServerLauncher(
        processManager: globals.processManager,
        artifacts: globals.artifacts!,
        logger: globals.logger,
        botDetector: globals.botDetector,
      ),
      Doctor: () => Doctor(logger: globals.logger, clock: globals.systemClock),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      EmulatorManager: () => EmulatorManager(
        androidWorkflow: androidWorkflow!,
        iosWorkflow: globals.iosWorkflow,
        java: globals.java,
        toolContext: const DelegatingToolContext(),
        xcode: globals.xcode,
        androidSdk: globals.androidSdk,
      ),
      FeatureFlags: () => FlutterFeatureFlags(
        flutterVersion: globals.flutterVersion,
        featuresConfig: FlutterFeaturesConfig(
          globalConfig: globals.config,
          platform: globals.platform,
          projectManifest: FlutterManifest.createFromPath(
            globals.fs.path.join(
              findProjectRoot(globals.fs) ?? globals.fs.currentDirectory.path,
              'pubspec.yaml',
            ),
            fileSystem: globals.fs,
            logger: globals.logger,
          ),
        ),
        platform: globals.platform,
      ),
      FlutterVersion: () =>
          FlutterVersion(fs: globals.fs, flutterRoot: Cache.flutterRoot!, git: globals.git),
      Git: () => Git(currentPlatform: globals.platform, runProcessWith: globals.processUtils),
      GradleUtils: () => GradleUtils(
        operatingSystemUtils: globals.os,
        logger: globals.logger,
        platform: globals.platform,
        cache: globals.cache,
      ),
      HotRunnerConfig: () => HotRunnerConfig(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(
        analytics: globals.analytics,
        plistParser: globals.plistParser,
        toolContext: const DelegatingToolContext(),
        xcode: globals.xcode!,
      ),
      IOSWorkflow: () => IOSWorkflow(
        featureFlags: featureFlags,
        xcode: globals.xcode!,
        platform: globals.platform,
      ),
      Java: () => Java.find(
        config: globals.config,
        androidStudio: globals.androidStudio,
        logger: globals.logger,
        fileSystem: globals.fs,
        platform: globals.platform,
        processManager: globals.processManager,
      ),
      LocalEngineLocator: () => LocalEngineLocator(
        userMessages: globals.userMessages,
        logger: globals.logger,
        platform: globals.platform,
        fileSystem: globals.fs,
        flutterRoot: Cache.flutterRoot!,
      ),
      Logger: () => globals.platform.isWindows
          ? WindowsStdoutLogger(
              terminal: globals.terminal,
              stdio: globals.stdio,
              outputPreferences: globals.outputPreferences,
            )
          : StdoutLogger(
              terminal: globals.terminal,
              stdio: globals.stdio,
              outputPreferences: globals.outputPreferences,
            ),
      MacOSWorkflow: () => MacOSWorkflow(featureFlags: featureFlags, platform: globals.platform),
      MDnsVmServiceDiscovery: () =>
          MDnsVmServiceDiscovery(logger: globals.logger, analytics: globals.analytics),
      OperatingSystemUtils: () => OperatingSystemUtils(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        processManager: globals.processManager,
      ),
      OutputPreferences: () => OutputPreferences(
        wrapText: globals.stdio.hasTerminal,
        showColor: globals.platform.stdoutSupportsAnsi,
        stdio: globals.stdio,
      ),
      PersistentToolState: () => PersistentToolState(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      ProcessInfo: () => ProcessInfo(globals.fs),
      ProcessManager: () => ErrorHandlingProcessManager(
        delegate: const LocalProcessManager(),
        platform: globals.platform,
        analytics: () => globals.analytics,
      ),
      ProcessUtils: () =>
          ProcessUtils(processManager: globals.processManager, logger: globals.logger),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
      Stdio: () => Stdio(),
      SystemClock: () => const SystemClock(),
      UserMessages: () => UserMessages(),
      VisualStudioValidator: () => VisualStudioValidator(
        userMessages: globals.userMessages,
        visualStudio: VisualStudio(
          fileSystem: globals.fs,
          platform: globals.platform,
          logger: globals.logger,
          processManager: globals.processManager,
          osUtils: globals.os,
        ),
      ),
      WebWorkflow: () => WebWorkflow(featureFlags: featureFlags, platform: globals.platform),
      WindowsWorkflow: () =>
          WindowsWorkflow(featureFlags: featureFlags, platform: globals.platform),
      Xcode: () => Xcode(
        logger: globals.logger,
        processManager: globals.processManager,
        platform: globals.platform,
        fileSystem: globals.fs,
        xcodeProjectInterpreter: globals.xcodeProjectInterpreter!,
        userMessages: globals.userMessages,
      ),
      XCDevice: () => XCDevice(
        xcode: globals.xcode!,
        iproxy: IProxy(
          artifacts: globals.artifacts!,
          logger: globals.logger,
          processManager: globals.processManager,
          dyLdLibEntry: globals.cache.dyLdLibEntry,
        ),
        analytics: globals.analytics,
        templateRenderer: globals.templateRenderer,
        toolContext: const DelegatingToolContext(),
      ),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(
        logger: globals.logger,
        processManager: globals.processManager,
        platform: globals.platform,
        fileSystem: globals.fs,
        analytics: globals.analytics,
      ),
    },
  );
}

/// A [ToolContext] that dynamically delegates to [globals] for [runInContext]
/// and `testUsingContext`.
class DelegatingToolContext implements ToolContext {
  const DelegatingToolContext({
    this._artifacts,
    this._botDetector,
    this._cache,
    this._config,
    this._customDevicesConfig,
    this._flutterVersion,
    this._fs,
    this._git,
    this._localEngineLocator,
    this._logger,
    this._nativeAssetsBuilder,
    this._os,
    this._outputPreferences,
    this._persistentToolState,
    this._platform,
    this._preRunValidator,
    this._processInfo,
    this._processManager,
    this._processUtils,
    this._projectFactory,
    this._shutdownHooks,
    this._signals,
    this._stdio,
    this._systemClock,
    this._terminal,
    this._userMessages,
  });

  final Artifacts? _artifacts;
  final BotDetector? _botDetector;
  final Cache? _cache;
  final Config? _config;
  final CustomDevicesConfig? _customDevicesConfig;
  final FlutterVersion? _flutterVersion;
  final FileSystem? _fs;
  final Git? _git;
  final LocalEngineLocator? _localEngineLocator;
  final Logger? _logger;
  final TestCompilerNativeAssetsBuilder? _nativeAssetsBuilder;
  final OperatingSystemUtils? _os;
  final OutputPreferences? _outputPreferences;
  final PersistentToolState? _persistentToolState;
  final Platform? _platform;
  final PreRunValidator? _preRunValidator;
  final ProcessInfo? _processInfo;
  final ProcessManager? _processManager;
  final ProcessUtils? _processUtils;
  final FlutterProjectFactory? _projectFactory;
  final ShutdownHooks? _shutdownHooks;
  final Signals? _signals;
  final Stdio? _stdio;
  final SystemClock? _systemClock;
  final AnsiTerminal? _terminal;
  final UserMessages? _userMessages;

  @override
  Artifacts get artifacts =>
      _artifacts ??
      globals.artifacts ??
      CachedArtifacts(fileSystem: fs, platform: platform, cache: cache, operatingSystemUtils: os);

  @override
  BotDetector get botDetector => _botDetector ?? globals.botDetector;

  @override
  Cache get cache => _cache ?? globals.cache;

  @override
  Config get config => _config ?? globals.config;

  @override
  CustomDevicesConfig get customDevicesConfig =>
      _customDevicesConfig ?? globals.customDevicesConfig;

  @override
  FlutterVersion get flutterVersion => _flutterVersion ?? globals.flutterVersion;

  @override
  FileSystem get fs => _fs ?? globals.fs;

  @override
  Git get git => _git ?? globals.git;

  @override
  LocalEngineLocator get localEngineLocator =>
      _localEngineLocator ??
      globals.localEngineLocator ??
      LocalEngineLocator(
        userMessages: userMessages,
        logger: logger,
        platform: platform,
        fileSystem: fs,
        flutterRoot: Cache.flutterRoot ?? '',
      );

  @override
  Logger get logger => _logger ?? globals.logger;

  @override
  TestCompilerNativeAssetsBuilder? get nativeAssetsBuilder =>
      _nativeAssetsBuilder ?? globals.nativeAssetsBuilder;

  @override
  OperatingSystemUtils get os => _os ?? globals.os;

  @override
  OutputPreferences get outputPreferences => _outputPreferences ?? globals.outputPreferences;

  @override
  PersistentToolState get persistentToolState =>
      _persistentToolState ??
      globals.persistentToolState ??
      PersistentToolState.test(
        directory: fs.systemTempDirectory.createTempSync('persistent_tool_state'),
        logger: logger,
      );

  @override
  Platform get platform => _platform ?? globals.platform;

  @override
  PreRunValidator get preRunValidator => _preRunValidator ?? const NoOpPreRunValidator();

  @override
  ProcessInfo get processInfo => _processInfo ?? globals.processInfo;

  @override
  ProcessManager get processManager => _processManager ?? globals.processManager;

  @override
  ProcessUtils get processUtils => _processUtils ?? globals.processUtils;

  @override
  FlutterProjectFactory get projectFactory => _projectFactory ?? globals.projectFactory;

  @override
  ShutdownHooks get shutdownHooks => _shutdownHooks ?? globals.shutdownHooks;

  @override
  Signals get signals => _signals ?? globals.signals;

  @override
  Stdio get stdio => _stdio ?? globals.stdio;

  @override
  SystemClock get systemClock => _systemClock ?? globals.systemClock;

  @override
  AnsiTerminal get terminal => _terminal ?? globals.terminal;

  @override
  UserMessages get userMessages => _userMessages ?? globals.userMessages;

  @override
  FileSystemUtils get fileSystemUtils => FileSystemUtils(fileSystem: fs, platform: platform);
}
