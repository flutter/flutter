// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:engine_build_configs/engine_build_configs.dart';

import '../build_utils.dart';
import '../environment.dart';
import 'flags.dart';

/// The base class that all commands and subcommands should inherit from.
abstract base class CommandBase extends Command<int> {
  /// Constructs the base command.
  CommandBase({
    required this.environment,
    this.help = false,
    int? usageLineLength,
  }) : argParser = ArgParser(usageLineLength: usageLineLength);

  /// The host system environment.
  final Environment environment;

  /// Whether the Command is being constructed only to print the usage/help
  /// message.
  final bool help;

  @override
  final ArgParser argParser;

  @override
  void printUsage() {
    environment.logger.status(usage);
  }
}

/// Adds the -c (--config) option to the parser.
void addConfigOption(
  Environment environment,
  ArgParser parser,
  List<Build> builds, {
  String defaultsTo = 'host_debug',
}) {
  parser.addOption(
    configFlag,
    abbr: 'c',
    defaultsTo: defaultsTo,
    help: 'Specify the build config to use. Run "et help build --verbose" to '
        'see the full list of runnable configurations.',
    allowed: <String>[
      for (final Build config in builds)
        mangleConfigName(environment, config.name),
    ],
    allowedHelp: <String, String>{
      for (final Build config in builds)
        mangleConfigName(environment, config.name): config.description,
    },
  );
}

/// Adds the -j option to the parser.
void addConcurrencyOption(ArgParser parser) {
  parser.addOption(
    concurrencyFlag,
    abbr: 'j',
    defaultsTo: '0',
    help: 'Specify the concurrency level to use for the ninja build.',
  );
}
