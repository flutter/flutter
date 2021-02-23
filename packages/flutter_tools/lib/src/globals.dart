// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:process/process.dart';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
import 'android/gradle_utils.dart';
import 'artifacts.dart';
import 'base/bot_detector.dart';
import 'base/config.dart';
import 'base/context.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'base/signals.dart';
import 'base/template.dart';
import 'base/terminal.dart';
import 'base/time.dart';
import 'base/user_messages.dart';
import 'build_system/build_system.dart';
import 'cache.dart';
import 'device.dart';
import 'doctor.dart';
import 'fuchsia/fuchsia_sdk.dart';
import 'ios/ios_workflow.dart';
import 'ios/plist_parser.dart';
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

Artifacts get artifacts => context.get<Artifacts>();
BuildSystem get buildSystem => context.get<BuildSystem>();
Cache get cache => context.get<Cache>();
Config get config => context.get<Config>();
CrashReporter get crashReporter => context.get<CrashReporter>();
Doctor get doctor => context.get<Doctor>();
HttpClientFactory get httpClientFactory => context.get<HttpClientFactory>();
Logger get logger => context.get<Logger>();
OperatingSystemUtils get os => context.get<OperatingSystemUtils>();
PersistentToolState get persistentToolState => PersistentToolState.instance;
Signals get signals => context.get<Signals>() ?? LocalSignals.instance;
Usage get flutterUsage => context.get<Usage>();
DeviceManager get deviceManager => context.get<DeviceManager>();

FlutterProjectFactory get projectFactory {
  return context.get<FlutterProjectFactory>() ?? FlutterProjectFactory(
    logger: logger,
    fileSystem: fs,
  );
}

CocoaPodsValidator get cocoapodsValidator => context.get<CocoaPodsValidator>();

LocalEngineLocator get localEngineLocator => context.get<LocalEngineLocator>();

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem get fs => ErrorHandlingFileSystem(
  delegate: context.get<FileSystem>() ?? LocalFileSystem.instance,
  platform: platform,
);

FileSystemUtils get fsUtils => context.get<FileSystemUtils>() ?? FileSystemUtils(
  fileSystem: fs,
  platform: platform,
);

const ProcessManager _kLocalProcessManager = LocalProcessManager();

/// The active process manager.
ProcessManager get processManager => context.get<ProcessManager>() ?? _kLocalProcessManager;
ProcessUtils get processUtils => context.get<ProcessUtils>();

const Platform _kLocalPlatform = LocalPlatform();

Platform get platform => context.get<Platform>() ?? _kLocalPlatform;

AndroidStudio get androidStudio => context.get<AndroidStudio>();
AndroidSdk get androidSdk => context.get<AndroidSdk>();
CocoaPods get cocoaPods => context.get<CocoaPods>();
FlutterVersion get flutterVersion => context.get<FlutterVersion>();
FuchsiaArtifacts get fuchsiaArtifacts => context.get<FuchsiaArtifacts>();
IOSSimulatorUtils get iosSimulatorUtils => context.get<IOSSimulatorUtils>();
IOSWorkflow get iosWorkflow => context.get<IOSWorkflow>();
UserMessages get userMessages => context.get<UserMessages>();
Xcode get xcode => context.get<Xcode>();
XcodeProjectInterpreter get xcodeProjectInterpreter => context.get<XcodeProjectInterpreter>();

XCDevice get xcdevice => context.get<XCDevice>();

final OutputPreferences _defaultOutputPreferences = OutputPreferences();
OutputPreferences get outputPreferences => context.get<OutputPreferences>() ?? _defaultOutputPreferences;

final BotDetector _defaultBotDetector = BotDetector(
  httpClientFactory: context.get<HttpClientFactory>() ?? () => HttpClient(),
  platform: platform,
  persistentToolState: persistentToolState,
);

BotDetector get botDetector => context.get<BotDetector>() ?? _defaultBotDetector;

Future<bool> get isRunningOnBot => botDetector.isRunningOnBot;

/// The current system clock instance.
SystemClock get systemClock => context.get<SystemClock>();

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
///
/// Set [emphasis] to true to make the output bold if it's supported.
/// Set [color] to a [TerminalColor] to color the output, if the logger
/// supports it. The [color] defaults to [TerminalColor.red].
void printError(
  String message, {
  StackTrace stackTrace,
  bool emphasis,
  TerminalColor color,
  int indent,
  int hangingIndent,
  bool wrap,
}) {
  logger.printError(
    message,
    stackTrace: stackTrace,
    emphasis: emphasis ?? false,
    color: color,
    indent: indent,
    hangingIndent: hangingIndent,
    wrap: wrap,
  );
}

/// Display normal output of the command. This should be used for things like
/// progress messages, success messages, or just normal command output.
///
/// Set `emphasis` to true to make the output bold if it's supported.
///
/// Set `newline` to false to skip the trailing linefeed.
///
/// If `indent` is provided, each line of the message will be prepended by the
/// specified number of whitespaces.
void printStatus(
  String message, {
  bool emphasis,
  bool newline,
  TerminalColor color,
  int indent,
  int hangingIndent,
  bool wrap,
}) {
  logger.printStatus(
    message,
    emphasis: emphasis ?? false,
    color: color,
    newline: newline ?? true,
    indent: indent,
    hangingIndent: hangingIndent,
    wrap: wrap,
  );
}

/// Use this for verbose tracing output. Users can turn this output on in order
/// to help diagnose issues with the toolchain or with their setup.
void printTrace(String message) => logger.printTrace(message);

AnsiTerminal get terminal {
  return context?.get<AnsiTerminal>() ?? _defaultAnsiTerminal;
}

final AnsiTerminal _defaultAnsiTerminal = AnsiTerminal(
  stdio: stdio,
  platform: platform,
);

/// The global Stdio wrapper.
Stdio get stdio => context.get<Stdio>() ?? (_stdioInstance ??= Stdio());
Stdio _stdioInstance;

PlistParser get plistParser => context.get<PlistParser>() ?? (
  _plistInstance ??= PlistParser(
    fileSystem: fs,
    processManager: processManager,
    logger: logger,
));
PlistParser _plistInstance;

/// The global template renderer.
TemplateRenderer get templateRenderer => context.get<TemplateRenderer>();

/// Gradle utils in the current [AppContext].
GradleUtils get gradleUtils => context.get<GradleUtils>();
