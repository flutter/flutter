// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/flutter_cache.dart';
import 'package:flutter_tools/src/flutter_features.dart';
import 'package:flutter_tools/src/flutter_features_config.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/native_assets.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/reporting/unified_analytics.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

const Platform _kLocalPlatform = LocalPlatform();
const ProcessManager _kLocalProcessManager = LocalProcessManager();
const SystemClock _defaultSystemClock = SystemClock();

final _defaultBotDetector = BotDetector(platform: _platform);

final _defaultOutputPreferences = OutputPreferences(
  wrapText: _stdio.hasTerminal,
  showColor: _platform.stdoutSupportsAnsi,
  stdio: _stdio,
);

final _defaultAnsiTerminal = AnsiTerminal(
  stdio: _stdio,
  platform: _platform,
  now: DateTime.now(),
  shutdownHooks: _shutdownHooks,
);

Stdio? _stdioInstance;
PlistParser? _plistInstance;
LocalFileSystem? _localFileSystemInstance;

Analytics get _analytics => context.get<Analytics>()!;
AndroidSdk? get _androidSdk => context.get<AndroidSdk>();
AndroidStudio? get _androidStudio => context.get<AndroidStudio>();
Artifacts? get _artifacts => context.get<Artifacts>();
BotDetector get _botDetector => context.get<BotDetector>() ?? _defaultBotDetector;
Cache get _cache => context.get<Cache>()!;
CocoaPods? get _cocoaPods => context.get<CocoaPods>();
CocoaPodsValidator? get _cocoapodsValidator => context.get<CocoaPodsValidator>();
Config get _config => context.get<Config>()!;
CustomDevicesConfig get _customDevicesConfig => context.get<CustomDevicesConfig>()!;
DeviceManager? get _deviceManager => context.get<DeviceManager>();
FlutterVersion get _flutterVersion => context.get<FlutterVersion>()!;
FileSystem get _fs => ErrorHandlingFileSystem(
  delegate: context.get<FileSystem>() ?? _localFileSystem,
  platform: _platform,
);
Git get _git => context.get<Git>()!;
GradleUtils? get _gradleUtils => context.get<GradleUtils>();
HttpClientFactory? get _httpClientFactory => context.get<HttpClientFactory>();
IOSSimulatorUtils? get _iosSimulatorUtils => context.get<IOSSimulatorUtils>();
IOSWorkflow? get _iosWorkflow => context.get<IOSWorkflow>();
Java? get _java => context.get<Java>();
LocalEngineLocator? get _localEngineLocator => context.get<LocalEngineLocator>();
LocalFileSystem get _localFileSystem => _localFileSystemInstance ??= LocalFileSystem(
  LocalSignals.instance,
  Signals.defaultExitSignals,
  _shutdownHooks,
);
Logger get _logger => context.get<Logger>()!;
TestCompilerNativeAssetsBuilder? get _nativeAssetsBuilder =>
    context.get<TestCompilerNativeAssetsBuilder>();
OperatingSystemUtils get _os => context.get<OperatingSystemUtils>()!;
OutputPreferences get _outputPreferences =>
    context.get<OutputPreferences>() ?? _defaultOutputPreferences;
PersistentToolState? get _persistentToolState => context.get<PersistentToolState>();
Platform get _platform => context.get<Platform>() ?? _kLocalPlatform;
PlistParser get _plistParser =>
    context.get<PlistParser>() ??
    (_plistInstance ??= PlistParser(
      fileSystem: _fs,
      processManager: _processManager,
      logger: _logger,
    ));
PreRunValidator get _preRunValidator =>
    context.get<PreRunValidator>() ?? const NoOpPreRunValidator();
ProcessInfo get _processInfo => context.get<ProcessInfo>()!;
ProcessManager get _processManager => context.get<ProcessManager>() ?? _kLocalProcessManager;
ProcessUtils get _processUtils => context.get<ProcessUtils>()!;
FlutterProjectFactory get _projectFactory =>
    context.get<FlutterProjectFactory>() ??
    FlutterProjectFactory(
      config: _config,
      featureFlagsBuilder: () => featureFlags,
      fileSystem: _fs,
      logger: _logger,
      plistParser: _plistParser,
      // Lazy builders avoid an AppContext dependency cycle during early startup
      // (e.g. Analytics -> Cache -> Xcode -> XcodeProjectInterpreter).
      xcodeBuilder: () => _xcode,
      xcodeProjectInterpreterBuilder: () => _xcodeProjectInterpreter,
    );
