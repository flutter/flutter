// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'fakes.dart';

export 'package:test/test.dart' hide isInstanceOf, test;

CommandRunner<void> createTestCommandRunner([
  FlutterCommand? command,
  Analytics? analytics,
  ToolContext? toolContext,
  FeatureFlags? featureFlags,
  AppleContext? appleContext,
]) {
  final ToolContext? effectiveToolContext = toolContext ?? command?.toolContext;
  final AppleContext? effectiveAppleContext =
      appleContext ?? (command is BuildCommand ? command.appleContext : null);
  final runner = TestFlutterCommandRunner(
    analytics: analytics,
    featureFlags: featureFlags,
    toolContext: effectiveToolContext,
    appleContext: effectiveAppleContext,
  );
  if (command != null) {
    runner.addCommand(command);
  }
  return runner;
}

/// Creates a flutter project in the [temp] directory using the
/// [arguments] list if specified, or `--no-pub` if not.
/// Returns the path to the flutter project.
Future<String> createProject(
  Directory temp, {
  String name = 'flutter_project',
  List<String>? arguments,
}) async {
  arguments ??= <String>['--no-pub'];
  final String projectPath = temp.fileSystem.path.join(temp.path, name);
  final command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>['create', ...arguments, projectPath]);
  return projectPath;
}

class TestFlutterCommandRunner extends FlutterCommandRunner {
  TestFlutterCommandRunner({
    Analytics? analytics,
    AppleContext? appleContext,
    FeatureFlags? featureFlags,
    ToolContext? toolContext,
  }) : _appleContext = appleContext,
       super(
         analytics: analytics ?? _defaultAnalytics(),
         featureFlags: featureFlags ?? _defaultFeatureFlags(),
         toolContext: toolContext ?? DelegatingToolContext(),
       );

  final AppleContext? _appleContext;

  AppleContext? get _effectiveAppleContext {
    if (_appleContext != null) {
      return _appleContext;
    }
    for (final Command<void> cmd in commands.values) {
      if (cmd is BuildCommand) {
        return cmd.appleContext;
      }
    }
    return null;
  }

  static Analytics _defaultAnalytics() {
    try {
      return context.get<Analytics>() ?? const NoOpAnalytics();
    } on UnsupportedError {
      return const NoOpAnalytics();
    }
  }

  static FeatureFlags? _defaultFeatureFlags() {
    try {
      return context.get<FeatureFlags>();
    } on UnsupportedError {
      return null;
    }
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Logger topLevelLogger = toolContext.logger;
    final AppleContext? effectiveAppleContext = _effectiveAppleContext;
    final contextOverrides = <Type, Object?>{
      if (topLevelResults['verbose'] as bool)
        Logger: VerboseLogger(topLevelLogger)
      else if (!context.hasExplicitOverride<Logger>())
        Logger: topLevelLogger,
      if (!context.hasExplicitOverride<FileSystem>()) FileSystem: toolContext.fs,
      if (!context.hasExplicitOverride<Platform>()) Platform: toolContext.platform,
      if (!context.hasExplicitOverride<ProcessManager>())
        ProcessManager: toolContext.processManager,
      if (!context.hasExplicitOverride<OperatingSystemUtils>())
        OperatingSystemUtils: toolContext.os,
      if (!context.hasExplicitOverride<AnsiTerminal>()) AnsiTerminal: toolContext.terminal,
      if (!context.hasExplicitOverride<FlutterVersion>())
        FlutterVersion: toolContext.flutterVersion,
      if (!context.hasExplicitOverride<Artifacts>()) Artifacts: toolContext.artifacts,
      if (!context.hasExplicitOverride<Cache>()) Cache: toolContext.cache,
      if (!context.hasExplicitOverride<Config>()) Config: toolContext.config,
      if (!context.hasExplicitOverride<ProcessInfo>()) ProcessInfo: toolContext.processInfo,
      if (!context.hasExplicitOverride<Analytics>()) Analytics: analytics,
      if (!context.hasExplicitOverride<FlutterProjectFactory>())
        FlutterProjectFactory: FlutterProjectFactory(
          fileSystem: toolContext.fs,
          logger: toolContext.logger,
        ),
      if (effectiveAppleContext case final AppleContext appleContext) ...<Type, Object?>{
        if (appleContext.xcode case final Xcode xcode)
          if (!context.hasExplicitOverride<Xcode>()) Xcode: xcode,
        if (appleContext.xcodeProjectInterpreter
            case final XcodeProjectInterpreter xcodeProjectInterpreter)
          if (!context.hasExplicitOverride<XcodeProjectInterpreter>())
            XcodeProjectInterpreter: xcodeProjectInterpreter,
        if (appleContext.plistParser case final PlistParser plistParser)
          if (!context.hasExplicitOverride<PlistParser>()) PlistParser: plistParser,
      },
    };
    return context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, Object? value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () {
        Cache.flutterRoot ??= Cache.defaultFlutterRoot(
          platform: toolContext.platform,
          fileSystem: toolContext.fs,
          userMessages: UserMessages(),
        );
        // For compatibility with tests that set this to a relative path.
        final FileSystem fs = toolContext.fs;
        Cache.flutterRoot = fs.path.normalize(fs.path.absolute(Cache.flutterRoot!));
        return super.runCommand(topLevelResults);
      },
    );
  }

  @override
  void printUsage() {
    toolContext.logger.printStatus(usage);
  }
}
