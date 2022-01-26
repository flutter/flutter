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
    Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
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

    List<MigrateConfig> configs = await MigrateConfig.parseOrCreateMigrateConfigs();

    String rootBaseRevision = '';
    String fallbackRevision = await MigrateConfig.getFallbackLastMigrateVersion();
    Map<String, List<MigrateConfig>> revisionToConfigs = <String, List<MigrateConfig>>{};
    Set<String> revisions = Set<String>();
    for (MigrateConfig config in configs) {
      print(config.lastMigrateVersion);
      print(fallbackRevision);
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

    String revision = '18116933e77adc82f80866c928266a5b4f1ed645';

    // Generate the old templates
    Directory generatedOldTemplateDirectory;
    Directory generatedNewTemplateDirectory;
    if (stringArg('old-app-directory') != null) {
      generatedOldTemplateDirectory = globals.fs.directory(stringArg('old-app-directory')!);
    } else {
      generatedOldTemplateDirectory = await MigrateUtils.createTempDirectory('generatedOldTemplate');
    }
    if (stringArg('new-app-directory') != null) {
      generatedNewTemplateDirectory = globals.fs.directory(stringArg('new-app-directory')!);
    } else {
      generatedNewTemplateDirectory = await MigrateUtils.createTempDirectory('generatedNewTemplate');
    }
    Directory oldFlutterRoot;

    await MigrateUtils.gitInit(generatedOldTemplateDirectory.absolute.path);
    await MigrateUtils.gitInit(generatedNewTemplateDirectory.absolute.path);

    // /var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generatedOldTemplate.XmklMKhV
    // /var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generatedNewTemplate.r9TzOOvh
    // Directory generatedOldTemplateDirectory = globals.fs.directory('/var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generatedOldTemplate.j8Tto95k');
    // Directory generatedNewTemplateDirectory = globals.fs.directory('/var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generateNewTemplate.0f4evU9N');
    // Directory oldFlutterRoot = globals.fs.directory();


    // // Create old
    String name = flutterProject.manifest.appName;
    String androidLanguage = FlutterProject.current().android.isKotlin ? 'kotlin' : 'java';
    String iosLanguage = FlutterProject.current().ios.isSwift ? 'swift' : 'objc';
    // // Clone old flutter
    if (stringArg('old-app-directory') == null) {
      Map<String, Directory> revisionToFlutterSdkDir = <String, Directory>{};
      for (String revision in revisions) {
        Directory sdkDir = await MigrateUtils.createTempDirectory('flutter_$revision');
        revisionToFlutterSdkDir[revision] = sdkDir;
        List<String> platforms = <String>[];
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
    List<FileSystemEntity> generatedOldFiles = generatedOldTemplateDirectory.listSync(recursive: true);
    List<FileSystemEntity> generatedNewFiles = generatedNewTemplateDirectory.listSync(recursive: true);

    Map<String, DiffResult> diffMap = <String, DiffResult>{};
    for (FileSystemEntity entity in generatedOldFiles) {
      // print(entity.path);
      if (entity is! File) {
        continue;
      }
      File oldTemplateFile = (entity as File).absolute;
      if (!oldTemplateFile.path.startsWith(generatedOldTemplateDirectory.absolute.path)) {
        continue;
      }
      String localPath = oldTemplateFile.path.replaceFirst(generatedOldTemplateDirectory.absolute.path + globals.fs.path.separator, '');
      if (await MigrateUtils.isGitIgnored(oldTemplateFile.absolute.path, generatedOldTemplateDirectory.absolute.path)) {
        diffMap[localPath] = DiffResult.ignored();
      }
      File newTemplateFile = generatedNewTemplateDirectory.childFile(localPath);
      // print('  Comparing to new template: ${newTemplateFile.path}');
      if (newTemplateFile.existsSync()) {
        DiffResult diff = await MigrateUtils.diffFiles(oldTemplateFile, newTemplateFile);
        diffMap[localPath] = diff;
        // print(diff.diff);
      } else {
        // print('else');
        // Current file has no new template counterpart, which is equivalent to a deletion.
        // This could also indicate a renaming if there is an addition with equivalent contents.
        diffMap[localPath] = DiffResult.deletion();
      }
    }

    // Check for any new files that were added in the new template
    Map<String, File> additionalFiles = <String, File>{};
    for (FileSystemEntity entity in generatedNewFiles) {
      print(entity.path);
      if (entity is! File) {
        continue;
      }
      File newTemplateFile = (entity as File).absolute;
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
      // print('  Addition');
      diffMap[localPath] = DiffResult.addition();
      additionalFiles[localPath] = newTemplateFile;
    }

    // for each file
    List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
    String projectRootPath = flutterProject.directory.absolute.path;
    Map<String, MergeResult> mergeResults = <String, MergeResult>{};
    Map<String, File> deletedFiles = <String, File>{};
    for (FileSystemEntity entity in currentFiles) {
      if (entity is! File) {
        continue;
      }
      File currentFile = (entity as File).absolute;
      // print('Checking ${currentFile.path}');
      if (!currentFile.path.startsWith(projectRootPath)) {
        continue; // Not a project file.
      }
      // Diff the current file against the old generated template
      String localPath = currentFile.path.replaceFirst(projectRootPath + globals.fs.path.separator, '');
      if (diffMap.containsKey(localPath) && diffMap[localPath]!.isIgnored || await MigrateUtils.isGitIgnored(currentFile.path, flutterProject.directory.absolute.path)) {
        // print('  File git ignored');
        continue;
      }
      File oldTemplateFile = generatedOldTemplateDirectory.childFile(localPath);
      DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

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
        MergeResult result = await MigrateUtils.gitMergeFile(
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

/////////////////////////////////////////////

    // create temp working directory
    // Directory workingDir = FlutterProject.current().directory.childDirectory('migrate_working_dir');

    for (String localPath in mergeResults.keys) {
      MergeResult result = mergeResults[localPath]!;
      File file = workingDir.childFile(localPath);
      file.createSync(recursive: true);
      file.writeAsStringSync(result.mergedContents, flush: true);
      print('  Wrote merged file $localPath');
    }

    for (String localPath in additionalFiles.keys) {
      File additionalFile = additionalFiles[localPath]!;
      File file = workingDir.childFile(localPath);
      file.createSync(recursive: true);
      file.writeAsStringSync(additionalFile.readAsStringSync(), flush: true);
      print('  Wrote Additional file $localPath');
    }

    MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, mergeResults: mergeResults, additionalFiles: additionalFiles, deletedFiles: deletedFiles);
    manifest.writeFile();

////////////////////////////////////////////////

    print('::::GENERATED FOLDERS::::::');
    print(generatedOldTemplateDirectory.path);
    print(generatedNewTemplateDirectory.path);
    // print(oldFlutterRoot.path);
    print('::::GENERATED FOLDERS::::::');

    if (boolArg('delete-temp-directories')) {

      MigrateUtils.deleteTempDirectories(
        paths: <String>[

        ],
        directories: <Directory>[
          generatedOldTemplateDirectory,
          generatedNewTemplateDirectory,
          // tempDir,
          // oldFlutterRoot,
        ],
      );
    }
    return const FlutterCommandResult(ExitStatus.success);
  }
}
