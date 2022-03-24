// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_compute.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate.dart';

class MigrateStartCommand extends FlutterCommand {
  MigrateStartCommand({
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
    argParser.addOption(
      'platforms',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addFlag(
      'delete-temp-directories',
      negatable: true,
      defaultsTo: true,
      help: "",
    );
    argParser.addOption(
      'base-app-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addOption(
      'target-app-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addOption(
      'base-revision',
      help: '',
      defaultsTo: null,
      valueHelp: '',
    );
    argParser.addOption(
      'target-revision',
      help: '',
      defaultsTo: null,
      valueHelp: '',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  @override
  final String name = 'start';

  @override
  final String description = 'Begins a new migration. Computes the changes needed to migrate the project from the base revision of Flutter to the current revision of Flutter and outputs the results in a working directory. Use `\$ flutter migrate apply` accept and apply the changes.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    if (project.isModule || project.isPlugin) {
      logger.printError('Migrate tool only supports app projects. This project is a ${project.isModule ? 'module' : 'plugin'}');
      return const FlutterCommandResult(ExitStatus.fail);
    }

    if (!await checkGitRepoExists(project.directory.path, logger)) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final Directory workingDir = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (workingDir.existsSync()) {
      logger.printStatus('Old migration already in progress.', emphasis: true);
      logger.printStatus('Pending migration files exist in `${workingDir.path}/$kDefaultMigrateWorkingDirectoryName`');
      logger.printStatus('Resolve merge conflicts and accept changes with by running:');
      MigrateUtils.printCommandText('flutter migrate apply', logger);
      logger.printStatus('You may also abandon the existing migration and start a new one with:');
      MigrateUtils.printCommandText('flutter migrate abandon', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    if (!await checkUncommittedChanges(project.directory.path, logger)) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    List<SupportedPlatform> platforms = <SupportedPlatform>[];
    if (stringArg('platforms') != null) {
      for (String platformString in stringArg('platforms')!.split(',')) {
        platformString = platformString.trim();
        platforms.add(SupportedPlatform.values.firstWhere(
          (SupportedPlatform val) => val.toString() == 'SupportedPlatform.$platformString'
        ));
      }
    }

    MigrateResult? migrateResult = await computeMigration(
      verbose: _verbose,
      flutterProject: project,
      baseAppPath: stringArg('base-app-directory'),
      targetAppPath: stringArg('target-app-directory'),
      baseRevision: stringArg('base-revision'),
      targetRevision: stringArg('target-revision'),
      deleteTempDirectories: boolArg('delete-temp-directories'),
      platforms: platforms,
      fileSystem: fileSystem,
      logger: logger,
    );
    if (migrateResult == null) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    await writeWorkingDir(migrateResult, logger, verbose: _verbose, flutterProject: project);

    MigrateUtils.deleteTempDirectories(
      paths: <String>[],
      directories: migrateResult.tempDirectories,
    );

    return const FlutterCommandResult(ExitStatus.success);
  }
}
