// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../cache.dart';
import '../custom_devices/custom_devices_config.dart';
import '../git.dart';
import '../native_assets.dart';
import '../pre_run_validator.dart';
import '../project.dart';
import '../runner/local_engine.dart';
import '../version.dart';

/// Holds core, platform-independent dependencies.
class ToolContext {
  ToolContext({
    required this.artifacts,
    required this.botDetector,
    required this.cache,
    required this.config,
    required this.customDevicesConfig,
    required this.flutterVersion,
    required this.fs,
    required this.git,
    required this.localEngineLocator,
    required this.logger,
    this.nativeAssetsBuilder,
    required this.os,
    required this.outputPreferences,
    required this.platform,
    required this.preRunValidator,
    required this.processInfo,
    required this.processManager,
    required this.processUtils,
    required this.projectFactory,
    required this.shutdownHooks,
    required this.signals,
    required this.stdio,
    required this.systemClock,
    required this.terminal,
    required this.userMessages,
  });

  /// Cached and host-specific binary artifacts.
  final Artifacts artifacts;

  /// Detects whether the tool is running in a CI or automated bot environment.
  final BotDetector botDetector;

  /// Manages cached SDK artifacts, binary downloads, and directory structures.
  final Cache cache;

  /// Reads and writes user and persistent global configuration settings.
  final Config config;

  /// Manages user-configured custom device definitions stored on disk.
  final CustomDevicesConfig customDevicesConfig;

  /// Provides version and git channel info for the current Flutter SDK.
  final FlutterVersion flutterVersion;

  /// Provides mockable file system operations across host and virtual environments.
  final FileSystem fs;

  /// Wraps host `git` operations, tracking repository state and branch revisions.
  final Git git;

  /// Locates local engine builds specified via command-line flags.
  final LocalEngineLocator localEngineLocator;

  /// Formats and emits console status, trace, warning, and error logs.
  final Logger logger;

  /// Builds and packages native C/C++ or Rust assets for compilation and tests.
  final TestCompilerNativeAssetsBuilder? nativeAssetsBuilder;

  /// Operating system utilities and environment queries.
  final OperatingSystemUtils os;

  /// Manages formatting preferences for console output, such as line wrapping width.
  final OutputPreferences outputPreferences;

  /// Provides host operating system details and environment variables.
  final Platform platform;

  /// Validates environment prerequisites and file permissions before command execution.
  final PreRunValidator preRunValidator;

  /// Process resource and memory usage reporting.
  final ProcessInfo processInfo;

  /// Spawns and manages external host processes.
  final ProcessManager processManager;

  /// Utility helpers for executing processes, error handling, and stream capturing.
  final ProcessUtils processUtils;

  /// Instantiates and caches [FlutterProject] instances for project directories.
  final FlutterProjectFactory projectFactory;

  /// Manages lifecycle callbacks executed upon tool termination or interrupt signals.
  final ShutdownHooks shutdownHooks;

  /// Intercepts and dispatches process signals.
  final Signals signals;

  /// Provides standard I/O streams (`stdin`, `stdout`, `stderr`).
  final Stdio stdio;

  /// Provides mockable system time interfaces for timed operations.
  final SystemClock systemClock;

  /// Formats terminal text output, colorization, and ANSI terminal capabilities.
  final AnsiTerminal terminal;

  /// Centralized templates for user-facing status strings and error messages.
  final UserMessages userMessages;

  /// Common file system utilities.
  FileSystemUtils get fileSystemUtils => FileSystemUtils(fileSystem: fs, platform: platform);
}
