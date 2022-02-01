// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
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
    required this.deletedFiles});

  MigrateResult.empty()
    : mergeResults = <MergeResult>[],
      addedFiles = <FilePendingMigration>[],
      deletedFiles = <FilePendingMigration>[];


  List<MergeResult> mergeResults;
  List<FilePendingMigration> addedFiles;
  List<FilePendingMigration> deletedFiles;
}

Future<MigrateResult?> generateMigration({
    bool verbose = false,
    String? baseAppDirectory,
    String? targetAppDirectory,
    String? baseRevision,
    String? targetRevision,
    bool deleteTempDirectories = true,
  }) async {
  final Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
  if (workingDir.existsSync()) {
    print('Old migration already in progress. Pending migration files exist in `<your_project_root_dir>/$kDefaultMigrateWorkingDirectoryName`');
    print('Resolve merge conflicts and accept changes with by running:\n');
    print('    \$ flutter migrate apply\n');
    print('Pending migration files exist in `<your_project_root_dir>/$kDefaultMigrateWorkingDirectoryName`\n');
    print('You may also abandon the existing migration and start a new one with:\n');
    print('    \$ flutter migrate abandon');
    return null;
  }
  final FlutterProject flutterProject = FlutterProject.current();

  final List<MigrateConfig> configs = await MigrateConfig.parseOrCreateMigrateConfigs();

  String rootBaseRevision = '';
  final String fallbackRevision = await MigrateConfig.getFallbackLastMigrateVersion();
  Map<String, List<MigrateConfig>> revisionToConfigs = <String, List<MigrateConfig>>{};
  Set<String> revisions = Set<String>();
  if (baseRevision == null) {
    for (MigrateConfig config in configs) {
      String effectiveRevision = config.lastMigrateVersion == null ? fallbackRevision : config.lastMigrateVersion!;
      print('effectiveRevision: $effectiveRevision');
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
  revisionsList.insert(0, rootBaseRevision);

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
  // Clone base flutter
  if (baseAppDirectory == null) {
    final Map<String, Directory> revisionToFlutterSdkDir = <String, Directory>{};
    for (String revision in revisionsList) {
      final Directory sdkDir = await MigrateUtils.createTempDirectory('flutter_$revision');
      revisionToFlutterSdkDir[revision] = sdkDir;
      final List<String> platforms = <String>[];
      for (MigrateConfig config in revisionToConfigs[revision]!) {
        platforms.add(config.platform!);
      }
      platforms.remove('root'); // Root does not need to be listed and is not a valid platform
      await MigrateUtils.cloneFlutter(revision, sdkDir.absolute.path);
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
      globals.fs.path.join(Cache.flutterRoot!, 'bin'),
      name: name,
      androidLanguage: androidLanguage,
      iosLanguage: iosLanguage,
      outputDirectory: generatedTargetTemplateDirectory.absolute.path
    );
  }

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
    final File newTemplateFile = generatedTargetTemplateDirectory.childFile(localPath);
    // print('  Comparing to new template: ${newTemplateFile.path}');
    if (newTemplateFile.existsSync()) {
      DiffResult diff = await MigrateUtils.diffFiles(oldTemplateFile, newTemplateFile);
      diffMap[localPath] = diff;
      // print(diff.diff);
    } else {
      // Current file has no new template counterpart, which is equivalent to a deletion.
      // This could also indicate a renaming if there is an addition with equivalent contents.
      diffMap[localPath] = DiffResult.deletion();
    }
  }

  MigrateResult migrateResult = MigrateResult.empty();

  // Check for any new files that were added in the new template
  // Map<String, File> additionalFiles = <String, File>{};
  for (FileSystemEntity entity in generatedTargetFiles) {
    if (entity is! File) {
      continue;
    }
    final File newTemplateFile = (entity as File).absolute;
    if (!newTemplateFile.path.startsWith(generatedTargetTemplateDirectory.absolute.path)) {
      continue;
    }
    String localPath = newTemplateFile.path.replaceFirst(generatedTargetTemplateDirectory.absolute.path + globals.fs.path.separator, '');
    if (diffMap.containsKey(localPath)) {
      continue;
    }
    if (await MigrateUtils.isGitIgnored(newTemplateFile.absolute.path, generatedTargetTemplateDirectory.absolute.path)) {
      diffMap[localPath] = DiffResult.ignored();
    }
    diffMap[localPath] = DiffResult.addition();
    migrateResult.addedFiles.add(FilePendingMigration(localPath, newTemplateFile));
    // additionalFiles[localPath] = newTemplateFile;
  }

  // for each file
  final List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
  final String projectRootPath = flutterProject.directory.absolute.path;
  // final Map<String, MergeResult> mergeResults = <String, MergeResult>{};
  // final Map<String, File> deletedFiles = <String, File>{};
  for (FileSystemEntity entity in currentFiles) {
    if (entity is! File) {
      continue;
    }
    final File currentFile = (entity as File).absolute;
    if (!currentFile.path.startsWith(projectRootPath)) {
      continue; // Not a project file.
    }
    // Diff the current file against the old generated template
    final String localPath = currentFile.path.replaceFirst(projectRootPath + globals.fs.path.separator, '');
    if (diffMap.containsKey(localPath) && diffMap[localPath]!.isIgnored || await MigrateUtils.isGitIgnored(currentFile.path, flutterProject.directory.absolute.path)) {
      // print('  File git ignored');
      continue;
    }
    final File oldTemplateFile = generatedBaseTemplateDirectory.childFile(localPath);
    final DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

    if (userDiff.exitCode == 0) {
      // Current file unchanged by user
      if (diffMap.containsKey(localPath) && diffMap[localPath]!.isDeletion) {
        // File is deleted in new template
        migrateResult.deletedFiles.add(FilePendingMigration(localPath, currentFile));
        // deletedFiles[localPath] = currentFile;
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
      print('Merged ${currentFile.path} with ${result.exitCode} conflicts');
      migrateResult.mergeResults.add(result);
      // mergeResults[localPath] = result;
      continue;
    }
  }

  // Write files in working dir
  for (MergeResult result in migrateResult.mergeResults) {
    final File file = workingDir.childFile(result.localPath);
    file.createSync(recursive: true);
    file.writeAsStringSync(result.mergedContents, flush: true);
  }

  for (FilePendingMigration addedFile in migrateResult.addedFiles) {
    final File file = workingDir.childFile(addedFile.localPath);
    file.createSync(recursive: true);
    file.writeAsStringSync(addedFile.file.readAsStringSync(), flush: true);
  }

  final MigrateManifest manifest = MigrateManifest(
    migrateRootDir: workingDir,
    migrateResult: migrateResult,
  );
  manifest.writeFile();

  if (deleteTempDirectories) {
    List<Directory> directoriesToDelete = <Directory>[];
    // Don't delete user-provided directories
    if (!customBaseAppDir) {
      directoriesToDelete.add(generatedBaseTemplateDirectory);
    }
    if (!customTargetAppDir) {
      directoriesToDelete.add(generatedTargetTemplateDirectory);
    }
    MigrateUtils.deleteTempDirectories(
      paths: <String>[],
      directories: directoriesToDelete,
    );
  }
  return migrateResult;
}

