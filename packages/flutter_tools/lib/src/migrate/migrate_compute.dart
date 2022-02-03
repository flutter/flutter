// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../cache.dart';
import '../commands/migrate.dart';
import 'migrate_config.dart';
import 'migrate_manifest.dart';
import 'migrate_utils.dart';

class FilePendingMigration {
  FilePendingMigration(this.localPath, this.file);
  String localPath;
  File file;
}

class MigrateResult {
  MigrateResult({
    required this.mergeResults,
    required this.addedFiles,
    required this.deletedFiles,
    required this.tempDirectories});

  MigrateResult.empty()
    : mergeResults = <MergeResult>[],
      addedFiles = <FilePendingMigration>[],
      deletedFiles = <FilePendingMigration>[],
      tempDirectories = <Directory>[];

  List<MergeResult> mergeResults;
  List<FilePendingMigration> addedFiles;
  List<FilePendingMigration> deletedFiles;
  List<Directory> tempDirectories;
}

Future<MigrateResult?> computeMigration({
    bool verbose = false,
    String? baseAppDirectory,
    String? targetAppDirectory,
    String? baseRevision,
    String? targetRevision,
    bool deleteTempDirectories = true,
    Logger? logger,
  }) async {
  if (logger == null) {
    logger = globals.logger;
  }
  final Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
  if (workingDir.existsSync()) {
    logger.printStatus('Old migration already in progress.', emphasis: true);
    logger.printStatus('Pending migration files exist in `<your_project_root_dir>/$kDefaultMigrateWorkingDirectoryName`');
    logger.printStatus('Resolve merge conflicts and accept changes with by running:\n');
    logger.printStatus('\$ flutter migrate apply\n', color: TerminalColor.grey, indent: 4);
    logger.printStatus('You may also abandon the existing migration and start a new one with:\n');
    logger.printStatus('\$ flutter migrate abandon', color: TerminalColor.grey, indent: 4);
    return null;
  }
  final FlutterProject flutterProject = FlutterProject.current();

  final List<MigrateConfig> configs = await MigrateConfig.parseOrCreateMigrateConfigs(create: false);

  // TODO: implement no-base-revision migrate in case no fallback can be found.
  final String fallbackRevision = await MigrateConfig.getFallbackLastMigrateVersion();
  String rootBaseRevision = '';
  Map<String, List<MigrateConfig>> revisionToConfigs = <String, List<MigrateConfig>>{};
  Set<String> revisions = Set<String>();
  if (baseRevision == null) {
    for (MigrateConfig config in configs) {
      String effectiveRevision = config.lastMigrateVersion == null ? fallbackRevision : config.lastMigrateVersion!;
      if (config.platform == 'root') {
        rootBaseRevision = effectiveRevision;
      }
      revisions.add(effectiveRevision);
      if (revisionToConfigs[effectiveRevision] == null) {
        revisionToConfigs[effectiveRevision] = <MigrateConfig>[];
      }
      revisionToConfigs[effectiveRevision]!.add(config);
    }
  } else {
    rootBaseRevision = baseRevision;
  }
  // Reorder such that the root revision is created first.
  revisions.remove(rootBaseRevision);
  List<String> revisionsList = List<String>.from(revisions);
  if (rootBaseRevision != '') {
    revisionsList.insert(0, rootBaseRevision);
  }

  print('falback: $fallbackRevision');
  print('$revisionsList');

  // Extract the files/paths that should be ignored by the migrate tool.
  // These paths are absolute paths.
  List<String> unmanagedFiles = <String>[];
  List<String> unmanagedDirectories = <String>[];
  for (MigrateConfig config in configs) {
    final basePath = config.getBasePath(flutterProject.directory);
    for (String localPath in config.unmanagedFiles) {
      if (localPath.endsWith(globals.fs.path.separator)) {
        unmanagedDirectories.add(globals.fs.path.join(basePath, localPath));
      } else {
        unmanagedFiles.add(globals.fs.path.join(basePath, localPath));
      }
    }
  }

  // Generate the base templates
  Directory generatedBaseTemplateDirectory;
  Directory generatedTargetTemplateDirectory;

  final bool customBaseAppDir = baseAppDirectory != null;
  final bool customTargetAppDir = targetAppDirectory != null;
  if (customBaseAppDir) {
    generatedBaseTemplateDirectory = globals.fs.directory(baseAppDirectory!);
  } else {
    generatedBaseTemplateDirectory = await MigrateUtils.createTempDirectory('generatedOldTemplate');
  }
  if (customTargetAppDir) {
    generatedTargetTemplateDirectory = globals.fs.directory(targetAppDirectory!);
  } else {
    generatedTargetTemplateDirectory = await MigrateUtils.createTempDirectory('generatedNewTemplate');
  }

  await MigrateUtils.gitInit(generatedBaseTemplateDirectory.absolute.path);
  await MigrateUtils.gitInit(generatedTargetTemplateDirectory.absolute.path);

  // Create base
  final String name = flutterProject.manifest.appName;
  final String androidLanguage = FlutterProject.current().android.isKotlin ? 'kotlin' : 'java';
  final String iosLanguage = FlutterProject.current().ios.isSwift ? 'swift' : 'objc';

  Directory targetFlutterBinDirectory = globals.fs.directory(globals.fs.path.join(Cache.flutterRoot!, 'bin'));
  // Clone base flutter
  if (baseAppDirectory == null) {
    final Map<String, Directory> revisionToFlutterSdkDir = <String, Directory>{};
    for (String revision in revisionsList) {
      Directory sdkDir = await MigrateUtils.createTempDirectory('flutter_$revision')!;
      revisionToFlutterSdkDir[revision] = sdkDir;
      final List<String> platforms = <String>[];
      for (MigrateConfig config in revisionToConfigs[revision]!) {
        platforms.add(config.platform!);
      }
      platforms.remove('root'); // Root does not need to be listed and is not a valid platform

      // In the case of the revision being invalid or not a hash of the master branch,
      // we want to fallback in the following order:
      //   - parsed revision
      //   - fallback revision
      //   - target revision (currently installed flutter)
      List<String> revisionsToTry = <String>[revision];
      if (revision != fallbackRevision) {
        revisionsToTry.add(fallbackRevision);
      }
      bool sdkAvailable = false;
      int index = 0;
      do {
        if (index < revisionsToTry.length) {
          final String activeRevision = revisionsToTry[index++];
          if (activeRevision != revision && revisionToFlutterSdkDir.containsKey(activeRevision)) {
            sdkDir = revisionToFlutterSdkDir[activeRevision]!;
            revisionToFlutterSdkDir[revision] = sdkDir;
            sdkAvailable = true;
          } else {
            sdkAvailable = await MigrateUtils.cloneFlutter(activeRevision, sdkDir.absolute.path);
          }
        } else {
          // fallback to just using the modern target version of flutter.
          sdkDir = targetFlutterBinDirectory;
          sdkAvailable = true;
        }
      } while (!sdkAvailable);
      await MigrateUtils.createFromTemplates(
        sdkDir.childDirectory('bin').absolute.path,
        name: name,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: generatedBaseTemplateDirectory.absolute.path,
        platforms: platforms,
      );
    }
  }

  if (targetAppDirectory == null) {
    // Create target
    await MigrateUtils.createFromTemplates(
      targetFlutterBinDirectory.path,
      name: name,
      androidLanguage: androidLanguage,
      iosLanguage: iosLanguage,
      outputDirectory: generatedTargetTemplateDirectory.absolute.path
    );
  }

  await MigrateUtils.gitInit(flutterProject.directory.absolute.path);

  // Generate diffs
  final List<FileSystemEntity> generatedBaseFiles = generatedBaseTemplateDirectory.listSync(recursive: true);
  final List<FileSystemEntity> generatedTargetFiles = generatedTargetTemplateDirectory.listSync(recursive: true);

  final Map<String, DiffResult> diffMap = <String, DiffResult>{};
  for (FileSystemEntity entity in generatedBaseFiles) {
    if (entity is! File) {
      continue;
    }
    final File oldTemplateFile = (entity as File).absolute;
    if (!oldTemplateFile.path.startsWith(generatedBaseTemplateDirectory.absolute.path)) {
      continue;
    }
    final String localPath = oldTemplateFile.path.replaceFirst(generatedBaseTemplateDirectory.absolute.path + globals.fs.path.separator, '');
    if (await MigrateUtils.isGitIgnored(oldTemplateFile.absolute.path, generatedBaseTemplateDirectory.absolute.path)) {
      diffMap[localPath] = DiffResult.ignored();
    }
    final File targetTemplateFile = generatedTargetTemplateDirectory.childFile(localPath);
    if (targetTemplateFile.existsSync()) {
      DiffResult diff = await MigrateUtils.diffFiles(oldTemplateFile, targetTemplateFile);
      diffMap[localPath] = diff;
    } else {
      // Current file has no new template counterpart, which is equivalent to a deletion.
      // This could also indicate a renaming if there is an addition with equivalent contents.
      diffMap[localPath] = DiffResult.deletion();
    }
  }

  MigrateResult migrateResult = MigrateResult.empty();

  // Check for any new files that were added in the new template
  for (FileSystemEntity entity in generatedTargetFiles) {
    if (entity is! File) {
      continue;
    }
    final File targetTemplateFile = (entity as File).absolute;
    if (!targetTemplateFile.path.startsWith(generatedTargetTemplateDirectory.absolute.path)) {
      continue;
    }
    String localPath = targetTemplateFile.path.replaceFirst(generatedTargetTemplateDirectory.absolute.path + globals.fs.path.separator, '');
    if (diffMap.containsKey(localPath)) {
      continue;
    }
    if (await MigrateUtils.isGitIgnored(targetTemplateFile.absolute.path, generatedTargetTemplateDirectory.absolute.path)) {
      diffMap[localPath] = DiffResult.ignored();
    }
    diffMap[localPath] = DiffResult.addition();
    migrateResult.addedFiles.add(FilePendingMigration(localPath, targetTemplateFile));
  }

  // for each file
  final List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
  final String projectRootPath = flutterProject.directory.absolute.path;
  for (FileSystemEntity entity in currentFiles) {
    if (entity is! File) {
      continue;
    }
    // check if the file is unmanaged/ignored by the migration tool.
    bool ignored = false;
    ignored = unmanagedFiles.contains(entity.absolute.path);
    for (String path in unmanagedDirectories) {
      if (entity.absolute.path.startsWith(path)) {
        ignored = true;
        break;
      }
    }
    if (ignored) {
      continue; // Skip if marked as unmanaged
    }

    final File currentFile = (entity as File).absolute;
    if (!currentFile.path.startsWith(projectRootPath)) {
      continue; // Not a project file.
    }
    // Diff the current file against the old generated template
    final String localPath = currentFile.path.replaceFirst(projectRootPath + globals.fs.path.separator, '');
    if (diffMap.containsKey(localPath) && diffMap[localPath]!.isIgnored || await MigrateUtils.isGitIgnored(currentFile.path, flutterProject.directory.absolute.path)) {
      continue;
    }
    final File oldTemplateFile = generatedBaseTemplateDirectory.childFile(localPath);
    final DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

    if (userDiff.exitCode == 0) {
      // Current file unchanged by user
      if (diffMap.containsKey(localPath) && diffMap[localPath]!.isDeletion) {
        // File is deleted in new template
        migrateResult.deletedFiles.add(FilePendingMigration(localPath, currentFile));
      }
      continue;
    }

    if (diffMap.containsKey(localPath)) {
      final MergeResult result = await MigrateUtils.gitMergeFile(
        ancestor: globals.fs.path.join(generatedBaseTemplateDirectory.path, localPath),
        current: currentFile.path,
        other: globals.fs.path.join(generatedTargetTemplateDirectory.path, localPath),
        localPath: localPath,
      );
      migrateResult.mergeResults.add(result);
      continue;
    }
  }

  if (deleteTempDirectories) {
    List<Directory> directoriesToDelete = <Directory>[];
    // Don't delete user-provided directories
    if (!customBaseAppDir) {
      migrateResult.tempDirectories.add(generatedBaseTemplateDirectory);
    }
    if (!customTargetAppDir) {
      migrateResult.tempDirectories.add(generatedTargetTemplateDirectory);
    }
  }
  return migrateResult;
}

Future<void> writeWorkingDir(MigrateResult migrateResult, {bool verbose = false}) async {
  final Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
  if (verbose) globals.logger.printStatus('Writing migrate working directory at `${workingDir.path}`');
  // Write files in working dir
  for (MergeResult result in migrateResult.mergeResults) {
    final File file = workingDir.childFile(result.localPath);
    file.createSync(recursive: true);
    file.writeAsStringSync(result.mergedContents, flush: true);
  }

  for (FilePendingMigration addedFile in migrateResult.addedFiles) {
    final File file = workingDir.childFile(addedFile.localPath);
    file.createSync(recursive: true);
    try {
      file.writeAsStringSync(addedFile.file.readAsStringSync(), flush: true);
    } on FileSystemException {
      file.writeAsBytesSync(addedFile.file.readAsBytesSync(), flush: true);
    }
  }

  final MigrateManifest manifest = MigrateManifest(
    migrateRootDir: workingDir,
    migrateResult: migrateResult,
  );
  manifest.writeFile();
}

