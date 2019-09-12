// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
import 'android/gradle.dart';
import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/build.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/flags.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'base/time.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'build_system/build_system.dart';
import 'cache.dart';
import 'compile.dart';
import 'devfs.dart';
import 'device.dart';
import 'doctor.dart';
import 'emulator.dart';
import 'features.dart';
import 'fuchsia/fuchsia_device.dart' show FuchsiaDeviceTools;
import 'fuchsia/fuchsia_sdk.dart' show FuchsiaSdk, FuchsiaArtifacts;
import 'fuchsia/fuchsia_workflow.dart' show FuchsiaWorkflow;
import 'ios/devices.dart' show IOSDeploy;
import 'ios/ios_workflow.dart';
import 'ios/mac.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'linux/linux_workflow.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcode.dart';
import 'macos/xcode_validator.dart';
import 'reporting/reporting.dart';
import 'run_hot.dart';
import 'version.dart';
import 'web/chrome.dart';
import 'web/workflow.dart';
import 'windows/visual_studio.dart';
import 'windows/visual_studio_validator.dart';
import 'windows/windows_workflow.dart';

Future<T> runInContext<T>(
  FutureOr<T> runner(), {
  Map<Type, Generator> overrides,
}) async {
  return await context.run<T>(
    name: 'global fallbacks',
    body: runner,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      AndroidLicenseValidator: () => AndroidLicenseValidator(),
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidValidator: () => AndroidValidator(),
      AndroidWorkflow: () => AndroidWorkflow(),
      ApplicationPackageFactory: () => ApplicationPackageFactory(),
      Artifacts: () => CachedArtifacts(),
      AssetBundleFactory: () => AssetBundleFactory.defaultInstance,
      BotDetector: () => const BotDetector(),
      BuildSystem: () => const BuildSystem(),
      Cache: () => Cache(),
      ChromeLauncher: () => const ChromeLauncher(),
      CocoaPods: () => CocoaPods(),
      CocoaPodsValidator: () => const CocoaPodsValidator(),
      Config: () => Config(),
      DevFSConfig: () => DevFSConfig(),
      DeviceManager: () => DeviceManager(),
      Doctor: () => const Doctor(),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      EmulatorManager: () => EmulatorManager(),
      FeatureFlags: () => const FeatureFlags(),
      Flags: () => const EmptyFlags(),
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      FuchsiaArtifacts: () => FuchsiaArtifacts.find(),
      FuchsiaDeviceTools: () => FuchsiaDeviceTools(),
      FuchsiaSdk: () => FuchsiaSdk(),
      FuchsiaWorkflow: () => FuchsiaWorkflow(),
      GenSnapshot: () => const GenSnapshot(),
      GradleUtils: () => GradleUtils(),
      HotRunnerConfig: () => HotRunnerConfig(),
      IMobileDevice: () => IMobileDevice(),
      IOSDeploy: () => const IOSDeploy(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(),
      IOSWorkflow: () => const IOSWorkflow(),
      KernelCompilerFactory: () => const KernelCompilerFactory(),
      LinuxWorkflow: () => const LinuxWorkflow(),
      Logger: () => platform.isWindows ? WindowsStdoutLogger() : StdoutLogger(),
      MacOSWorkflow: () => const MacOSWorkflow(),
      OperatingSystemUtils: () => OperatingSystemUtils(),
      ProcessUtils: () => ProcessUtils(),
      SimControl: () => SimControl(),
      Stdio: () => const Stdio(),
      SystemClock: () => const SystemClock(),
      TimeoutConfiguration: () => const TimeoutConfiguration(),
      Usage: () => Usage(),
      UserMessages: () => UserMessages(),
      VisualStudio: () => VisualStudio(),
      VisualStudioValidator: () => const VisualStudioValidator(),
      WebWorkflow: () => const WebWorkflow(),
      WindowsWorkflow: () => const WindowsWorkflow(),
      Xcode: () => Xcode(),
      XcodeValidator: () => const XcodeValidator(),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(),
    },
  );
}
