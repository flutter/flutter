// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../../executable.dart';
library;

import 'dart:async';

import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../android/android_workflow.dart';
import '../android/gradle_utils.dart';
import '../android/java.dart';
import '../artifacts.dart';
import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../cache.dart';
import '../custom_devices/custom_devices_config.dart';
import '../device.dart';
import '../doctor.dart';
import '../emulator.dart';
import '../experimental/extension_build_manager.dart';
import '../experimental/extension_discovery.dart';
import '../experimental/extension_manager.dart';
import '../features.dart';
import '../flutter_cache.dart';
import '../flutter_device_manager.dart';
import '../flutter_features.dart';
import '../flutter_features_config.dart';
import '../flutter_manifest.dart';
import '../git.dart';
import '../ios/ios_workflow.dart';
import '../ios/iproxy.dart';
import '../ios/plist_parser.dart';
import '../ios/simulators.dart';
import '../ios/xcodeproj.dart';
import '../macos/cocoapods.dart';
import '../macos/cocoapods_validator.dart';
import '../macos/macos_workflow.dart';
import '../macos/xcdevice.dart';
import '../macos/xcode.dart';
import '../native_assets.dart';
import '../persistent_tool_state.dart';
import '../pre_run_validator.dart';
import '../project.dart';
import '../reporting/crash_reporting.dart';
import '../reporting/unified_analytics.dart';
import '../runner/local_engine.dart';
import '../version.dart';
import '../windows/windows_workflow.dart';
import 'android_context.dart';
import 'apple_context.dart';
import 'tool_context.dart';

/// The root of the Flutter tool's dependency graph.
///
/// [ToolDependencies.bootstrap] is called once per tool invocation, before any
/// command runs, and constructs the tool's long-lived services in dependency
/// order. The result holds the [ToolContext], the platform-specific
/// [AndroidContext] and [AppleContext], and services that don't belong to a
/// single context (such as [Analytics], [BuildSystem], [Doctor], and
/// [FeatureFlags]).
///
/// Like [ToolContext], it only holds instances that live for the whole tool
/// invocation; the two differ in what they expose, not in lifetime.
/// [ToolDependencies] holds [ToolContext] (not the reverse) and is only used at
/// the composition root: [generateCommands] unpacks it and passes each command
/// only the contexts and services that command needs. Passing
/// [ToolDependencies] itself into commands or services would expose the whole
/// graph to every component and turn it into a service locator.
class ToolDependencies {
  ToolDependencies({
    required this.analytics,
    required this.androidContext,
    required this.appleContext,
    required this.buildSystem,
    required this.crashReporter,
    required this.deviceManager,
    required this.doctor,
    required this.emulatorManager,
    required this.featureFlags,
    required this.toolContext,
    this.buildTargets,
    this.extensionBuildManager,
    this.extensionManager,
  });

  /// Telemetry and analytics reporter for command and feature usage.
  final Analytics analytics;

  /// Sub-context containing Android-specific platform services.
  final AndroidContext androidContext;

  /// Sub-context containing Apple platform services.
  final AppleContext appleContext;

  /// High-performance compilation and build pipeline orchestrator.
  final BuildSystem buildSystem;

  /// Factory interface for constructing compile and bundle build targets.
  final BuildTargets? buildTargets;

  /// Captures and submits unhandled tool crash reports and stack traces.
  final CrashReporter crashReporter;

  /// Manager for discovering and filtering connected target devices.
  final DeviceManager deviceManager;

  /// System health diagnostics and toolchain validator.
  final Doctor doctor;

  /// Manager for discovering, launching, and creating emulators.
  final EmulatorManager emulatorManager;

  /// Manager for querying custom build targets and executing builds via tool extensions.
  final ExtensionBuildManager? extensionBuildManager;

  /// Manager for discovering and communicating with active tool extensions.
  final ExtensionManager? extensionManager;

  /// Feature flags that govern tool capabilities and rollouts.
  final FeatureFlags featureFlags;

  /// Core container holding host environment and SDK configuration dependencies.
  final ToolContext toolContext;

