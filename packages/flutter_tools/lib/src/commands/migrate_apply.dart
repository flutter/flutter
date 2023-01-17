// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../flutter_project_metadata.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_update_locks.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'migrate.dart';

/// Migrate subcommand that checks the migrate working directory for unresolved conflicts and
/// applies the staged changes to the project.
class MigrateApplyCommand extends FlutterCommand {
  MigrateApplyCommand({
    bool verbose = false,
    required this.logger,
    required this.fileSystem,
    required this.terminal,
    required Platform platform,
    required ProcessManager processManager,
  }) : _verbose = verbose,
       migrateUtils = MigrateUtils(
         logger: logger,
         fileSystem: fileSystem,
         platform: platform,
         processManager: processManager,
  ) {
    requiresPubspecYaml();
    argParser.addOption(
      'staging-directory',
      help: 'Specifies the custom migration working directory used to stage '
            'and edit proposed changes. This path can be absolute or relative '
            'to the flutter project root. This defaults to '
            '`$kDefaultMigrateStagingDirectoryName`',
      valueHelp: 'path',
    );
    argParser.addOption(
      'project-directory',
      help: 'The root directory of the flutter project. This defaults to the '
            'current working directory if omitted.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Ignore unresolved merge conflicts and uncommitted changes and '
            'apply staged changes by force.',
    );
    argParser.addFlag(
      'keep-working-directory',
      help: 'Do not delete the working directory.',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  final Terminal terminal;

  final MigrateUtils migrateUtils;

  @override
  final String name = 'apply';

  @override
  final String description = r'Accepts the changes produced by `$ flutter '
                              'migrate start` and copies the changed files into '
                              'your project files. All merge conflicts should '
                              'be resolved before apply will complete '
                              'successfully. If conflicts still exist, this '
                              'command will print the remaining conflicted files.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? projectDirectory = stringArg('project-directory');
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null
      ? FlutterProject.current()
      : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));

    if (!await gitRepoExists(project.directory.path, logger, migrateUtils)) {
      logger.printStatus('No git repo found. Please run in a project with an '
                         'initialized git repo or initialize one with:');
      printCommandText('git init', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final bool force = boolArg('force') ?? false;

    Directory stagingDirectory = project.directory.childDirectory(kDefaultMigrateStagingDirectoryName);
    final String? customStagingDirectoryPath = stringArg('staging-directory');
    if (customStagingDirectoryPath != null) {
      if (fileSystem.path.isAbsolute(customStagingDirectoryPath)) {
        stagingDirectory = fileSystem.directory(customStagingDirectoryPath);
      } else {
        stagingDirectory = project.directory.childDirectory(customStagingDirectoryPath);
      }
    }
    if (!stagingDirectory.existsSync()) {
      logger.printStatus('No migration in progress at $stagingDirectory. Please run:');
      printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(stagingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
    if (!checkAndPrintMigrateStatus(manifest, stagingDirectory, warnConflict: true, logger: logger) && !force) {
      logger.printStatus('Conflicting files found. Resolve these conflicts and try again.');
      logger.printStatus('Guided conflict resolution wizard:');
      printCommandText('flutter migrate resolve-conflicts', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    if (await hasUncommittedChanges(project.directory.path, logger, migrateUtils) && !force) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    logger.printStatus('Applying migration.');
    // Copy files from working directory to project root
    final List<String> allFilesToCopy = <String>[];
    allFilesToCopy.addAll(manifest.mergedFiles);
    allFilesToCopy.addAll(manifest.conflictFiles);
    allFilesToCopy.addAll(manifest.addedFiles);
    if (allFilesToCopy.isNotEmpty && _verbose) {
      logger.printStatus('Modifying ${allFilesToCopy.length} files.', indent: 2);
    }
    for (final String localPath in allFilesToCopy) {
      if (_verbose) {
        logger.printStatus('Writing $localPath');
      }
      final File workingFile = stagingDirectory.childFile(localPath);
      final File targetFile = project.directory.childFile(localPath);
      if (!workingFile.existsSync()) {
        continue;
      }

      if (!targetFile.existsSync()) {
        targetFile.createSync(recursive: true);
      }
      try {
        targetFile.writeAsStringSync(workingFile.readAsStringSync(), flush: true);
      } on FileSystemException {
        targetFile.writeAsBytesSync(workingFile.readAsBytesSync(), flush: true);
      }
    }
    // Delete files slated for deletion.
    if (manifest.deletedFiles.isNotEmpty) {
      logger.printStatus('Deleting ${manifest.deletedFiles.length} files.', indent: 2);
    }
    for (final String localPath in manifest.deletedFiles) {
      final File targetFile = FlutterProject.current().directory.childFile(localPath);
      targetFile.deleteSync();
    }

    // Update the migrate config files to reflect latest migration.
    if (_verbose) {
      logger.printStatus('Updating .migrate_configs');
    }
    final FlutterProjectMetadata metadata = FlutterProjectMetadata(project.directory.childFile('.metadata'), logger);
    final FlutterVersion version = FlutterVersion(workingDirectory: project.directory.absolute.path);

    final String currentGitHash = version.frameworkRevision;
    metadata.migrateConfig.populate(
      projectDirectory: project.directory,
      currentRevision: currentGitHash,
      logger: logger,
    );

    // Clean up the working directory
    final bool keepWorkingDirectory = boolArg('keep-working-directory') ?? false;
    if (!keepWorkingDirectory) {
      stagingDirectory.deleteSync(recursive: true);
    }

    // Detect pub dependency locking. Run flutter pub upgrade --major-versions
    await updatePubspecDependencies(project, migrateUtils, logger, terminal);

    // Detect gradle lockfiles in android directory. Delete lockfiles and regenerate with ./gradlew tasks (any gradle task that requires a build).
    await updateGradleDependencyLocking(project, migrateUtils, logger, terminal, _verbose, fileSystem);

    logger.printStatus('Migration complete. You may use commands like `git '
                      'status`, `git diff` and `git restore <file>` to continue '
                      'working with the migrated files.');
    return const FlutterCommandResult(ExitStatus.success);
  }
}
