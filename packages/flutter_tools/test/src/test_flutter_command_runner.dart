// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'fakes.dart';

export 'package:test/test.dart' hide isInstanceOf, test;

CommandRunner<void> createTestCommandRunner([
  FlutterCommand? command,
  Analytics? analytics,
  ToolContext? toolContext,
]) {
  final ToolContext? effectiveToolContext = toolContext ?? command?.toolContext;
  final runner = TestFlutterCommandRunner(analytics: analytics, toolContext: effectiveToolContext);
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
  TestFlutterCommandRunner({Analytics? analytics, ToolContext? toolContext})
    : super(
        analytics: analytics ?? _defaultAnalytics(),
        toolContext: toolContext ?? DelegatingToolContext(),
      );

  static Analytics _defaultAnalytics() {
    try {
      return context.get<Analytics>() ?? const NoOpAnalytics();
    } on UnsupportedError {
      return const NoOpAnalytics();
    }
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Logger topLevelLogger = toolContext.logger;
    final contextOverrides = <Type, Object?>{
      if (topLevelResults['verbose'] as bool) Logger: VerboseLogger(topLevelLogger),
      ProcessInfo: toolContext.processInfo,
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
