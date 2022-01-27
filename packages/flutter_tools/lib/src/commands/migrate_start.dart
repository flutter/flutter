// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate.dart';

class MigrateStartCommand extends FlutterCommand {
  MigrateStartCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
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
      'old-app-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addOption(
      'new-app-directory',
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
  }

  final bool _verbose;

  @override
  final String name = 'start';

  @override
  final String description = '';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (workingDir.existsSync()) {
      print('Old migration already in progress. Pending migration files exist in `<your_project_root_dir>/$kDefaultMigrateWorkingDirectoryName`');
      print('Resolve merge conflicts and accept changes with by running:\n');
      print('    \$ flutter migrate apply\n');
      print('Pending migration files exist in `<your_project_root_dir>/$kDefaultMigrateWorkingDirectoryName`\n');
      print('You may also abandon the existing migration and start a new one with:\n');
      print('    \$ flutter migrate abandon');
      return const FlutterCommandResult(ExitStatus.fail);
    }
    final FlutterProject flutterProject = FlutterProject.current();

    final List<MigrateConfig> configs = await MigrateConfig.parseOrCreateMigrateConfigs();

    String rootBaseRevision = '';
    final String fallbackRevision = await MigrateConfig.getFallbackLastMigrateVersion();
    Map<String, List<MigrateConfig>> revisionToConfigs = <String, List<MigrateConfig>>{};
    Set<String> revisions = Set<String>();
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

    // Generate the old templates
    Directory generatedOldTemplateDirectory;
    Directory generatedNewTemplateDirectory;

    final bool customOldAppDir = stringArg('old-app-directory') != null;
    final bool customNewAppDir = stringArg('new-app-directory') != null;
    if (customOldAppDir) {
      generatedOldTemplateDirectory = globals.fs.directory(stringArg('old-app-directory')!);
    } else {
      generatedOldTemplateDirectory = await MigrateUtils.createTempDirectory('generatedOldTemplate');
    }
    if (customNewAppDir) {
      generatedNewTemplateDirectory = globals.fs.directory(stringArg('new-app-directory')!);
    } else {
      generatedNewTemplateDirectory = await MigrateUtils.createTempDirectory('generatedNewTemplate');
    }

    await MigrateUtils.gitInit(generatedOldTemplateDirectory.absolute.path);
    await MigrateUtils.gitInit(generatedNewTemplateDirectory.absolute.path);

    // // Create old
    final String name = flutterProject.manifest.appName;
    final String androidLanguage = FlutterProject.current().android.isKotlin ? 'kotlin' : 'java';
    final String iosLanguage = FlutterProject.current().ios.isSwift ? 'swift' : 'objc';
    // // Clone old flutter
    if (stringArg('old-app-directory') == null) {
      final Map<String, Directory> revisionToFlutterSdkDir = <String, Directory>{};
      for (String revision in revisions) {
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
          outputDirectory: generatedOldTemplateDirectory.absolute.path,
          platforms: platforms,
        );
      }
    }

    if (stringArg('new-app-directory') == null) {
      // Create new
      await MigrateUtils.createFromTemplates(
        globals.fs.path.join(Cache.flutterRoot!, 'bin'),
        name: name,
        androidLanguage: androidLanguage,
        iosLanguage: iosLanguage,
        outputDirectory: generatedNewTemplateDirectory.absolute.path
      );
    }

    // Generate diffs
    final List<FileSystemEntity> generatedOldFiles = generatedOldTemplateDirectory.listSync(recursive: true);
    final List<FileSystemEntity> generatedNewFiles = generatedNewTemplateDirectory.listSync(recursive: true);

    final Map<String, DiffResult> diffMap = <String, DiffResult>{};
    for (FileSystemEntity entity in generatedOldFiles) {
      // print(entity.path);
      if (entity is! File) {
        continue;
      }
      final File oldTemplateFile = (entity as File).absolute;
      if (!oldTemplateFile.path.startsWith(generatedOldTemplateDirectory.absolute.path)) {
        continue;
      }
      final String localPath = oldTemplateFile.path.replaceFirst(generatedOldTemplateDirectory.absolute.path + globals.fs.path.separator, '');
      if (await MigrateUtils.isGitIgnored(oldTemplateFile.absolute.path, generatedOldTemplateDirectory.absolute.path)) {
        diffMap[localPath] = DiffResult.ignored();
      }
      final File newTemplateFile = generatedNewTemplateDirectory.childFile(localPath);
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

    // Check for any new files that were added in the new template
    Map<String, File> additionalFiles = <String, File>{};
    for (FileSystemEntity entity in generatedNewFiles) {
      if (entity is! File) {
        continue;
      }
      final File newTemplateFile = (entity as File).absolute;
      if (!newTemplateFile.path.startsWith(generatedNewTemplateDirectory.absolute.path)) {
        continue;
      }
      String localPath = newTemplateFile.path.replaceFirst(generatedNewTemplateDirectory.absolute.path + globals.fs.path.separator, '');
      if (diffMap.containsKey(localPath)) {
        continue;
      }
      if (await MigrateUtils.isGitIgnored(newTemplateFile.absolute.path, generatedNewTemplateDirectory.absolute.path)) {
        diffMap[localPath] = DiffResult.ignored();
      }
      diffMap[localPath] = DiffResult.addition();
      additionalFiles[localPath] = newTemplateFile;
    }

    // for each file
    final List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
    final String projectRootPath = flutterProject.directory.absolute.path;
    final Map<String, MergeResult> mergeResults = <String, MergeResult>{};
    final Map<String, File> deletedFiles = <String, File>{};
    for (FileSystemEntity entity in currentFiles) {
      if (entity is! File) {
        continue;
      }
      final File currentFile = (entity as File).absolute;
      // print('Checking ${currentFile.path}');
      if (!currentFile.path.startsWith(projectRootPath)) {
        continue; // Not a project file.
      }
      // Diff the current file against the old generated template
      final String localPath = currentFile.path.replaceFirst(projectRootPath + globals.fs.path.separator, '');
      if (diffMap.containsKey(localPath) && diffMap[localPath]!.isIgnored || await MigrateUtils.isGitIgnored(currentFile.path, flutterProject.directory.absolute.path)) {
        // print('  File git ignored');
        continue;
      }
      final File oldTemplateFile = generatedOldTemplateDirectory.childFile(localPath);
      final DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

      if (userDiff.exitCode == 0) {
        // Current file unchanged by user
        // print('  File unchanged');
        if (diffMap.containsKey(localPath) && diffMap[localPath]!.isDeletion) { // File is deleted in new template
          // print('    DELETING');
          // currentFile.deleteSync();
          deletedFiles[localPath] = currentFile;
        }
        continue;
      }

      if (diffMap.containsKey(localPath)) {
        final MergeResult result = await MigrateUtils.gitMergeFile(
          ancestor: globals.fs.path.join(generatedOldTemplateDirectory.path, localPath),
          current: currentFile.path,
          other: globals.fs.path.join(generatedNewTemplateDirectory.path, localPath),
        );
        print('Merged ${currentFile.path} with ${result.exitCode} conflicts');
        // print(result.mergedContents);
        mergeResults[localPath] = result;
        continue;
      }
      print('  File unhandled');
    }

    // Write files in working dir
    for (String localPath in mergeResults.keys) {
      final MergeResult result = mergeResults[localPath]!;
      final File file = workingDir.childFile(localPath);
      file.createSync(recursive: true);
      file.writeAsStringSync(result.mergedContents, flush: true);
      print('  Wrote merged file $localPath');
    }

    for (String localPath in additionalFiles.keys) {
      final File additionalFile = additionalFiles[localPath]!;
      final File file = workingDir.childFile(localPath);
      file.createSync(recursive: true);
      file.writeAsStringSync(additionalFile.readAsStringSync(), flush: true);
      print('  Wrote Additional file $localPath');
    }

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, mergeResults: mergeResults, additionalFiles: additionalFiles, deletedFiles: deletedFiles);
    manifest.writeFile();

    if (boolArg('delete-temp-directories')) {
      List<Directory> directoriesToDelete = <Directory>[];
      // Don't delete user-provided directories
      if (!customOldAppDir) {
        directoriesToDelete.add(generatedOldTemplateDirectory);
      }
      if (!customNewAppDir) {
        directoriesToDelete.add(generatedNewTemplateDirectory);
      }
      MigrateUtils.deleteTempDirectories(
        paths: <String>[],
        directories: directoriesToDelete,
      );
    }
    return const FlutterCommandResult(ExitStatus.success);
  }
}
