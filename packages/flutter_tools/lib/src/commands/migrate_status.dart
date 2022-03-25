// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate.dart';

/// Flutter migrate subcommand to check the migration status of the project.
class MigrateStatusCommand extends FlutterCommand {
  MigrateStatusCommand({
    bool verbose = false,
    required this.logger,
    required this.fileSystem,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes.',
      defaultsTo: null,
      valueHelp: 'path',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  @override
  final String name = 'status';

  @override
  final String description = 'Prints the current status of the in progress migration.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  /// Manually marks the lines in a diff that should be printed unformatted for visbility.
  final Set<int> _initialDiffLines = <int>{0, 1};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    Directory workingDirectory = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (stringArg('working-directory') != null) {
      workingDirectory = fileSystem.directory(stringArg('working-directory'));
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);

    for (final String localPath in manifest.mergedFiles) {
      DiffResult result = await MigrateUtils.diffFiles(project.directory.childFile(localPath), workingDirectory.childFile(localPath));
      if (result.diff != '') {
        // Print with different colors for better visibility.
        int lineNumber = -1;
        for (final String line in result.diff.split('\n')) {
          lineNumber++;
          if (line.startsWith('---') || line.startsWith('+++') || line.startsWith('&&') || _initialDiffLines.contains(lineNumber)) {
            logger.printStatus(line);
            continue;
          }
          if (line.startsWith('-')) {
            logger.printStatus(line, color: TerminalColor.red);
            continue;
          }
          if (line.startsWith('+')) {
            logger.printStatus(line, color: TerminalColor.green);
            continue;
          }
          logger.printStatus(line, color: TerminalColor.grey);
        }
      }
    }

    logger.printBox('Working directory at `${workingDirectory.path}`');

    checkAndPrintMigrateStatus(manifest, workingDirectory, logger: logger);

    logger.printStatus('Resolve conflicts and accept changes with:');
    MigrateUtils.printCommandText('flutter migrate apply', logger);

    return const FlutterCommandResult(ExitStatus.success);
  }
}
