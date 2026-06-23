// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:process/process.dart';

import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
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
    required this.outputPreferences,
    required this.platform,
    required this.preRunValidator,
    required this.processManager,
    required this.processUtils,
    required this.projectFactory,
    required this.shutdownHooks,
    required this.stdio,
    required this.systemClock,
    required this.terminal,
    required this.userMessages,
  });

  final BotDetector botDetector;
  final Cache cache;
  final Config config;
  final CustomDevicesConfig customDevicesConfig;
  final FlutterVersion flutterVersion;
  final FileSystem fs;
  final Git git;
  final LocalEngineLocator localEngineLocator;
  final Logger logger;
  final TestCompilerNativeAssetsBuilder? nativeAssetsBuilder;
  final OutputPreferences outputPreferences;
  final Platform platform;
  final PreRunValidator preRunValidator;
  final ProcessManager processManager;
  final ProcessUtils processUtils;
  final FlutterProjectFactory projectFactory;
  final ShutdownHooks shutdownHooks;
  final Stdio stdio;
  final SystemClock systemClock;
  final AnsiTerminal terminal;
  final UserMessages userMessages;
}
