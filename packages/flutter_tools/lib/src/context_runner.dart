// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
import 'android/gradle_utils.dart';
import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/process.dart';
import 'base/signals.dart';
import 'base/time.dart';
import 'base/user_messages.dart';
import 'build_system/build_system.dart';
import 'cache.dart';
import 'compile.dart';
import 'dart/pub.dart';
import 'devfs.dart';
import 'device.dart';
import 'doctor.dart';
import 'emulator.dart';
import 'features.dart';
import 'fuchsia/fuchsia_device.dart' show FuchsiaDeviceTools;
import 'fuchsia/fuchsia_sdk.dart' show FuchsiaSdk, FuchsiaArtifacts;
import 'fuchsia/fuchsia_workflow.dart' show FuchsiaWorkflow;
import 'globals.dart' as globals;
import 'ios/ios_workflow.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcode.dart';
import 'mdns_discovery.dart';
import 'persistent_tool_state.dart';
import 'reporting/reporting.dart';
import 'run_hot.dart';
import 'version.dart';
import 'web/workflow.dart';
import 'windows/visual_studio.dart';
import 'windows/visual_studio_validator.dart';
import 'windows/windows_workflow.dart';

Future<T> runInContext<T>(
  FutureOr<T> runner(), {
  Map<Type, Generator> overrides,
}) async {

  // Wrap runner with any asynchronous initialization that should run with the
  // overrides and callbacks.
  bool runningOnBot;
  FutureOr<T> runnerWrapper() async {
    runningOnBot = await globals.isRunningOnBot;
    return runner();
  }

  return await context.run<T>(
    name: 'global fallbacks',
    body: runnerWrapper,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      AndroidLicenseValidator: () => AndroidLicenseValidator(),
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidValidator: () => AndroidValidator(
        androidStudio: globals.androidStudio,
        androidSdk: globals.androidSdk,
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        processManager: globals.processManager,
        userMessages: globals.userMessages,
      ),
      AndroidWorkflow: () => AndroidWorkflow(),
      ApplicationPackageFactory: () => ApplicationPackageFactory(),
      Artifacts: () => CachedArtifacts(
        fileSystem: globals.fs,
        cache: globals.cache,
        platform: globals.platform,
      ),
      AssetBundleFactory: () => AssetBundleFactory.defaultInstance,
      BuildSystem: () => FlutterBuildSystem(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      Cache: () => Cache(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      CocoaPods: () => CocoaPods(
        fileSystem: globals.fs,
        processManager: globals.processManager,
        logger: globals.logger,
        platform: globals.platform,
        xcodeProjectInterpreter: globals.xcodeProjectInterpreter,
        timeoutConfiguration: timeoutConfiguration,
      ),
      CocoaPodsValidator: () => CocoaPodsValidator(
        globals.cocoaPods,
        globals.userMessages,
      ),
      Config: () => Config(
        Config.kFlutterSettings,
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      CrashReporter: () => CrashReporter(
        fileSystem: globals.fs,
        logger: globals.logger,
        flutterProjectFactory: globals.projectFactory,
        client: globals.httpClientFactory?.call() ?? HttpClient(),
      ),
      DevFSConfig: () => DevFSConfig(),
      DeviceManager: () => DeviceManager(),
      Doctor: () => Doctor(logger: globals.logger),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      EmulatorManager: () => EmulatorManager(),
      FeatureFlags: () => const FeatureFlags(),
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      FuchsiaArtifacts: () => FuchsiaArtifacts.find(),
      FuchsiaDeviceTools: () => FuchsiaDeviceTools(),
      FuchsiaSdk: () => FuchsiaSdk(),
      FuchsiaWorkflow: () => FuchsiaWorkflow(),
      GradleUtils: () => GradleUtils(),
      HotRunnerConfig: () => HotRunnerConfig(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(
        logger: globals.logger,
        processManager: globals.processManager,
        xcode: globals.xcode,
      ),
      IOSWorkflow: () => const IOSWorkflow(),
      KernelCompilerFactory: () => const KernelCompilerFactory(),
      Logger: () => globals.platform.isWindows
        ? WindowsStdoutLogger(
            terminal: globals.terminal,
            stdio: globals.stdio,
            outputPreferences: globals.outputPreferences,
            timeoutConfiguration: timeoutConfiguration,
          )
        : StdoutLogger(
            terminal: globals.terminal,
            stdio: globals.stdio,
            outputPreferences: globals.outputPreferences,
            timeoutConfiguration: timeoutConfiguration,
          ),
      MacOSWorkflow: () => const MacOSWorkflow(),
      MDnsObservatoryDiscovery: () => MDnsObservatoryDiscovery(),
      OperatingSystemUtils: () => OperatingSystemUtils(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        processManager: globals.processManager,
      ),
      PersistentToolState: () => PersistentToolState(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
      ),
      ProcessInfo: () => ProcessInfo(),
      ProcessUtils: () => ProcessUtils(
        processManager: globals.processManager,
        logger: globals.logger,
      ),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        botDetector: globals.botDetector,
        platform: globals.platform,
        usage: globals.flutterUsage,
      ),
      ShutdownHooks: () => ShutdownHooks(logger: globals.logger),
      Signals: () => Signals(),
      Stdio: () => Stdio(),
      SystemClock: () => const SystemClock(),
      TimeoutConfiguration: () => const TimeoutConfiguration(),
      Usage: () => Usage(
        runningOnBot: runningOnBot,
      ),
      UserMessages: () => UserMessages(),
      VisualStudioValidator: () => VisualStudioValidator(
        userMessages: globals.userMessages,
        visualStudio: VisualStudio(
          fileSystem: globals.fs,
          platform: globals.platform,
          logger: globals.logger,
          processManager: globals.processManager,
        )
      ),
      WebWorkflow: () => WebWorkflow(
        featureFlags: featureFlags,
        platform: globals.platform,
      ),
      WindowsWorkflow: () => const WindowsWorkflow(),
      Xcode: () => Xcode(
        logger: globals.logger,
        processManager: globals.processManager,
        platform: globals.platform,
        fileSystem: globals.fs,
        xcodeProjectInterpreter: globals.xcodeProjectInterpreter,
      ),
      XCDevice: () => XCDevice(
        processManager: globals.processManager,
        logger: globals.logger,
        artifacts: globals.artifacts,
        cache: globals.cache,
        platform: globals.platform,
        xcode: globals.xcode,
      ),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(
        logger: globals.logger,
        processManager: globals.processManager,
        platform: globals.platform,
        fileSystem: globals.fs,
        terminal: globals.terminal,
        usage: globals.flutterUsage,
      ),
    },
  );
}
