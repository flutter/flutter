// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'migrate.dart';

/// Abandons the existing migration by deleting the migrate working directory.
class MigrateAbandonCommand extends FlutterCommand {
  MigrateAbandonCommand({
    bool verbose = false,
    required this.logger,
    required this.fileSystem,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes. '
            'This path can be absolute or relative to the flutter project root.',
      valueHelp: 'path',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

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
    final FlutterProject flutterProject = FlutterProject.current();
    Directory workingDirectory = flutterProject.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    final String? customWorkingDirectoryPath = stringArg('working-directory');
    if (customWorkingDirectoryPath != null) {
      if (customWorkingDirectoryPath.startsWith(fileSystem.path.separator) || customWorkingDirectoryPath.startsWith('/')) {
        // Is an absolute path
        workingDirectory = fileSystem.directory(customWorkingDirectoryPath);
      } else {
        workingDirectory = flutterProject.directory.childDirectory(customWorkingDirectoryPath);
      }
      if (!workingDirectory.existsSync()) {
        logger.printError('Provided working directory `$customWorkingDirectoryPath` does not exist or is not a valid.');
        return const FlutterCommandResult(ExitStatus.fail);
      }
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }
    if (_verbose) {
      logger.printStatus('Abandoning the existing migration will delete the migration working directory at ${workingDirectory.path}');
    }

    workingDirectory.deleteSync(recursive: true);
    
    logger.printStatus('\nAbandon complete. Start a new migration with:');
    MigrateUtils.printCommandText('flutter migrate start', logger);
    return const FlutterCommandResult(ExitStatus.success);
  }
}
