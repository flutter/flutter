// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'context.dart';
import 'fakes.dart';

export 'package:test/test.dart' hide isInstanceOf, test;

CommandRunner<void> createTestCommandRunner([FlutterCommand? command, Analytics? analytics]) {
  final ToolContext? toolContext = command?.toolContext;
  var resolvedAnalytics = analytics;
  if (resolvedAnalytics == null) {
    try {
      resolvedAnalytics = context.get<Analytics>();
    } on UnsupportedError {
      // In testWithoutContext, context.get is not supported.
    }
  }
  final runner = TestFlutterCommandRunner(
    toolContext: toolContext,
    toolDependencies: (toolContext != null || resolvedAnalytics != null)
        ? FakeToolDependencies(analytics: resolvedAnalytics, toolContext: toolContext)
        : null,
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
  ToolContext? toolContext,
}) async {
  arguments ??= <String>['--no-pub'];
  final FileSystem fs = toolContext?.fs ?? globals.fs;
  final String projectPath = fs.path.join(temp.path, name);
  final command = CreateCommand(
    toolContext:
        toolContext ??
        FakeToolContext(
          fs: fs,
          logger: globals.logger,
          platform: globals.platform,
          processManager: globals.processManager,
          cache: globals.cache,
          flutterVersion: FakeFlutterVersion(),
        ),
  );
  Analytics? analytics;
  try {
    analytics = context.get<Analytics>();
  } on UnsupportedError {
    // In testWithoutContext, context.get is not supported.
  }
  final CommandRunner<void> runner = createTestCommandRunner(command, analytics);
  await runner.run(<String>['create', ...arguments, projectPath]);
  return projectPath;
}

class TestFlutterCommandRunner extends FlutterCommandRunner {
  TestFlutterCommandRunner({super.toolDependencies, super.toolContext});

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Logger? topLevelLogger = toolContext?.logger ?? context.get<Logger>();
    final contextOverrides = <Type, dynamic>{
      if (topLevelLogger != null && (topLevelResults['verbose'] as bool))
        Logger: VerboseLogger(topLevelLogger),
    };
    return context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, dynamic value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () {
        return super.runCommand(topLevelResults);
      },
    );
  }

  @override
  void printUsage() {
    (toolContext?.logger ?? testLogger).printStatus(usage);
  }
}
