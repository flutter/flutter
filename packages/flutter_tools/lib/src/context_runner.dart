// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:quiver/time.dart';

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
import 'base/port_scanner.dart';
import 'base/utils.dart';
import 'cache.dart';
import 'compile.dart';
import 'devfs.dart';
import 'device.dart';
import 'doctor.dart';
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
  Map<Type, dynamic> overrides,
}) async {
  return await context.run<T>(
    name: 'global fallbacks',
    body: runner,
    overrides: overrides,
    fallbacks: <Type, Generator>{
      AndroidSdk: AndroidSdk.locateAndroidSdk,
      AndroidStudio: AndroidStudio.latestValid,
      AndroidWorkflow: () => new AndroidWorkflow(),
      Artifacts: () => new CachedArtifacts(),
      AssetBundleFactory: () => AssetBundleFactory.defaultInstance,
      BotDetector: () => const BotDetector(),
      Cache: () => new Cache(),
      Clock: () => const Clock(),
      CocoaPods: () => new CocoaPods(),
      Config: () => new Config(),
      DevFSConfig: () => new DevFSConfig(),
      DeviceManager: () => new DeviceManager(),
      Doctor: () => const Doctor(),
      DoctorValidatorsProvider: () => DoctorValidatorsProvider.defaultInstance,
      Flags: () => const EmptyFlags(),
      FlutterVersion: () => new FlutterVersion(const Clock()),
      GenSnapshot: () => const GenSnapshot(),
      HotRunnerConfig: () => new HotRunnerConfig(),
      IMobileDevice: () => const IMobileDevice(),
      IOSSimulatorUtils: () => new IOSSimulatorUtils(),
      IOSWorkflow: () => const IOSWorkflow(),
      KernelCompiler: () => const KernelCompiler(),
      Logger: () => platform.isWindows ? new WindowsStdoutLogger() : new StdoutLogger(),
      OperatingSystemUtils: () => new OperatingSystemUtils(),
      PortScanner: () => const HostPortScanner(),
      SimControl: () => new SimControl(),
      Stdio: () => const Stdio(),
      Usage: () => new Usage(),
      Xcode: () => new Xcode(),
      XcodeProjectInterpreter: () => new XcodeProjectInterpreter(),
    },
  );
}
