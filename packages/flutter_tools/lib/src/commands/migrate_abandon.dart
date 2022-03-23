// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../cache.dart';
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
      help: '',
      defaultsTo: null,
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
    Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (stringArg('working-directory') != null) {
      workingDir = fileSystem.directory(stringArg('working-directory'));
    }
    if (!workingDir.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }
    logger.printStatus('Abandoning the existing migration will delete the migration working directory at ${workingDir.path}');
    workingDir.deleteSync(recursive: true);
    logger.printStatus('\nAbandon complete. Start a new migration with:');
    MigrateUtils.printCommandText('flutter migrate start', logger);
    return const FlutterCommandResult(ExitStatus.success);
  }
}
