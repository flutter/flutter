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
      help: 'Ignore unresolved merge conflicts and apply staged changes by force.',
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
  final String description = r'Accepts the changes produced by `$ flutter migrate start` and copies the changed files into your project files. All merge conflicts should be resolved before apply will complete successfully. If conflicts still exist, this command will print the remaining conflicted files.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? projectDirectory = stringArg('project-directory');
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null ? FlutterProject.current() : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));

    if (!await gitRepoExists(project.directory.path, logger, migrateUtils)) {
      logger.printStatus('No git repo found. Please run in a project with an initialized git repo or initialize one with:');
      printCommandText('git init', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final bool force = boolArg('force') ?? false;

    terminal.usesTerminalUi = true;

    Directory workingDirectory = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    final String? customWorkingDirectoryPath = stringArg('working-directory');
    if (customWorkingDirectoryPath != null) {
      if (customWorkingDirectoryPath.startsWith(fileSystem.path.separator) || customWorkingDirectoryPath.startsWith(RegExp(r'[A-Z]:\\'))) {
        // Is an absolute path
        workingDirectory = fileSystem.directory(customWorkingDirectoryPath);
      } else {
        workingDirectory = project.directory.childDirectory(customWorkingDirectoryPath);
      }
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Please run:');
      printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
    if (!checkAndPrintMigrateStatus(manifest, workingDirectory, warnConflict: true, logger: logger) && !force) {
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
      final File workingFile = workingDirectory.childFile(localPath);
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
      workingDirectory.deleteSync(recursive: true);
    }

    // Detect pub dependency locking. Run flutter pub upgrade --major-versions
    await updatePubspecDependencies(project);

    // Detect gradle lockfiles in android directory. Delete lockfiles and regenerate with ./gradlew tasks (any gradle task that requires a build).
    await updateGradleDependencyLocking(project);

    logger.printStatus('Migration complete. You may use commands like `git status`, `git diff` and `git restore <file>` to continue working with the migrated files.');
    return const FlutterCommandResult(ExitStatus.success);
  }

  /// Checks if the project uses pubspec dependency locking and prompts if
  /// the pub upgrade should be run.
  Future<void> updatePubspecDependencies(FlutterProject project) async {
    final File pubspecFile = project.directory.childFile('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return;
    }
    if (!pubspecFile.readAsStringSync().contains('# THIS LINE IS AUTOGENERATED')) {
      return;
    }
    logger.printStatus('\nDart dependency locking detected in pubspec.yaml.');
    String selection = 'y';
    try {
      selection = await terminal.promptForCharInput(
        <String>['y', 'n'],
        logger: logger,
        prompt: 'Do you want the tool to run `flutter pub upgrade --major-versions`? (y)es, (n)o',
        defaultChoiceIndex: 1,
      );
    } on StateError catch(e) {
      logger.printError(
        e.message,
        indent: 0,
      );
    }
    if (selection == 'y') {
      // Runs `flutter pub upgrade --major-versions`
      await migrateUtils.flutterPubUpgrade(project.directory.path);
    }
  }

  /// Checks if gradle dependency locking is used and prompts the developer to
  /// remove and back up the gradle dependenc lockfile.
  Future<void> updateGradleDependencyLocking(FlutterProject flutterProject) async {
    final Directory androidDir = flutterProject.directory.childDirectory('android');
    if (!androidDir.existsSync()) {
      return;
    }
    final List<FileSystemEntity> androidFiles = androidDir.listSync();
    final List<File> lockfiles = <File>[];
    final List<String> backedUpFilePaths = <String>[];
    for (final FileSystemEntity entity in androidFiles) {
      if (entity is! File) {
        continue;
      }
      final File file = entity.absolute;
      // Don't re-handle backed up lockfiles.
      if (file.path.contains('_backup_')) {
        continue;
      }
      try {
        // lockfiles generated by gradle start with this prefix.
        if (file.readAsStringSync().startsWith('# This is a Gradle generated file for dependency locking.\n# Manual edits can break the build and are not advised.\n# This file is expected to be part of source control.')) {
          lockfiles.add(file);
        }
      } on FileSystemException {
        if (_verbose) {
          logger.printStatus('Unable to check ${file.path}');
        }
      }
    }
    if (lockfiles.isNotEmpty) {
      logger.printStatus('\nGradle dependency locking detected.');
      logger.printStatus('Flutter can backup the lockfiles and regenerate updated lockfiles.');
      String selection = 'y';
      try {
        selection = await terminal.promptForCharInput(
          <String>['y', 'n'],
          logger: logger,
          prompt: 'Do you want the tool to update locked dependencies? (y)es, (n)o',
          defaultChoiceIndex: 1,
        );
      } on StateError catch(e) {
        logger.printError(
          e.message,
          indent: 0,
        );
      }
      if (selection == 'y') {
        for (final File file in lockfiles) {
          int counter = 0;
          while (true) {
            final String newPath = '${file.absolute.path}_backup_$counter';
            if (!fileSystem.file(newPath).existsSync()) {
              file.renameSync(newPath);
              backedUpFilePaths.add(newPath);
              break;
            } else {
              counter++;
            }
          }
        }
        // Runs `./gradelw tasks`in the project's android directory.
        await migrateUtils.gradlewTasks(flutterProject.directory.childDirectory('android').path);
        logger.printStatus('Old lockfiles renamed to:');
        for (final String path in backedUpFilePaths) {
          logger.printStatus(path, color: TerminalColor.grey, indent: 2);
        }
      }
    }
  }
}