ShutdownHooks get _shutdownHooks => LocalSignals.instance.shutdownHooks;
Signals get _signals => context.get<Signals>() ?? LocalSignals.instance;
Stdio get _stdio => context.get<Stdio>() ?? (_stdioInstance ??= Stdio());
SystemClock get _systemClock => context.get<SystemClock>() ?? _defaultSystemClock;
TemplateRenderer get _templateRenderer => context.get<TemplateRenderer>()!;
AnsiTerminal get _terminal => context.get<AnsiTerminal>() ?? _defaultAnsiTerminal;
UserMessages get _userMessages => context.get<UserMessages>()!;
XCDevice? get _xcdevice => context.get<XCDevice>();
Xcode? get _xcode => context.get<Xcode>();
XcodeProjectInterpreter? get _xcodeProjectInterpreter => context.get<XcodeProjectInterpreter>();

/// Disposes any fallback host [LocalFileSystem] lazily initialized by [runInContext].
Future<void> disposeContextRunnerLocalFileSystem() async {
  await _localFileSystemInstance?.dispose();
}

/// A [ToolContext] that delegates to [AppContext] for legacy test callers.
class _ContextToolContext implements ToolContext {
  const _ContextToolContext();

  @override
  Artifacts get artifacts => _artifacts!;

  @override
  BotDetector get botDetector => _botDetector;

  @override
  Cache get cache => _cache;

  @override
  Config get config => _config;

  @override
  CustomDevicesConfig get customDevicesConfig => _customDevicesConfig;

  @override
  FileSystemUtils get fileSystemUtils => FileSystemUtils(fileSystem: fs, platform: platform);

  @override
  FlutterVersion get flutterVersion => _flutterVersion;

  @override
  FileSystem get fs => _fs;

  @override
  Git get git => _git;

  @override
  LocalEngineLocator get localEngineLocator => _localEngineLocator!;

  @override
  Logger get logger => _logger;

  @override
  TestCompilerNativeAssetsBuilder? get nativeAssetsBuilder => _nativeAssetsBuilder;

  @override
  OperatingSystemUtils get os => _os;

  @override
  OutputPreferences get outputPreferences => _outputPreferences;

  @override
  PersistentToolState get persistentToolState => _persistentToolState!;

  @override
  Platform get platform => _platform;

  @override
  PreRunValidator get preRunValidator => _preRunValidator;

  @override
  ProcessInfo get processInfo => _processInfo;

  @override
  ProcessManager get processManager => _processManager;

  @override
  ProcessUtils get processUtils => _processUtils;

  @override
  FlutterProjectFactory get projectFactory => _projectFactory;

  @override
  ShutdownHooks get shutdownHooks => _shutdownHooks;

  @override
  Signals get signals => _signals;

  @override
  Stdio get stdio => _stdio;

  @override
  SystemClock get systemClock => _systemClock;

  @override
  AnsiTerminal get terminal => _terminal;

  @override
  UserMessages get userMessages => _userMessages;
}

