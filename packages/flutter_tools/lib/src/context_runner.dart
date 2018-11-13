// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/android_workflow.dart';
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
import 'base/utils.dart';
import 'cache.dart';
import 'compile.dart';
import 'devfs.dart';
import 'device.dart';
import 'doctor.dart';
import 'emulator.dart';
import 'fuchsia/fuchsia_sdk.dart';
import 'fuchsia/fuchsia_workflow.dart';
import 'ios/cocoapods.dart';
import 'ios/ios_workflow.dart';
import 'ios/mac.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'run_hot.dart';
import 'usage.dart';
import 'version.dart';

Future<T> runInContext<T>(
  FutureOr<T> runner(), {
  Map<Type, Generator> overrides,
}) async {
  return await context.run<T>(
    name: 'global fallbacks',
    body: runner,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidWorkflow: () => AndroidWorkflow(),
      AndroidValidator: () => AndroidValidator(),
      AndroidLicenseValidator: () => AndroidLicenseValidator(),
      Artifacts: () => CachedArtifacts(),
      AssetBundleFactory: () => AssetBundleFactory.defaultInstance,
      BotDetector: () => const BotDetector(),
      Cache: () => Cache(),
      CocoaPods: () => CocoaPods(),
      CocoaPodsValidator: () => const CocoaPodsValidator(),
      Config: () => Config(),
      DevFSConfig: () => DevFSConfig(),
      DeviceManager: () => DeviceManager(),
      Doctor: () => const Doctor(),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      EmulatorManager: () => EmulatorManager(),
      FuchsiaSdk: () => FuchsiaSdk(),
      FuchsiaArtifacts: () => FuchsiaArtifacts(),
      FuchsiaWorkflow: () => FuchsiaWorkflow(),
      Flags: () => const EmptyFlags(),
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      GenSnapshot: () => const GenSnapshot(),
      HotRunnerConfig: () => HotRunnerConfig(),
      IMobileDevice: () => const IMobileDevice(),
      IOSSimulatorUtils: () => IOSSimulatorUtils(),
      IOSWorkflow: () => const IOSWorkflow(),
      IOSValidator: () => const IOSValidator(),
      KernelCompiler: () => const KernelCompiler(),
      Logger: () => platform.isWindows ? WindowsStdoutLogger() : StdoutLogger(),
      OperatingSystemUtils: () => OperatingSystemUtils(),
      PlistBuddy: () => const PlistBuddy(),
      SimControl: () => SimControl(),
      SystemClock: () => const SystemClock(),
      Stdio: () => const Stdio(),
      Usage: () => Usage(),
      Xcode: () => Xcode(),
      XcodeProjectInterpreter: () => XcodeProjectInterpreter(),
    },
  );
}
