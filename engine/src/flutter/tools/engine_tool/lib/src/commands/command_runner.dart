// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:engine_build_configs/engine_build_configs.dart';

import '../environment.dart';
import 'build_command.dart';
import 'fetch_command.dart';
import 'flags.dart';
import 'format_command.dart';
import 'lint_command.dart';
import 'query_command.dart';
import 'run_command.dart';

const int _usageLineLength = 80;

/// The root command runner.
final class ToolCommandRunner extends CommandRunner<int> {
  /// Constructs the runner and populates commands, subcommands, and global
  /// options and flags.
  ToolCommandRunner({
    required this.environment,
    required this.configs,
  }) : super(toolName, toolDescription, usageLineLength: _usageLineLength) {
    final List<Command<int>> commands = <Command<int>>[
      FetchCommand(environment: environment),
      FormatCommand(environment: environment),
      QueryCommand(environment: environment, configs: configs),
      BuildCommand(environment: environment, configs: configs),
      RunCommand(environment: environment, configs: configs),
      LintCommand(environment: environment),
    ];
    commands.forEach(addCommand);

    argParser.addFlag(
      verboseFlag,
      abbr: 'v',
      help: 'Prints verbose output',
      negatable: false,
    );
  }

  /// The name of the tool as reported in the tool's usage and help
  /// messages.
  static const String toolName = 'et';

  /// The description of the tool reported in the tool's usage and help
  /// messages.
  static const String toolDescription = 'A command line tool for working on '
      'the Flutter Engine.';

  /// The host system environment.
  final Environment environment;

  /// Build configurations loaded from the engine from under ci/builders.
  final Map<String, BuilderConfig> configs;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      return await runCommand(parse(args)) ?? 0;
    } on FormatException catch (e) {
      environment.logger.error(e);
      return 1;
    } on UsageException catch (e) {
      environment.logger.error(e);
      return 1;
    }
  }
}
