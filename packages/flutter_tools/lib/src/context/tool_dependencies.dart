// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import '../base/context.dart';
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
import '../isolated/build_targets.dart';
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

/// Bootstraps and manages tool dependencies.
class ToolDependencies {
  ToolDependencies({
    required this.analytics,
    required this.androidContext,
    required this.appleContext,
    required this.buildSystem,
    required this.buildTargets,
    required this.crashReporter,
    required this.deviceManager,
    required this.doctor,
    required this.emulatorManager,
    required this.macOSWorkflow,
    required this.toolContext,
    required this.windowsWorkflow,
  });

  final Analytics analytics;
  final AndroidContext androidContext;
  final AppleContext appleContext;
  final BuildSystem buildSystem;
  final BuildTargets buildTargets;
  final CrashReporter crashReporter;
  final DeviceManager deviceManager;
  final Doctor doctor;
  final EmulatorManager emulatorManager;
  final MacOSWorkflow macOSWorkflow;
  final ToolContext toolContext;
  final WindowsWorkflow windowsWorkflow;

  /// Bootstraps the dependency graph and constructs all three contexts.
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
    EmulatorManager? emulatorManager,
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
    OperatingSystemUtils? os,
    OutputPreferences? outputPreferences,
    PersistentToolState? persistentToolState,
    Platform? platform,
    PlistParser? plistParser,
    PreRunValidator? preRunValidator,
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
          now: DateTime.now(),
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
              shutdownHooks ?? ShutdownHooks(),
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
      analytics: () {
        if (!finalAnalyticsInitialized) {
          throw ContextDependencyCycleException(<Type>[FlutterVersion, Analytics]);
        }
        return finalAnalytics;
      },
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

    final flutterVersion = FlutterVersion(fs: finalFS, flutterRoot: flutterRoot, git: finalGit);

    // 8. Analytics
    finalAnalytics =
        analytics ??
        getAnalytics(
          runningOnBot: isBot,
          flutterVersion: flutterVersion,
          environment: finalPlatform.environment,
          clientIde: finalPlatform.environment['FLUTTER_HOST'],
          config: finalConfig,
        );
    finalAnalyticsInitialized = true;

    // 9. Project Factory and Operating System Utilities
    final FlutterProjectFactory finalProjectFactory =
        projectFactory ?? FlutterProjectFactory(logger: finalLogger, fileSystem: finalFS);

    final OperatingSystemUtils finalOS =
        os ??
        OperatingSystemUtils(
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

    final BuildTargets finalBuildTargets = buildTargets ?? const BuildTargetsImpl();

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

    final finalDoctor = Doctor(logger: finalLogger, clock: finalSystemClock);

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

    final Artifacts finalArtifacts =
        artifacts ??
        CachedArtifacts(
          fileSystem: finalFS,
          cache: finalCache,
          platform: finalPlatform,
          operatingSystemUtils: finalOS,
        );

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
            iproxyPath: finalArtifacts.getHostArtifact(HostArtifact.iproxy).path,
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

    final featureFlags = FlutterFeatureFlags(
      flutterVersion: flutterVersion,
      featuresConfig: FlutterFeaturesConfig(
        globalConfig: finalConfig,
        platform: finalPlatform,
        projectManifest: projectManifest,
      ),
      platform: finalPlatform,
    );

    final IOSWorkflow? finalIOSWorkflow =
        iosWorkflow ??
        (finalPlatform.isMacOS
            ? IOSWorkflow(featureFlags: featureFlags, xcode: finalXcode, platform: finalPlatform)
            : null);

    final IOSSimulatorUtils? finalIOSSimulatorUtils =
        iosSimulatorUtils ??
        (finalPlatform.isMacOS
            ? IOSSimulatorUtils(
                logger: finalLogger,
                processManager: finalProcessManager,
                xcode: finalXcode,
              )
            : null);

    final PlistParser finalPlistParser =
        plistParser ??
        PlistParser(fileSystem: finalFS, processManager: finalProcessManager, logger: finalLogger);

    // 12. AndroidContext Dependencies
    final AndroidStudio? finalAndroidStudio =
        androidStudio ??
        AndroidStudio.latestValid(
          platform: finalPlatform,
          fileSystem: finalFS,
          processManager: finalProcessManager,
          config: finalConfig,
        );

    final AndroidSdk? finalAndroidSdk =
        androidSdk ??
        AndroidSdk.locateAndroidSdk(
          fileSystem: finalFS,
          platform: finalPlatform,
          config: finalConfig,
        );

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
    final AndroidWorkflow finalAndroidWorkflow =
        androidWorkflow ?? AndroidWorkflow(androidSdk: finalAndroidSdk, featureFlags: featureFlags);

    final EmulatorManager finalEmulatorManager =
        emulatorManager ??
        EmulatorManager(
          java: finalJava,
          androidSdk: finalAndroidSdk,
          processManager: finalProcessManager,
          logger: finalLogger,
          fileSystem: finalFS,
          androidWorkflow: finalAndroidWorkflow,
        );

    final WindowsWorkflow finalWindowsWorkflow =
        windowsWorkflow ?? WindowsWorkflow(platform: finalPlatform, featureFlags: featureFlags);

    final MacOSWorkflow finalMacOSWorkflow =
        macOSWorkflow ?? MacOSWorkflow(platform: finalPlatform, featureFlags: featureFlags);

    final DeviceManager finalDeviceManager =
        deviceManager ??
        FlutterDeviceManager(
          logger: finalLogger,
          platform: finalPlatform,
          processManager: finalProcessManager,
          fileSystem: finalFS,
          androidSdk: finalAndroidSdk,
          featureFlags: featureFlags,
          iosSimulatorUtils: finalIOSSimulatorUtils,
          xcDevice: finalXCDevice,
          androidWorkflow: finalAndroidWorkflow,
          iosWorkflow: finalIOSWorkflow,
          flutterVersion: flutterVersion,
          artifacts: finalArtifacts,
          macOSWorkflow: finalMacOSWorkflow,
          userMessages: finalUserMessages,
          operatingSystemUtils: finalOS,
          windowsWorkflow: finalWindowsWorkflow,
          customDevicesConfig: finalCustomDevicesConfig,
          nativeAssetsBuilder: finalNativeAssetsBuilder,
        );

    return ToolDependencies(
      analytics: finalAnalytics,
      androidContext: AndroidContext(
        androidSdk: finalAndroidSdk,
        androidStudio: finalAndroidStudio,
        androidWorkflow: finalAndroidWorkflow,
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
      buildTargets: finalBuildTargets,
      crashReporter: finalCrashReporter,
      deviceManager: finalDeviceManager,
      doctor: finalDoctor,
      emulatorManager: finalEmulatorManager,
      macOSWorkflow: finalMacOSWorkflow,
      toolContext: ToolContext(
        artifacts: finalArtifacts,
        botDetector: finalBotDetector,
        cache: finalCache,
        config: finalConfig,
        customDevicesConfig: finalCustomDevicesConfig,

        flutterVersion: flutterVersion,
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
        processManager: finalProcessManager,
        processUtils: finalProcessUtils,
        projectFactory: finalProjectFactory,
        shutdownHooks: finalShutdownHooks,
        stdio: finalStdio,
        systemClock: finalSystemClock,
        terminal: finalTerminal,
        userMessages: finalUserMessages,
      ),
      windowsWorkflow: finalWindowsWorkflow,
    );
  }
}
