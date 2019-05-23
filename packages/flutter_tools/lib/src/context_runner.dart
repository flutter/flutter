// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
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
import 'base/time.dart';
import 'base/user_messages.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'compile.dart';
import 'devfs.dart';
import 'device.dart';
import 'doctor.dart';
import 'emulator.dart';
import 'fuchsia/fuchsia_device.dart' show FuchsiaDeviceTools;
import 'fuchsia/fuchsia_sdk.dart' show FuchsiaSdk, FuchsiaArtifacts;
import 'fuchsia/fuchsia_workflow.dart' show FuchsiaWorkflow;
import 'ios/cocoapods.dart';
import 'ios/ios_workflow.dart';
import 'ios/mac.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'linux/linux_workflow.dart';
import 'macos/macos_workflow.dart';
import 'run_hot.dart';
import 'usage.dart';
import 'version.dart';
import 'web/compile.dart';
import 'web/web_device.dart';
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
      Flags: () => const EmptyFlags(),
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      FuchsiaArtifacts: () => FuchsiaArtifacts.find(),
      FuchsiaDeviceTools: () => FuchsiaDeviceTools(),
      FuchsiaSdk: () => FuchsiaSdk(),
      FuchsiaWorkflow: () => FuchsiaWorkflow(),
      GenSnapshot: () => const GenSnapshot(),
      HotRunnerConfig: () => HotRunnerConfig(),
      IMobileDevice: () => const IMobileDevice(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(),
      IOSValidator: () => const IOSValidator(),
      IOSWorkflow: () => const IOSWorkflow(),
      KernelCompilerFactory: () => const KernelCompilerFactory(),
      LinuxWorkflow: () => const LinuxWorkflow(),
      Logger: () => platform.isWindows ? WindowsStdoutLogger() : StdoutLogger(),
      MacOSWorkflow: () => const MacOSWorkflow(),
      OperatingSystemUtils: () => OperatingSystemUtils(),
      PlistBuddy: () => const PlistBuddy(),
      SimControl: () => SimControl(),
      Stdio: () => const Stdio(),
      SystemClock: () => const SystemClock(),
      TimeoutConfiguration: () => const TimeoutConfiguration(),
      Usage: () => Usage(),
      UserMessages: () => UserMessages(),
      WebCompiler: () => const WebCompiler(),
      WindowsWorkflow: () => const WindowsWorkflow(),
      Xcode: () => Xcode(),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(),
    },
  );
}
