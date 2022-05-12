// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import '../base/logger.dart';
import '../base/terminal.dart';
import '../migrate/migrate_utils.dart';
import '../runner/flutter_command.dart';


/// Base command for the migration tool.
class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    required this.logger,
    // TODO(garyq): Add each parameters in as subcommands land.
  }) {
    // TODO(garyq): Add subcommands.
  }

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

Future<bool> gitRepoExists(String projectDirectory, Logger logger, MigrateUtils migrateUtils) async {
  if (await migrateUtils.isGitRepo(projectDirectory)) {
    return true;
  }
  logger.printStatus('Project is not a git repo. Please initialize a git repo and try again.');
  printCommandText('git init', logger);
  return false;
}

Future<bool> hasUncommittedChanges(String projectDirectory, Logger logger, MigrateUtils migrateUtils) async {
  if (await migrateUtils.hasUncommittedChanges(projectDirectory)) {
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
