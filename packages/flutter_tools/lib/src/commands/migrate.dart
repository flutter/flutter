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

    String revision = '5344ed71561b924fb23300fb7fdb306744718767';

    // Get the list of file names in the old templates directory
    List<String> files = await MigrateUtils.getFileNamesInDirectory(
      revision: revision,
      searchPath: 'packages/flutter_tools/templates',
      workingDirectory: Cache.flutterRoot!,
    );

    // Clone a copy of the old templates directory into a temp dir.
    Directory tempDir = await MigrateUtils.createTempDirectory('tempdir1');
    print(tempDir.path);
    for (String f in files) {
      print('REtrieving $f');
      File fileOld = tempDir.childFile(f);
      String contents = await MigrateUtils.getFileContents(
        revision: revision,
        file: f,
        workingDirectory: Cache.flutterRoot!,
        outputPath: fileOld.path.trim(),
      );
    }

    // Generate the old templates

    Directory generatedOldTemplateDirectory = await MigrateUtils.createTempDirectory('generatedOldTemplate');
    Directory generatedNewTemplateDirectory = await MigrateUtils.createTempDirectory('generateNewTemplate');

    // Generate diffs
    List<FileSystemEntity> generatedOldFiles = generatedOldTemplateDirectory.listSync(recursive: true);
    List<FileSystemEntity> generatedNewFiles = generatedNewTemplateDirectory.listSync(recursive: true);

    for (FileSystemEntity entity in generatedOldFiles) {
      if (entity is! File) {
        continue;
      }
      File oldTemplateFile = (entity as File).absolute;
      if (!oldTemplateFile.path.startsWith(generatedOldTemplateDirectory.absolute.path)) {
        continue;
      }
      File newTemplateFile = generatedNewTemplateDirectory.childFile(oldTemplateFile.path.replaceFirst(generatedOldTemplateDirectory.absolute.path, ''));
      if (newTemplateFile.existsSync()) {
        DiffResult diff = await MigrateUtils.diffFiles(oldTemplateFile, newTemplateFile);
        print(diff.diff);
      } else {
        // current file has no new template counterpart.
      }
    }
    // TODO write diffs to files

    Directory diffRootDirectory = await MigrateUtils.createTempDirectory('diffRoot');


    // for each file
    List<FileSystemEntity> currentFiles = flutterProject.directory.listSync(recursive: true);
    String projectRootPath = flutterProject.directory.absolute.path;
    for (FileSystemEntity entity in currentFiles) {
      if (entity is! File) {
        continue;
      }
      File currentFile = (entity as File).absolute;
      if (!currentFile.path.startsWith(projectRootPath)) {
        continue; // Not a project file.
      }
      // Diff the current file against the old generated template
      File oldTemplateFile = generatedOldTemplateDirectory.childFile(currentFile.path.replaceFirst(projectRootPath, ''));
      DiffResult userDiff = await MigrateUtils.diffFiles(oldTemplateFile, currentFile);

      File diffFile = diffRootDirectory.childFile(currentFile.path.replaceFirst(projectRootPath, ''));
      if (userDiff.exitCode == 0) {
        // Current file unchanged by user
        if (false) { // File is deleted in new template
          currentFile.deleteSync();
        }
        continue;
      }

      if (diffFile.existsSync()) {
        merge(currentFile, diffFile, userDiff);
      }
    }

    print(tempDir.path);

    print('DONE');

    return const FlutterCommandResult(ExitStatus.success);
  }

  void merge(File currentFile, File diffFile, DiffResult userDiff) {

  }
}