Future<T> runInContext<T>(FutureOr<T> Function() runner, {Map<Type, Generator>? overrides}) async {
  // Wrap runner with any asynchronous initialization that should run with the
  // overrides and callbacks.
  late bool runningOnBot;
  FutureOr<T> runnerWrapper() async {
    runningOnBot = await _botDetector.isRunningOnBot;
    return runner();
  }

  return context.run<T>(
    name: 'global fallbacks',
    body: runnerWrapper,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      Analytics: () => getAnalytics(
        runningOnBot: runningOnBot,
        flutterVersion: _flutterVersion,
        environment: _platform.environment,
        clientIde: _platform.environment['FLUTTER_HOST'],
        config: _config,
      ),
      AndroidBuilder: () => AndroidGradleBuilder(
        analytics: _analytics,
        androidSdk: _androidSdk,
        androidStudio: _androidStudio,
        gradleUtils: _gradleUtils!,
        java: _java,
        toolContext: const _ContextToolContext(),
      ),
      AndroidSdk: () => AndroidSdk.locateAndroidSdk(toolContext: const _ContextToolContext()),
      AndroidStudio: () => AndroidStudio.latestValid(
        plistParser: _plistParser,
        toolContext: const _ContextToolContext(),
      ),
      AndroidValidator: () => AndroidValidator(
        java: _java,
        androidSdk: _androidSdk,
        logger: _logger,
        platform: _platform,
        userMessages: _userMessages,
        processManager: _processManager,
        osUtils: _os,
      ),
      AndroidWorkflow: () =>
          AndroidWorkflow(androidSdkBuilder: () => _androidSdk, featureFlags: featureFlags),
      ApplicationPackageFactory: () => FlutterApplicationPackageFactory(
        androidSdk: _androidSdk,
        plistParser: _plistParser,
        toolContext: const _ContextToolContext(),
      ),
      Artifacts: () => CachedArtifacts(
        fileSystem: _fs,
        cache: _cache,
        platform: _platform,
        operatingSystemUtils: _os,
      ),
      AssetBundleFactory: () {
        return AssetBundleFactory.defaultInstance(
          logger: _logger,
          fileSystem: _fs,
          flutterRoot: _cache.flutterRoot,
          platform: _platform,
        );
      },
      BuildSystem: () => FlutterBuildSystem(fileSystem: _fs, logger: _logger, platform: _platform),
      Cache: () => FlutterCache(
        fileSystem: _fs,
        logger: _logger,
        platform: _platform,
        osUtils: _os,
        projectFactory: _projectFactory,
        stdio: _stdio,
      ),
      CocoaPods: () => CocoaPods(
        analytics: _analytics,
        toolContext: const _ContextToolContext(),
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      CocoaPodsValidator: () => CocoaPodsValidator(_cocoaPods!, _userMessages),
      Config: () =>
          Config(Config.kFlutterSettings, fileSystem: _fs, logger: _logger, platform: _platform),
      CustomDevicesConfig: () =>
          CustomDevicesConfig(cache: _cache, fileSystem: _fs, logger: _logger, platform: _platform),
      CrashReporter: () =>
          CrashReporter(fileSystem: _fs, logger: _logger, flutterProjectFactory: _projectFactory),
      DevFSConfig: () => DevFSConfig(),
      DevtoolsLauncher: () => DevtoolsServerLauncher(
        processManager: _processManager,
        artifacts: _artifacts!,
        logger: _logger,
        botDetector: _botDetector,
      ),
      Doctor: () => Doctor(
        analytics: _analytics,
        cache: _cache,
        clock: _systemClock,
        logger: _logger,
        validatorsProviderBuilder: _createDoctorValidatorsProvider,
      ),
      DoctorValidatorsProvider: _createDoctorValidatorsProvider,
      EmulatorManager: () => EmulatorManager(
        androidWorkflow: androidWorkflow!,
        iosWorkflow: _iosWorkflow,
        javaBuilder: () => _java,
        toolContext: const _ContextToolContext(),
        xcode: _xcode,
        androidSdkBuilder: () => _androidSdk,
      ),
      FeatureFlags: () => FlutterFeatureFlags(
        flutterVersion: _flutterVersion,
        featuresConfig: FlutterFeaturesConfig(
          globalConfig: _config,
          platform: _platform,
          projectManifest: FlutterManifest.createFromPath(
            _fs.path.join(findProjectRoot(_fs) ?? _fs.currentDirectory.path, 'pubspec.yaml'),
            fileSystem: _fs,
            logger: _logger,
          ),
        ),
        platform: _platform,
      ),
      FlutterVersion: () => FlutterVersion(
        cache: _cache,
        fs: _fs,
        flutterRoot: _cache.flutterRoot,
        git: _git,
        logger: _logger,
        platform: _platform,
      ),
      Git: () => Git(currentPlatform: _platform, runProcessWith: _processUtils),
      GradleUtils: () => GradleUtils(
        operatingSystemUtils: _os,
        logger: _logger,
        platform: _platform,
        cache: _cache,
      ),
      HotRunnerConfig: () => HotRunnerConfig(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(
        analytics: _analytics,
        cocoaPods: _cocoaPods!,
        plistParser: _plistParser,
        templateRenderer: _templateRenderer,
        toolContext: const _ContextToolContext(),
        xcode: _xcode!,
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      IOSWorkflow: () =>
          IOSWorkflow(featureFlags: featureFlags, xcode: _xcode!, platform: _platform),
      Java: () => Java.find(
        androidStudioBuilder: () => _androidStudio,
        config: _config,
        fileSystem: _fs,
        logger: _logger,
        platform: _platform,
        processManager: _processManager,
      ),
      LocalEngineLocator: () => LocalEngineLocator(
        userMessages: _userMessages,
        logger: _logger,
        platform: _platform,
        fileSystem: _fs,
        flutterRoot: _cache.flutterRoot,
      ),
      Logger: () => _platform.isWindows
          ? WindowsStdoutLogger(
              terminal: _terminal,
              stdio: _stdio,
              outputPreferences: _outputPreferences,
            )
          : StdoutLogger(terminal: _terminal, stdio: _stdio, outputPreferences: _outputPreferences),
      MacOSWorkflow: () => MacOSWorkflow(featureFlags: featureFlags, platform: _platform),
      MDnsVmServiceDiscovery: () =>
          MDnsVmServiceDiscovery(logger: _logger, analytics: _analytics, platform: _platform),
      OperatingSystemUtils: () => OperatingSystemUtils(
        fileSystem: _fs,
        logger: _logger,
        platform: _platform,
        processManager: _processManager,
      ),
      OutputPreferences: () => OutputPreferences(
        wrapText: _stdio.hasTerminal,
        showColor: _platform.stdoutSupportsAnsi,
        stdio: _stdio,
      ),
      PersistentToolState: () =>
          PersistentToolState(fileSystem: _fs, logger: _logger, platform: _platform),
      ProcessInfo: () => ProcessInfo(_fs),
      ProcessManager: () => ErrorHandlingProcessManager(
        delegate: const LocalProcessManager(),
        platform: _platform,
        analytics: () => _analytics,
      ),
      ProcessUtils: () => ProcessUtils(processManager: _processManager, logger: _logger),
      Pub: () => Pub(toolContext: const _ContextToolContext()),
      Stdio: () => Stdio(),
      SystemClock: () => const SystemClock(),
      TemplatePathProvider: () => TemplatePathProvider(flutterRoot: _cache.flutterRoot),
      UserMessages: () => UserMessages(),
      WebWorkflow: () => WebWorkflow(featureFlags: featureFlags, platform: _platform),
      WindowsWorkflow: () => WindowsWorkflow(featureFlags: featureFlags, platform: _platform),
      Xcode: () => Xcode(
        toolContext: const _ContextToolContext(),
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      XCDevice: () => XCDevice(
        analytics: _analytics,
        cocoaPods: _cocoaPods!,
        iproxy: IProxy(
          artifacts: _artifacts!,
          logger: _logger,
          processManager: _processManager,
          dyLdLibEntry: _cache.dyLdLibEntry,
        ),
        plistParser: _plistParser,
        templateRenderer: _templateRenderer,
        toolContext: const _ContextToolContext(),
        xcode: _xcode!,
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      XcodeProjectInterpreter: () =>
          XcodeProjectInterpreter(analytics: _analytics, toolContext: const _ContextToolContext()),
    },
  );
}

DoctorValidatorsProvider _createDoctorValidatorsProvider({ExtensionManager? extensionManager}) {
  return DoctorValidatorsProvider.create(
    androidContext: AndroidContext(
      androidSdkBuilder: () => _androidSdk,
      androidStudioBuilder: () => _androidStudio,
      gradleUtilsBuilder: () => _gradleUtils!,
      javaBuilder: () => _java,
    ),
    appleContext: AppleContext(
      cocoaPodsBuilder: () => _cocoaPods!,
      cocoapodsValidatorBuilder: () => _cocoapodsValidator!,
      iosSimulatorUtilsBuilder: () => _iosSimulatorUtils!,
      iosWorkflowBuilder: () => _iosWorkflow!,
      plistParserBuilder: () => _plistParser,
      xcdeviceBuilder: () => _xcdevice!,
      xcodeBuilder: () => _xcode!,
      xcodeProjectInterpreterBuilder: () => _xcodeProjectInterpreter!,
    ),
    deviceManager: _deviceManager,
    extensionManager: extensionManager,
    featureFlags: featureFlags,
    httpClientFactory: _httpClientFactory,
    toolContext: const _ContextToolContext(),
  );
}
