// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:engine_build_configs/engine_build_configs.dart';

import '../environment.dart';
import 'build_command.dart';
import 'format_command.dart';
import 'query_command.dart';

/// The root command runner.
final class ToolCommandRunner extends CommandRunner<int> {
  /// Constructs the runner and populates commands, subcommands, and global
  /// options and flags.
  ToolCommandRunner({
    required this.environment,
    required this.configs,
  }) : super(toolName, toolDescription) {
    final List<Command<int>> commands = <Command<int>>[
      FormatCommand(
        environment: environment,
      ),
      QueryCommand(environment: environment, configs: configs),
      BuildCommand(environment: environment, configs: configs),
    ];
    commands.forEach(addCommand);
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
