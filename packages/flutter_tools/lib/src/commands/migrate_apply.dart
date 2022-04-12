// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../migrate/migrate_manifest.dart';
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
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes. '
            'This path can be absolute or relative to the flutter project root.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Ignore unresolved merge conflicts and apply staged changes by force.',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  @override
  final String name = 'apply';

  @override
  final String description = r'Accepts the changes produced by `$ flutter migrate start` and copies the changed files into your project files. All merge conflicts should be resolved before apply will complete successfully. If conflicts still exist, this command will print the remaining conflicted files.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();

    if (!await gitRepoExists(flutterProject.directory.path, logger)) {
      logger.printStatus('No git repo found. Please run in a project with an initialized git repo or initialize one with:');
      MigrateUtils.printCommandText('git init', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final bool force = boolArg('force');

    Directory workingDirectory = flutterProject.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    final String? customWorkingDirectoryPath = stringArg('working-directory');
    if (customWorkingDirectoryPath != null) {
      if (customWorkingDirectoryPath.startsWith(fileSystem.path.separator) || customWorkingDirectoryPath.startsWith('/')) {
        // Is an absolute path
        workingDirectory = fileSystem.directory(customWorkingDirectoryPath);
      } else {
        workingDirectory = flutterProject.directory.childDirectory(customWorkingDirectoryPath);
      }
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Please run:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
    if (!checkAndPrintMigrateStatus(manifest, workingDirectory, warnConflict: true, logger: logger) && !force) {
      logger.printStatus('Conflicting files found. Resolve these conflicts and try again.');
      logger.printStatus('Guided conflict resolution wizard:');
      MigrateUtils.printCommandText('flutter migrate resolve-conflicts', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    if (await hasUncommittedChanges(flutterProject.directory.path, logger) && !force) {
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
      final File workingFile = workingDirectory.childFile(localPath);
      final File targetFile = flutterProject.directory.childFile(localPath);
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
    final FlutterProjectMetadata metadata = FlutterProjectMetadata(flutterProject.directory.childFile('.metadata'), logger);
    final FlutterVersion version = FlutterVersion(workingDirectory: flutterProject.directory.absolute.path);

    final String currentGitHash = version.frameworkRevision;
    metadata.migrateConfig.populate(
      projectDirectory: flutterProject.directory,
      currentRevision: currentGitHash,
      logger: logger,
    );

    // Clean up the working directory
    workingDirectory.deleteSync(recursive: true);

    // Detect pub dependency locking. Run flutter pub upgrade --major-versions
    updatePubspecDependencies(flutterProject);

    // Detect gradle lockfiles in android directory. Delete lockfiles and regenerate with ./gradlew tasks (any gradle task that requires a build).
    updateGradleDependencyLocking(flutterProject);

    logger.printStatus('Migration complete. You may use commands like `git status`, `git diff` and `git restore <file>` to continue working with the migrated files.');
    return const FlutterCommandResult(ExitStatus.success);
  }

  void updatePubspecDependencies(FlutterProject flutterProject) {
    final File pubspecFile = flutterProject.directory.childFile('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return;
    }
    if (!pubspecFile.readAsStringSync().contains('# THIS LINE IS AUTOGENERATED')) {
      return;
    }
    MigrateUtils.flutterPubUpgrade(flutterProject.directory.path);
  }

  void updateGradleDependencyLocking(FlutterProject flutterProject) {
    final List<FileSystemEntity> androidFiles = flutterProject.directory.childDirectory('android').listSync(recursive: false);
    bool foundLockfile = false;
    for (final FileSystemEntity entity in generatedBaseFiles) {
      if (entity is! File) {
        continue;
      }
      final File file = entity.absolute;
      try {
        if (file.readAsStringSync().startsWith('# This is a Gradle generated file for dependency locking.\n# Manual edits can break the build and are not advised.\n# This file is expected to be part of source control.')) {
          foundLockfile = true;
          break;
        }
      } on FileSystemException {
        if (_verbose) {
          logger.printStatus('Unable to check ${file.path}');
        }
      }
    }
    if (foundLockfile) {
      MigrateUtils.gradlewTasks();
    }
  }
}
