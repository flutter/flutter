// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_utils.dart';
import '../migrate/migrate_config.dart';
import '../cache.dart';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addFlag('delete-temp-directories',
      negatable: true,
      help: "",
    );
  }

  final bool _verbose;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrates flutter generated project files to the current flutter version';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();

    // final Directory buildDir = globals.fs.directory(getBuildDirectory());
    print('HERE');

    List<MigrateConfig> configs = <MigrateConfig>[];
    List<String> platforms = <String>['root', 'android'];
    for (String platform in platforms) {
      if (MigrateConfig.getFileFromPlatform(platform).existsSync()) {
        configs.add(MigrateConfig.fromPlatform(platform));
      } else {
        MigrateConfig newConfig = MigrateConfig(
          platform: platform,
          createVersion: 'vklalckasjlcksa',
          lastMigrateVersion: 'askdl;laskdlas;kd',
          unmanagedFiles: <String>[
            'blah/file/path',
          ],
        );
        newConfig.writeFile();
        configs.add(newConfig);
      }
    }

    // String revision = '5344ed71561b924fb23300fb7fdb306744718767';
    String revision = '18116933e77adc82f80866c928266a5b4f1ed645';

    // // Get the list of file names in the old templates directory
    // List<String> files = await MigrateUtils.getFileNamesInDirectory(
    //   revision: revision,
    //   searchPath: 'packages/flutter_tools/templates',
    //   workingDirectory: Cache.flutterRoot!,
    // );

    // // Clone a copy of the old templates directory into a temp dir.
    // Directory tempDir = await MigrateUtils.createTempDirectory('tempdir1');
    // print(tempDir.path);
    // for (String f in files) {
    //   print('Retrieving $f');
    //   File fileOld = tempDir.childFile(f);
    //   String contents = await MigrateUtils.getFileContents(
    //     revision: revision,
    //     file: f,
    //     workingDirectory: Cache.flutterRoot!,
    //     outputPath: fileOld.path.trim(),
    //   );
    // }

    // Generate the old templates
    // Directory generatedOldTemplateDirectory = await MigrateUtils.createTempDirectory('generatedOldTemplate');
    // Directory generatedNewTemplateDirectory = await MigrateUtils.createTempDirectory('generateNewTemplate');
    // Directory oldFlutterRoot = await MigrateUtils.createTempDirectory('oldFlutter');

    Directory generatedOldTemplateDirectory = globals.fs.directory('/var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generatedOldTemplate.j8Tto95k');
    Directory generatedNewTemplateDirectory = globals.fs.directory('/var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/generateNewTemplate.0f4evU9N');
    // Directory oldFlutterRoot = globals.fs.directory();

    // // Clone old flutter
    // await MigrateUtils.cloneFlutter(revision, oldFlutterRoot.absolute.path);

    // // Create old
    // await MigrateUtils.createFromTemplates(
    //   oldFlutterRoot.childDirectory('bin').absolute.path,
    //   flutterProject.manifest.appName,
    //   outputDirectory: generatedOldTemplateDirectory.absolute.path
    // );

    // // Create new
    // await MigrateUtils.createFromTemplates(
    //   globals.fs.path.join(Cache.flutterRoot!, 'bin'),
    //   flutterProject.manifest.appName,
    //   outputDirectory: generatedNewTemplateDirectory.absolute.path
    // );

    // Generate diffs
    List<FileSystemEntity> generatedOldFiles = generatedOldTemplateDirectory.listSync(recursive: true);
    List<FileSystemEntity> generatedNewFiles = generatedNewTemplateDirectory.listSync(recursive: true);

    Map<String, DiffResult> diffMap = <String, DiffResult>{};
    for (FileSystemEntity entity in generatedOldFiles) {
      print(entity.path);
      if (entity is! File) {
        continue;
      }
      File oldTemplateFile = (entity as File).absolute;
      if (!oldTemplateFile.path.startsWith(generatedOldTemplateDirectory.absolute.path)) {
        continue;
      }
      String localPath = oldTemplateFile.path.replaceFirst(generatedOldTemplateDirectory.absolute.path + globals.fs.path.separator, '');
      File newTemplateFile = generatedNewTemplateDirectory.childFile(localPath);
      print('  Comparing to new template: ${newTemplateFile.path}');
      if (newTemplateFile.existsSync()) {
        DiffResult diff = await MigrateUtils.diffFiles(oldTemplateFile, newTemplateFile);
        diffMap[localPath] = diff;
        print(diff.diff);
      } else {
        print('else');
        // Current file has no new template counterpart, which is equivalent to a deletion.
        // This could also indicate a renaming if there is an addition with equivalent contents.
        diffMap[localPath] = DiffResult.deletion();
      }
    }

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
      print('  Addition');
      diffMap[localPath] = DiffResult.addition();
    }
    // TODO write diffs to files

    // Directory diffRootDirectory = await MigrateUtils.createTempDirectory('diffRoot');

    // for each file
    List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
    String projectRootPath = flutterProject.directory.absolute.path;
    for (FileSystemEntity entity in currentFiles) {
      if (entity is! File) {
        continue;
      }
      File currentFile = (entity as File).absolute;
      print('Checking ${currentFile.path}');
      if (!currentFile.path.startsWith(projectRootPath)) {
        continue; // Not a project file.
      }
      // Diff the current file against the old generated template
      String localPath = currentFile.path.replaceFirst(projectRootPath + globals.fs.path.separator, '');
      File oldTemplateFile = generatedOldTemplateDirectory.childFile(localPath);
      DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

      // File diffFile = diffRootDirectory.childFile(currentFile.path.replaceFirst(projectRootPath, ''));
      if (userDiff.exitCode == 0) {
        // Current file unchanged by user
        print('  File unchanged');
        if (diffMap.containsKey(localPath) && diffMap[localPath]!.isDeletion) { // File is deleted in new template
          print('    DELETING');
          // currentFile.deleteSync();
        }
        continue;
      }

      if (diffMap.containsKey(localPath)) {
        MergeResult result = await MigrateUtils.gitMergeFile(
          ancestor: globals.fs.path.join(generatedOldTemplateDirectory.path, localPath),
          current: currentFile.path,
          other: globals.fs.path.join(generatedNewTemplateDirectory.path, localPath),
        );
        print(result.mergedContents);
        // merge(currentFile, diffMap[localPath]!, userDiff);
      }
    }

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

    print('DONE');

    return const FlutterCommandResult(ExitStatus.success);
  }

  void merge(File currentFile, DiffResult diffFile, DiffResult userDiff) {
    print('  Merging');
    // MigrateUtils.gitMergeFile(
    //   ancestor: 
    //   current:
    //   other:
    // );
  }

  void parseParameters() {
    // String name = flutterProject.manifest.appName;
    String androidLanguage;
    String iosLanguage;
  }
}
