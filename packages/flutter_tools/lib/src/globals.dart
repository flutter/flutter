// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'android/gradle_utils.dart';
import 'artifacts.dart';
import 'base/context.dart';
import 'build_system/build_system.dart';
import 'device.dart';
import 'doctor.dart';
import 'fuchsia/fuchsia_sdk.dart';
import 'globals_null_migrated.dart' as globals;
import 'ios/simulators.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/xcdevice.dart';
import 'project.dart';
import 'reporting/crash_reporting.dart';
import 'runner/local_engine.dart';

export 'globals_null_migrated.dart';

Artifacts get artifacts => context.get<Artifacts>();
BuildSystem get buildSystem => context.get<BuildSystem>();
CrashReporter get crashReporter => context.get<CrashReporter>();
Doctor get doctor => context.get<Doctor>();
DeviceManager get deviceManager => context.get<DeviceManager>();

FlutterProjectFactory get projectFactory {
  return context.get<FlutterProjectFactory>() ?? FlutterProjectFactory(
    logger: globals.logger,
    fileSystem: globals.fs,
  );
}

CocoaPodsValidator get cocoapodsValidator => context.get<CocoaPodsValidator>();

LocalEngineLocator get localEngineLocator => context.get<LocalEngineLocator>();

CocoaPods get cocoaPods => context.get<CocoaPods>();
FuchsiaArtifacts get fuchsiaArtifacts => context.get<FuchsiaArtifacts>();
IOSSimulatorUtils get iosSimulatorUtils => context.get<IOSSimulatorUtils>();

XCDevice get xcdevice => context.get<XCDevice>();

/// Gradle utils in the current [AppContext].
GradleUtils get gradleUtils => context.get<GradleUtils>();
