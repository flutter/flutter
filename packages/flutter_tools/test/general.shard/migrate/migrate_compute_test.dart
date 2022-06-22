// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_compute.dart';
import 'package:flutter_tools/src/migrate/migrate_result.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fileSystem;
  late File manifestFile;
  late BufferLogger logger;
  late MigrateUtils utils;
  late MigrateContext context;

  setUpAll(() {
    fileSystem = globals.localFileSystem;
    logger = BufferLogger.test();
    utils = MigrateUtils(
      logger: logger,
      fileSystem: fileSystem,
      platform: globals.platform,
      processManager: globals.processManager,
    );
    MigrateContext context = MigrateContext(
      migrateResult: MigrateResult.empty(),
      flutterProject: ,
      blacklistPrefixes: <String>[],
      logger: logger,
      verbose: true,
      fileSystem: fileSystem,
      status: logger.startSpinner();,
      migrateUtils: migrateUtils,
    );
  });

  group('MigrateFlutterProject', () {
    testWithoutContext('MigrateBaseFlutterProject creates', () async {
      final Directory workingDir = fileSystem.directory('migrate_working_dir');
      final Directory baseDir = fileSystem.directory('base_dir');
      workingDir.createSync(recursive: true);
      MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
        path: baseDir.path,
        directory: baseDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      baseProject.createProject(
        MigrateContext.,
        List<String> revisionsList,
        Map<String, List<MigratePlatformConfig>> revisionToConfigs,
        String fallbackRevision,
        String targetRevision,
        Directory targetFlutterDirectory,
      )

      expect(logger.statusText, contains('\n'));
    });

    testWithoutContext('populated MigrateResult detects fixed conflict', () async {
      final Directory workingDir = fileSystem.directory('migrate_working_dir');
      workingDir.createSync(recursive: true);
      final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
        mergeResults: <MergeResult>[
          StringMergeResult.explicit(
            localPath: 'merged_file',
            mergedString: 'str',
            hasConflict: false,
            exitCode: 0,
          ),
          StringMergeResult.explicit(
            localPath: 'conflict_file',
            mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\n=======\n<<<<<<<\nhi\n',
            hasConflict: true,
            exitCode: 1,
          ),
        ],
        addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
        deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
        // The following are ignored by the manifest.
        mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
        diffMap: <String, DiffResult>{},
        tempDirectories: <Directory>[],
        sdkDirs: <String, Directory>{},
      ));

      final File conflictFile = workingDir.childFile('conflict_file');
      conflictFile.writeAsStringSync('hello\nwow a bunch of lines\nhi\n', flush: true);

      checkAndPrintMigrateStatus(manifest, workingDir, warnConflict: true, logger: logger);
    });
  });
}
