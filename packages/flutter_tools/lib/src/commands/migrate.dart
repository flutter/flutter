// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../migrate/migrate_utils.dart';
import '../runner/flutter_command.dart';
import 'migrate_abandon.dart';
import 'migrate_apply.dart';
import 'migrate_resolve_conflicts.dart';
import 'migrate_start.dart';
import 'migrate_status.dart';

/// Base command for the migration tool.
class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
    required this.logger,
    required FileSystem fileSystem,
    required Terminal terminal,
  }) : _verbose = verbose {
    addSubcommand(MigrateAbandonCommand(logger: logger, fileSystem: fileSystem, terminal: terminal));
    addSubcommand(MigrateApplyCommand(verbose: _verbose, logger: logger, fileSystem: fileSystem, terminal: terminal));
    addSubcommand(MigrateResolveConflictsCommand(logger: logger, fileSystem: fileSystem, terminal: terminal));
    addSubcommand(MigrateStartCommand(verbose: _verbose, logger: logger, fileSystem: fileSystem));
    addSubcommand(MigrateStatusCommand(verbose: _verbose, logger: logger, fileSystem: fileSystem));
  }

  final bool _verbose;

  final Logger logger;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrates flutter generated project files to the current flutter version';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    return const FlutterCommandResult(ExitStatus.fail);
  }
}

Future<bool> gitRepoExists(String projectDirectory, Logger logger) async {
  if (await MigrateUtils.isGitRepo(projectDirectory, logger)) {
    return true;
  }
  logger.printStatus('Project is not a git repo. Please initialize a git repo and try again.');
  printCommandText('git init', logger);
  return false;
}

Future<bool> hasUncommittedChanges(String projectDirectory, Logger logger) async {
  if (await MigrateUtils.hasUncommitedChanges(projectDirectory, logger)) {
    logger.printStatus('There are uncommitted changes in your project. Please git commit, abandon, or stash your changes before trying again.');
    return true;
  }
  return false;
}

/// Prints a command to logger with appropriate formatting.
void printCommandText(String command, Logger logger) {
  logger.printStatus(
    '\n\$ $command\n',
    color: TerminalColor.grey,
    indent: 4,
    newline: false,
  );
}
