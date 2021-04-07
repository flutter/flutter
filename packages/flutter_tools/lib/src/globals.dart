// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'android/gradle_utils.dart';
import 'artifacts.dart';
import 'base/bot_detector.dart';
import 'base/context.dart';
import 'base/io.dart';
import 'base/net.dart';
import 'build_system/build_system.dart';
import 'device.dart';
import 'doctor.dart';
import 'fuchsia/fuchsia_sdk.dart';
import 'globals_null_migrated.dart' as globals;
import 'ios/ios_workflow.dart';
import 'ios/simulators.dart';
import 'ios/xcodeproj.dart';
import 'macos/cocoapods.dart';
import 'macos/cocoapods_validator.dart';
import 'macos/xcode.dart';
import 'persistent_tool_state.dart';
import 'project.dart';
import 'reporting/reporting.dart';
import 'runner/local_engine.dart';
import 'version.dart';

export 'globals_null_migrated.dart';

Artifacts get artifacts => context.get<Artifacts>();
BuildSystem get buildSystem => context.get<BuildSystem>();
CrashReporter get crashReporter => context.get<CrashReporter>();
Doctor get doctor => context.get<Doctor>();
PersistentToolState get persistentToolState => PersistentToolState.instance;
Usage get flutterUsage => context.get<Usage>();
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
FlutterVersion get flutterVersion => context.get<FlutterVersion>();
FuchsiaArtifacts get fuchsiaArtifacts => context.get<FuchsiaArtifacts>();
IOSSimulatorUtils get iosSimulatorUtils => context.get<IOSSimulatorUtils>();
IOSWorkflow get iosWorkflow => context.get<IOSWorkflow>();
Xcode get xcode => context.get<Xcode>();
XcodeProjectInterpreter get xcodeProjectInterpreter => context.get<XcodeProjectInterpreter>();

XCDevice get xcdevice => context.get<XCDevice>();

final BotDetector _defaultBotDetector = BotDetector(
  httpClientFactory: context.get<HttpClientFactory>() ?? () => HttpClient(),
  platform: globals.platform,
  persistentToolState: persistentToolState,
);

BotDetector get botDetector => context.get<BotDetector>() ?? _defaultBotDetector;

Future<bool> get isRunningOnBot => botDetector.isRunningOnBot;

/// Gradle utils in the current [AppContext].
GradleUtils get gradleUtils => context.get<GradleUtils>();
