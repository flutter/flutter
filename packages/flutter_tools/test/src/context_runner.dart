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
import 'package:flutter_tools/src/artifacts.dart';
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
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
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
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/crash_reporting.dart';
import 'package:flutter_tools/src/reporting/unified_analytics.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/workflow.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'fakes.dart';

const _toolContext = DelegatingToolContext();

Analytics get _analytics => context.get<Analytics>()!;
AndroidSdk? get _androidSdk => context.get<AndroidSdk>();
AndroidStudio? get _androidStudio => context.get<AndroidStudio>();
AndroidWorkflow? get _androidWorkflow => context.get<AndroidWorkflow>();
Artifacts? get _artifacts => context.get<Artifacts>();
Cache get _cache => _toolContext.cache;
CocoaPods? get _cocoaPods => context.get<CocoaPods>();
CocoaPodsValidator? get _cocoapodsValidator => context.get<CocoaPodsValidator>();
Config get _config => _toolContext.config;
DeviceManager? get _deviceManager => context.get<DeviceManager>();
FeatureFlags get _featureFlags => context.get<FeatureFlags>()!;
FlutterVersion get _flutterVersion => _toolContext.flutterVersion;
FileSystem get _fs => _toolContext.fs;
Git get _git => _toolContext.git;
GradleUtils? get _gradleUtils => context.get<GradleUtils>();
HttpClientFactory? get _httpClientFactory => context.get<HttpClientFactory>();
IOSSimulatorUtils? get _iosSimulatorUtils => context.get<IOSSimulatorUtils>();
IOSWorkflow? get _iosWorkflow => context.get<IOSWorkflow>();
Java? get _java => context.get<Java>();
Logger get _logger => _toolContext.logger;
OperatingSystemUtils get _os => _toolContext.os;
OutputPreferences get _outputPreferences => _toolContext.outputPreferences;
Platform get _platform => _toolContext.platform;
ProcessManager get _processManager => _toolContext.processManager;
ProcessUtils get _processUtils => _toolContext.processUtils;
FlutterProjectFactory get _projectFactory => _toolContext.projectFactory;
Stdio get _stdio => _toolContext.stdio;
SystemClock get _systemClock => _toolContext.systemClock;
TemplateRenderer get _templateRenderer => context.get<TemplateRenderer>()!;
AnsiTerminal get _terminal => _toolContext.terminal;
UserMessages get _userMessages => _toolContext.userMessages;
WindowsWorkflow? get _windowsWorkflow => context.get<WindowsWorkflow>();
XCDevice? get _xcdevice => context.get<XCDevice>();
Xcode? get _xcode => context.get<Xcode>();
XcodeProjectInterpreter? get _xcodeProjectInterpreter => context.get<XcodeProjectInterpreter>();

PlistParser _resolvePlistParser() =>
    context.get<PlistParser>() ??
    PlistParser(fileSystem: _fs, processManager: _processManager, logger: _logger);

