// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

import 'context.dart';

export 'package:test/test.dart' hide isInstanceOf, test;

CommandRunner<void> createTestCommandRunner([FlutterCommand? command]) {
  final FlutterCommandRunner runner = TestFlutterCommandRunner(toolContext: command?.toolContext);
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
  final String projectPath = globals.fs.path.join(temp.path, name);
  final command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>['create', ...arguments, projectPath]);
  return projectPath;
}

class TestFlutterCommandRunner extends FlutterCommandRunner {
  TestFlutterCommandRunner({super.toolDependencies, super.toolContext});

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final Logger? topLevelLogger = toolContext?.logger;
    final contextOverrides = <Type, dynamic>{
      if (topLevelLogger != null && (topLevelResults['verbose'] as bool))
        Logger: VerboseLogger(topLevelLogger),
    };
    return context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, dynamic value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () {
        if (toolContext != null) {
          Cache.flutterRoot ??= Cache.defaultFlutterRoot(
            platform: toolContext!.platform,
            fileSystem: toolContext!.fs,
            userMessages: toolContext!.userMessages,
          );
          Cache.flutterRoot = toolContext!.fs.path.normalize(
            toolContext!.fs.path.absolute(Cache.flutterRoot!),
          );
        }
        return super.runCommand(topLevelResults);
      },
    );
  }

  @override
  void printUsage() {
    (toolContext?.logger ?? testLogger).printStatus(usage);
  }
}
