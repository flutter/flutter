// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'android/android_sdk.dart';
import 'android/android_studio.dart';
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
import 'cache.dart';
import 'ios/plist_parser.dart';

Cache get cache => context.get<Cache>()!;
Config get config => context.get<Config>()!;
HttpClientFactory? get httpClientFactory => context.get<HttpClientFactory>();
Logger get logger => context.get<Logger>()!;
OperatingSystemUtils get os => context.get<OperatingSystemUtils>()!;
Signals get signals => context.get<Signals>() ?? LocalSignals.instance;
AndroidStudio? get androidStudio => context.get<AndroidStudio>();
AndroidSdk? get androidSdk => context.get<AndroidSdk>();

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem get fs => ErrorHandlingFileSystem(
  delegate: context.get<FileSystem>() ?? localFileSystem,
  platform: platform,
);

FileSystemUtils get fsUtils => context.get<FileSystemUtils>() ?? FileSystemUtils(
  fileSystem: fs,
  platform: platform,
);

const ProcessManager _kLocalProcessManager = LocalProcessManager();

/// The active process manager.
ProcessManager get processManager => context.get<ProcessManager>() ?? _kLocalProcessManager;
ProcessUtils get processUtils => context.get<ProcessUtils>()!;

const Platform _kLocalPlatform = LocalPlatform();
Platform get platform => context.get<Platform>() ?? _kLocalPlatform;

UserMessages get userMessages => context.get<UserMessages>()!;

final OutputPreferences _default = OutputPreferences(
  wrapText: stdio.hasTerminal,
  showColor:  platform.stdoutSupportsAnsi,
  stdio: stdio,
);
OutputPreferences get outputPreferences => context.get<OutputPreferences>() ?? _default;

/// The current system clock instance.
SystemClock get systemClock => context.get<SystemClock>() ?? _systemClock;
SystemClock _systemClock = const SystemClock();

ProcessInfo get processInfo => context.get<ProcessInfo>()!;

/// Display an error level message to the user. Commands should use this if they
/// fail in some way.
///
/// Set [emphasis] to true to make the output bold if it's supported.
/// Set [color] to a [TerminalColor] to color the output, if the logger
/// supports it. The [color] defaults to [TerminalColor.red].
void printError(
  String message, {
  StackTrace? stackTrace,
  bool? emphasis,
  TerminalColor? color,
  int? indent,
  int? hangingIndent,
  bool? wrap,
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
  bool? emphasis,
  bool? newline,
  TerminalColor? color,
  int? indent,
  int? hangingIndent,
  bool? wrap,
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
  return context.get<AnsiTerminal>() ?? _defaultAnsiTerminal;
}

final AnsiTerminal _defaultAnsiTerminal = AnsiTerminal(
  stdio: stdio,
  platform: platform,
);

/// The global Stdio wrapper.
Stdio get stdio => context.get<Stdio>() ?? (_stdioInstance ??= Stdio());
Stdio? _stdioInstance;

PlistParser get plistParser => context.get<PlistParser>() ?? (
  _plistInstance ??= PlistParser(
    fileSystem: fs,
    processManager: processManager,
    logger: logger,
));
PlistParser? _plistInstance;

/// The global template renderer.
TemplateRenderer get templateRenderer => context.get<TemplateRenderer>()!;

ShutdownHooks? get shutdownHooks => context.get<ShutdownHooks>();

// Unless we're in a test of this class's signal handling features, we must
// have only one instance created with the singleton LocalSignals instance
// and the catchable signals it considers to be fatal.
LocalFileSystem? _instance;
LocalFileSystem get localFileSystem => _instance ??= LocalFileSystem(
  LocalSignals.instance,
  Signals.defaultExitSignals,
  shutdownHooks,
);