Future<T> runInContext<T>(FutureOr<T> Function() runner, {Map<Type, Generator>? overrides}) {
  return context.run<T>(
    name: 'global fallbacks',
    body: runner,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      Analytics: () => getAnalytics(
        runningOnBot: _toolContext.botDetector.isRunningOnBot,
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
        toolContext: _toolContext,
      ),
      AndroidLicenseValidator: () => AndroidLicenseValidator(
        platform: _platform,
        userMessages: _userMessages,
        processManager: _processManager,
        java: _java,
        androidSdk: _androidSdk,
        logger: _logger,
        stdio: _stdio,
      ),
      AndroidSdk: () => AndroidSdk.locateAndroidSdk(toolContext: _toolContext),
      AndroidStudio: () =>
          AndroidStudio.latestValid(plistParser: _resolvePlistParser(), toolContext: _toolContext),
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
          AndroidWorkflow(androidSdkBuilder: () => _androidSdk, featureFlags: _featureFlags),
      Artifacts: () => CachedArtifacts(
        fileSystem: _fs,
        cache: _cache,
        platform: _platform,
        operatingSystemUtils: _os,
      ),
      BuildSystem: () => FlutterBuildSystem(fileSystem: _fs, logger: _logger, platform: _platform),
      Cache: () => FlutterCache(
        fileSystem: _fs,
        isLocalEngineBuilder: () => _artifacts?.localEngineInfo != null,
        logger: _logger,
        platform: _platform,
        osUtils: _os,
        projectFactory: _projectFactory,
        pub: () => Pub(featureFlags: _featureFlags, toolContext: _toolContext),
        stdio: _stdio,
      ),
      CocoaPods: () => CocoaPods(
        analytics: _analytics,
        toolContext: _toolContext,
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
      Doctor: () => Doctor(
        analytics: _analytics,
        cache: _cache,
        clock: _systemClock,
        logger: _logger,
        validatorsProviderBuilder: _createDoctorValidatorsProvider,
      ),
      DoctorValidatorsProvider: _createDoctorValidatorsProvider,
      EmulatorManager: () => EmulatorManager(
        androidWorkflow: _androidWorkflow!,
        iosWorkflow: _iosWorkflow,
        javaBuilder: () => _java,
        toolContext: _toolContext,
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
        isOmitLegacyVersionFileEnabled: () => _featureFlags.isOmitLegacyVersionFileEnabled,
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
        featureFlags: _featureFlags,
        analytics: _analytics,
        cocoaPods: _cocoaPods!,
        plistParser: _resolvePlistParser(),
        templateRenderer: _templateRenderer,
        toolContext: _toolContext,
        xcode: _xcode!,
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      IOSWorkflow: () =>
          IOSWorkflow(featureFlags: _featureFlags, xcode: _xcode!, platform: _platform),
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
      MacOSWorkflow: () => MacOSWorkflow(featureFlags: _featureFlags, platform: _platform),
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
      Stdio: () => Stdio(),
      SystemClock: () => const SystemClock(),
      UserMessages: () => UserMessages(),
      VisualStudioValidator: () => VisualStudioValidator(
        userMessages: _userMessages,
        visualStudio: VisualStudio(toolContext: _toolContext),
      ),
      WebWorkflow: () => WebWorkflow(featureFlags: _featureFlags, platform: _platform),
      WindowsWorkflow: () => WindowsWorkflow(featureFlags: _featureFlags, platform: _platform),
      Xcode: () =>
          Xcode(toolContext: _toolContext, xcodeProjectInterpreter: _xcodeProjectInterpreter!),
      XCDevice: () => XCDevice(
        featureFlags: _featureFlags,
        analytics: _analytics,
        cocoaPods: _cocoaPods!,
        iproxy: IProxy(
          artifacts: _artifacts!,
          logger: _logger,
          processManager: _processManager,
          dyLdLibEntry: _cache.dyLdLibEntry,
        ),
        mdnsVmServiceDiscovery: MDnsVmServiceDiscovery(
          analytics: _analytics,
          logger: _logger,
          platform: _platform,
        ),
        plistParser: _resolvePlistParser(),
        templatePathProvider: TemplatePathProvider(flutterRoot: _cache.flutterRoot),
        templateRenderer: _templateRenderer,
        toolContext: _toolContext,
        xcode: _xcode!,
        xcodeProjectInterpreter: _xcodeProjectInterpreter!,
      ),
      XcodeProjectInterpreter: () =>
          XcodeProjectInterpreter(analytics: _analytics, toolContext: _toolContext),
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
    androidWorkflow: _androidWorkflow!,
    appleContext: AppleContext(
      cocoaPodsBuilder: () => _cocoaPods!,
      cocoapodsValidatorBuilder: () => _cocoapodsValidator!,
      iosSimulatorUtilsBuilder: () => _iosSimulatorUtils!,
      iosWorkflowBuilder: () => _iosWorkflow!,
      plistParserBuilder: _resolvePlistParser,
      xcdeviceBuilder: () => _xcdevice!,
      xcodeBuilder: () => _xcode!,
      xcodeProjectInterpreterBuilder: () => _xcodeProjectInterpreter!,
    ),
    deviceManager: _deviceManager,
    extensionManager: extensionManager,
    featureFlags: _featureFlags,
    httpClientFactory: _httpClientFactory,
    toolContext: _toolContext,
    windowsWorkflow: _windowsWorkflow!,
  );
}
