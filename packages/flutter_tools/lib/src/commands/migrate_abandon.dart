// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'migrate.dart';

/// Abandons the existing migration by deleting the migrate working directory.
class MigrateAbandonCommand extends FlutterCommand {
  MigrateAbandonCommand({
    required this.logger,
    required this.fileSystem,
    required this.terminal,
    required Platform platform,
    required ProcessManager processManager,
  }) : migrateUtils = MigrateUtils(
         logger: logger,
         fileSystem: fileSystem,
         platform: platform,
         processManager: processManager,
       ) {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes. '
            'This path can be absolute or relative to the flutter project root. This defaults to `migrate_working_dir`',
      valueHelp: 'path',
    );
    argParser.addOption(
      'project-directory',
      help: 'The root directory of the flutter project.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Delete the migrate working directory without asking for confirmation.',
    );
  }

  final Logger logger;

  final FileSystem fileSystem;

  final Terminal terminal;

  final MigrateUtils migrateUtils;

  @override
  final String name = 'abandon';

  @override
  final String description = 'Deletes the current active migration working directory.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? projectDirectory = stringArg('project-directory');
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null ? FlutterProject.current() : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));
    Directory workingDirectory = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    final String? customWorkingDirectoryPath = stringArg('working-directory');
    if (customWorkingDirectoryPath != null) {
      if (fileSystem.path.isAbsolute(customWorkingDirectoryPath)) {
        workingDirectory = fileSystem.directory(customWorkingDirectoryPath);
      } else {
        workingDirectory = project.directory.childDirectory(customWorkingDirectoryPath);
      }
      if (!workingDirectory.existsSync()) {
        logger.printError('Provided working directory `$customWorkingDirectoryPath` does not exist or is not valid.');
        return const FlutterCommandResult(ExitStatus.fail);
      }
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    logger.printStatus('\nAbandoning the existing migration will delete the migration working directory at ${workingDirectory.path}');
    final bool force = boolArg('force') ?? false;
    if (!force) {
      String selection = 'y';
      terminal.usesTerminalUi = true;
      try {
        selection = await terminal.promptForCharInput(
          <String>['y', 'n'],
          logger: logger,
          prompt: 'Are you sure you wish to continue with abandoning? (y)es, (N)o',
          defaultChoiceIndex: 1,
        );
      } on StateError catch(e) {
        logger.printError(
          e.message,
          indent: 0,
        );
      }
      if (selection != 'y') {
        return const FlutterCommandResult(ExitStatus.success);
      }
    }

    workingDirectory.deleteSync(recursive: true);

    logger.printStatus('\nAbandon complete. Start a new migration with:');
    printCommandText('flutter migrate start', logger);
    return const FlutterCommandResult(ExitStatus.success);
  }
}