  /// Bootstraps the dependency graph and constructs all three contexts.
  ///
  /// [FlutterVersion] uses [Git], which runs processes through the
  /// [ErrorHandlingProcessManager], which reads [Analytics] to propagate the
  /// analytics-suppression flag to child processes; [Analytics] in turn
  /// depends on [FlutterVersion]. To break this cycle, the process manager
  /// gets a lazy callback that returns [NoOpAnalytics] until [Analytics] has
  /// been constructed.
  static Future<ToolDependencies> bootstrap({
    Analytics? analytics,
    AndroidSdk? androidSdk,
    AndroidStudio? androidStudio,
    AndroidWorkflow? androidWorkflow,
    Artifacts? artifacts,
    BotDetector? botDetector,
    BuildSystem? buildSystem,
    BuildTargets? buildTargets,
    Cache? cache,
    CocoaPods? cocoaPods,
    CocoaPodsValidator? cocoapodsValidator,
    Config? config,
    CrashReporter? crashReporter,
    CustomDevicesConfig? customDevicesConfig,
    DeviceManager? deviceManager,
    Doctor? doctor,
    EmulatorManager? emulatorManager,
    List<ExtensionEntryPoint> extensionEntryPoints = const <ExtensionEntryPoint>[],
    FeatureFlags? featureFlags,
    FlutterVersion? flutterVersion,
    FileSystem? fs,
    Git? git,
    GradleUtils? gradleUtils,
    IOSSimulatorUtils? iosSimulatorUtils,
    IOSWorkflow? iosWorkflow,
    Java? java,
    LocalEngineLocator? localEngineLocator,
    Logger? logger,
    MacOSWorkflow? macOSWorkflow,
    TestCompilerNativeAssetsBuilder? nativeAssetsBuilder,
    OutputPreferences? outputPreferences,
    PersistentToolState? persistentToolState,
    Platform? platform,
    PlistParser? plistParser,
    PreRunValidator? preRunValidator,
    ProcessInfo? processInfo,
    ProcessManager? processManager,
    FlutterProjectFactory? projectFactory,
    ShutdownHooks? shutdownHooks,
    Stdio? stdio,
    SystemClock? systemClock,
    AnsiTerminal? terminal,
    UserMessages? userMessages,
    WindowsWorkflow? windowsWorkflow,
    XCDevice? xcdevice,
    Xcode? xcode,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
  }) async {
    // 1. Core Platform Inputs
    final Platform finalPlatform = platform ?? const LocalPlatform();
    final SystemClock finalSystemClock = systemClock ?? const SystemClock();
    final UserMessages finalUserMessages = userMessages ?? UserMessages();
    final ShutdownHooks finalShutdownHooks = shutdownHooks ?? ShutdownHooks();
    final Stdio finalStdio = stdio ?? Stdio();

    // 2. Terminal and Preferences
    final AnsiTerminal finalTerminal =
        terminal ??
        AnsiTerminal(
          stdio: finalStdio,
          platform: finalPlatform,
          now: finalSystemClock.now(),
          shutdownHooks: finalShutdownHooks,
        );

    final OutputPreferences finalOutputPreferences =
        outputPreferences ??
        OutputPreferences(
          wrapText: finalStdio.hasTerminal,
          showColor: finalPlatform.stdoutSupportsAnsi,
          stdio: finalStdio,
        );

    // 3. Logger
    final Logger finalLogger =
        logger ??
        (finalPlatform.isWindows
            ? WindowsStdoutLogger(
                terminal: finalTerminal,
                stdio: finalStdio,
                outputPreferences: finalOutputPreferences,
              )
            : StdoutLogger(
                terminal: finalTerminal,
                stdio: finalStdio,
                outputPreferences: finalOutputPreferences,
              ));

    // 4. File System
    final finalFS = fs == null
        ? ErrorHandlingFileSystem(
            delegate: LocalFileSystem(
              LocalSignals.instance,
              Signals.defaultExitSignals,
              finalShutdownHooks,
            ),
            platform: finalPlatform,
          )
        : ErrorHandlingFileSystem(delegate: fs, platform: finalPlatform);

    // 5. Bot Detector and Config
    final PersistentToolState finalPersistentToolState =
        persistentToolState ??
        PersistentToolState(fileSystem: finalFS, logger: finalLogger, platform: finalPlatform);

    final BotDetector finalBotDetector =
        botDetector ??
        BotDetector(
          httpClientFactory: () => HttpClient(),
          platform: finalPlatform,
          persistentToolState: finalPersistentToolState,
        );

    final bool isBot = await finalBotDetector.isRunningOnBot;

    final Config finalConfig =
        config ??
        Config(
          Config.kFlutterSettings,
          fileSystem: finalFS,
          logger: finalLogger,
          platform: finalPlatform,
        );

    // 6. Process Management & Git (resolving cycle via lazy analytics closure)
    var finalAnalyticsInitialized = false;
    late final Analytics finalAnalytics;

    final finalProcessManager = ErrorHandlingProcessManager(
      delegate: processManager ?? const LocalProcessManager(),
      platform: finalPlatform,
      analytics: () => finalAnalyticsInitialized ? finalAnalytics : const NoOpAnalytics(),
    );

    final finalProcessUtils = ProcessUtils(
      processManager: finalProcessManager,
      logger: finalLogger,
    );

    final Git finalGit =
        git ?? Git(currentPlatform: finalPlatform, runProcessWith: finalProcessUtils);

    // 7. Flutter Version and Cache
    final String flutterRoot =
        Cache.flutterRoot ??
        Cache.defaultFlutterRoot(
          platform: finalPlatform,
          fileSystem: finalFS,
          userMessages: finalUserMessages,
        );
    Cache.flutterRoot ??= flutterRoot;

    final FlutterVersion finalFlutterVersion =
        flutterVersion ?? FlutterVersion(fs: finalFS, flutterRoot: flutterRoot, git: finalGit);

    // 8. Analytics
    finalAnalytics =
        analytics ??
        getAnalytics(
          runningOnBot: isBot,
          flutterVersion: finalFlutterVersion,
          environment: finalPlatform.environment,
          clientIde: finalPlatform.environment['FLUTTER_HOST'],
          config: finalConfig,
        );
    finalAnalyticsInitialized = true;

    // 9. Project Factory and Operating System Utilities
    final FlutterProjectFactory finalProjectFactory =
        projectFactory ?? FlutterProjectFactory(logger: finalLogger, fileSystem: finalFS);

    final finalOS = OperatingSystemUtils(
      fileSystem: finalFS,
      logger: finalLogger,
      platform: finalPlatform,
      processManager: finalProcessManager,
    );

    final Cache finalCache =
        cache ??
        FlutterCache(
          fileSystem: finalFS,
          logger: finalLogger,
          platform: finalPlatform,
          osUtils: finalOS,
          projectFactory: finalProjectFactory,
          stdio: finalStdio,
        );

    // 10. Remaining ToolContext Dependencies
    final BuildSystem finalBuildSystem =
        buildSystem ??
        FlutterBuildSystem(fileSystem: finalFS, logger: finalLogger, platform: finalPlatform);

    final finalBuildTargets = buildTargets;

    final CrashReporter finalCrashReporter =
        crashReporter ??
        CrashReporter(
          fileSystem: finalFS,
          logger: finalLogger,
          flutterProjectFactory: finalProjectFactory,
        );

    final CustomDevicesConfig finalCustomDevicesConfig =
        customDevicesConfig ??
        CustomDevicesConfig(fileSystem: finalFS, logger: finalLogger, platform: finalPlatform);

    final PreRunValidator finalPreRunValidator =
        preRunValidator ?? PreRunValidator(fileSystem: finalFS);

    final ProcessInfo finalProcessInfo = processInfo ?? ProcessInfo(finalFS);

    final LocalEngineLocator finalLocalEngineLocator =
        localEngineLocator ??
        LocalEngineLocator(
          userMessages: finalUserMessages,
          logger: finalLogger,
          platform: finalPlatform,
          fileSystem: finalFS,
          flutterRoot: flutterRoot,
        );

    final finalNativeAssetsBuilder = nativeAssetsBuilder;

    // 11. AppleContext Dependencies
    final XcodeProjectInterpreter finalXcodeProjectInterpreter =
        xcodeProjectInterpreter ??
        XcodeProjectInterpreter(
          platform: finalPlatform,
          processManager: finalProcessManager,
          logger: finalLogger,
          fileSystem: finalFS,
          analytics: finalAnalytics,
        );

    final Xcode finalXcode =
        xcode ??
        Xcode(
          platform: finalPlatform,
          processManager: finalProcessManager,
          logger: finalLogger,
          fileSystem: finalFS,
          xcodeProjectInterpreter: finalXcodeProjectInterpreter,
          userMessages: finalUserMessages,
        );

    final CocoaPods finalCocoaPods =
        cocoaPods ??
        CocoaPods(
          fileSystem: finalFS,
          processManager: finalProcessManager,
          logger: finalLogger,
          platform: finalPlatform,
          xcodeProjectInterpreter: finalXcodeProjectInterpreter,
          analytics: finalAnalytics,
        );

    final CocoaPodsValidator finalCocoapodsValidator =
        cocoapodsValidator ?? CocoaPodsValidator(finalCocoaPods, finalUserMessages);

    // Artifacts will be updated later if a local engine is used.
    final Artifacts finalArtifacts = switch (artifacts) {
      final DeferredArtifacts deferredArtifacts => deferredArtifacts,
      final Artifacts providedArtifacts => DeferredArtifacts(providedArtifacts),
      null => DeferredArtifacts(
        CachedArtifacts(
          fileSystem: finalFS,
          cache: finalCache,
          platform: finalPlatform,
          operatingSystemUtils: finalOS,
        ),
      ),
    };

    final XCDevice finalXCDevice =
        xcdevice ??
        XCDevice(
          processManager: finalProcessManager,
          logger: finalLogger,
          artifacts: finalArtifacts,
          cache: finalCache,
          platform: finalPlatform,
          xcode: finalXcode,
          iproxy: IProxy(
            artifacts: finalArtifacts,
            logger: finalLogger,
            processManager: finalProcessManager,
            dyLdLibEntry: finalCache.dyLdLibEntry,
          ),
          fileSystem: finalFS,
          analytics: finalAnalytics,
          shutdownHooks: finalShutdownHooks,
        );

    final String projectRoot = findProjectRoot(finalFS) ?? finalFS.currentDirectory.path;
    final FlutterManifest? projectManifest = FlutterManifest.createFromPath(
      finalFS.path.join(projectRoot, 'pubspec.yaml'),
      fileSystem: finalFS,
      logger: finalLogger,
    );

    final FeatureFlags finalFeatureFlags =
        featureFlags ??
        FlutterFeatureFlags(
          flutterVersion: finalFlutterVersion,
          featuresConfig: FlutterFeaturesConfig(
            globalConfig: finalConfig,
            platform: finalPlatform,
            projectManifest: projectManifest,
          ),
          platform: finalPlatform,
        );

    final IOSWorkflow finalIOSWorkflow =
        iosWorkflow ??
        IOSWorkflow(featureFlags: finalFeatureFlags, xcode: finalXcode, platform: finalPlatform);

    final IOSSimulatorUtils finalIOSSimulatorUtils =
        iosSimulatorUtils ??
        IOSSimulatorUtils(
          logger: finalLogger,
          operatingSystemUtils: finalOS,
          processManager: finalProcessManager,
          xcode: finalXcode,
        );

    final PlistParser finalPlistParser =
        plistParser ??
        PlistParser(fileSystem: finalFS, processManager: finalProcessManager, logger: finalLogger);

    // 12. AndroidContext Dependencies
    final AndroidStudio? finalAndroidStudio = androidStudio ?? AndroidStudio.latestValid();

    final AndroidSdk? finalAndroidSdk = androidSdk ?? AndroidSdk.locateAndroidSdk();

    final Java? finalJava =
        java ??
        Java.find(
          config: finalConfig,
          androidStudio: finalAndroidStudio,
          logger: finalLogger,
          fileSystem: finalFS,
          platform: finalPlatform,
          processManager: finalProcessManager,
        );

    final GradleUtils finalGradleUtils =
        gradleUtils ??
        GradleUtils(
          platform: finalPlatform,
          logger: finalLogger,
          cache: finalCache,
          operatingSystemUtils: finalOS,
        );

    // 13. Doctor, EmulatorManager, and DeviceManager Dependencies
    final Doctor finalDoctor =
        doctor ?? Doctor(clock: finalSystemClock, logger: finalLogger, analytics: finalAnalytics);

    final AndroidWorkflow finalAndroidWorkflow =
        androidWorkflow ??
        AndroidWorkflow(androidSdk: finalAndroidSdk, featureFlags: finalFeatureFlags);

    final EmulatorManager finalEmulatorManager =
        emulatorManager ??
        EmulatorManager(
          androidWorkflow: finalAndroidWorkflow,
          fileSystem: finalFS,
          java: finalJava,
          logger: finalLogger,
          processManager: finalProcessManager,
          androidSdk: finalAndroidSdk,
        );

    final MacOSWorkflow finalMacOSWorkflow =
        macOSWorkflow ?? MacOSWorkflow(featureFlags: finalFeatureFlags, platform: finalPlatform);

    final WindowsWorkflow finalWindowsWorkflow =
        windowsWorkflow ??
        WindowsWorkflow(featureFlags: finalFeatureFlags, platform: finalPlatform);

    final extensionManager = ExtensionManager(
      entryPoints: extensionEntryPoints,
      featureFlags: finalFeatureFlags,
      hostPlatform: finalOS.hostPlatform,
      logger: finalLogger,
    );

    final extensionBuildManager = ExtensionBuildManager(
      extensionManager: extensionManager,
      featureFlags: finalFeatureFlags,
      logger: finalLogger,
    );

    final DeviceManager finalDeviceManager =
        deviceManager ??
        FlutterDeviceManager(
          logger: finalLogger,
          platform: finalPlatform,
          processManager: finalProcessManager,
          fileSystem: finalFS,
          androidSdk: finalAndroidSdk,
          featureFlags: finalFeatureFlags,
          iosSimulatorUtils: finalIOSSimulatorUtils,
          xcDevice: finalXCDevice,
          androidWorkflow: finalAndroidWorkflow,
          iosWorkflow: finalIOSWorkflow,
          flutterVersion: finalFlutterVersion,
          artifacts: finalArtifacts,
          macOSWorkflow: finalMacOSWorkflow,
          userMessages: finalUserMessages,
          operatingSystemUtils: finalOS,
          windowsWorkflow: finalWindowsWorkflow,
          customDevicesConfig: finalCustomDevicesConfig,
          nativeAssetsBuilder: finalNativeAssetsBuilder,
          extensionManager: extensionManager,
        );

    return ToolDependencies(
      analytics: finalAnalytics,
      androidContext: AndroidContext(
        androidSdk: finalAndroidSdk,
        androidStudio: finalAndroidStudio,
        gradleUtils: finalGradleUtils,
        java: finalJava,
      ),
      appleContext: AppleContext(
        cocoaPods: finalCocoaPods,
        cocoapodsValidator: finalCocoapodsValidator,
        iosSimulatorUtils: finalIOSSimulatorUtils,
        iosWorkflow: finalIOSWorkflow,
        plistParser: finalPlistParser,
        xcdevice: finalXCDevice,
        xcode: finalXcode,
        xcodeProjectInterpreter: finalXcodeProjectInterpreter,
      ),
      buildSystem: finalBuildSystem,
      crashReporter: finalCrashReporter,
      deviceManager: finalDeviceManager,
      doctor: finalDoctor,
      emulatorManager: finalEmulatorManager,
      extensionBuildManager: extensionBuildManager,
      extensionManager: extensionManager,
      featureFlags: finalFeatureFlags,
      toolContext: ToolContext(
        artifacts: finalArtifacts,
        botDetector: finalBotDetector,
        cache: finalCache,
        config: finalConfig,
        customDevicesConfig: finalCustomDevicesConfig,
        flutterVersion: finalFlutterVersion,
        fs: finalFS,
        git: finalGit,
        localEngineLocator: finalLocalEngineLocator,
        logger: finalLogger,
        nativeAssetsBuilder: finalNativeAssetsBuilder,
        os: finalOS,
        outputPreferences: finalOutputPreferences,
        persistentToolState: finalPersistentToolState,
        platform: finalPlatform,
        preRunValidator: finalPreRunValidator,
        processInfo: finalProcessInfo,
        processManager: finalProcessManager,
        processUtils: finalProcessUtils,
        projectFactory: finalProjectFactory,
        shutdownHooks: finalShutdownHooks,
        signals: LocalSignals.instance,
        stdio: finalStdio,
        systemClock: finalSystemClock,
        terminal: finalTerminal,
        userMessages: finalUserMessages,
      ),
      buildTargets: finalBuildTargets,
    );
  }
}
