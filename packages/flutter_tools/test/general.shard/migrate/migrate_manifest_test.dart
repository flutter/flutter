// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/migrate/migrate_manifest.dart';
import 'package:flutter_tools/src/migrate/migrate_result.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fileSystem;
  late File manifestFile;
  late BufferLogger logger;

  setUpAll(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    manifestFile = fileSystem.file('.migrate_manifest');
  });

  group('checkAndPrintMigrateStatus', () {
    testWithoutContext('empty MigrateResult produces empty output', () async {
      final Directory workingDir = fileSystem.directory('migrate_working_dir');
      workingDir.createSync(recursive: true);
      final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
        mergeResults: <MergeResult>[],
        addedFiles: <FilePendingMigration>[],
        deletedFiles: <FilePendingMigration>[],
        mergeTypeMap: <String, MergeType>{},
        diffMap: <String, DiffResult>{},
        tempDirectories: <Directory>[],
        sdkDirs: <String, Directory>{},
      ));

      checkAndPrintMigrateStatus(manifest, workingDir, warnConflict: true, logger: logger);

      expect(logger.statusText, contains('\n'));
    });

    testWithoutContext('populated MigrateResult produces correct output', () async {
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
      conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\n=======\n<<<<<<<\nhi\n', flush: true);

      checkAndPrintMigrateStatus(manifest, workingDir, warnConflict: true, logger: logger);

      expect(logger.statusText, contains('''
Added files:
  - added_file
Deleted files:
  - deleted_file
Modified files:
  - conflict_file
  - merged_file
'''));
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
      expect(logger.statusText, contains('''
Added files:
  - added_file
Deleted files:
  - deleted_file
Modified files:
  - conflict_file
  - merged_file
'''));
    });
  });

  group('manifest file parsing', () {
    testWithoutContext('empty fails', () async {
      manifestFile.writeAsStringSync('');
      bool exceptionFound = false;
      try {
        MigrateManifest.fromFile(manifestFile);
      } on Exception catch (e) {
        exceptionFound = true;
        expect(e.toString(), 'Exception: Invalid .migrate_manifest file in the migrate working directory. File is not a Yaml map.');
      }
      expect(exceptionFound, true);
    });

    testWithoutContext('invalid name fails', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
        conflict_files:
        added_filessssss:
        deleted_files:
      ''');
      bool exceptionFound = false;
      try {
       MigrateManifest.fromFile(manifestFile);
      } on Exception catch (e) {
        exceptionFound = true;
        expect(e.toString(), 'Exception: Invalid .migrate_manifest file in the migrate working directory. File is missing an entry.');
      }
      expect(exceptionFound, true);
    });

    testWithoutContext('missing name fails', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
        conflict_files:
        deleted_files:
      ''');
      bool exceptionFound = false;
      try {
        MigrateManifest.fromFile(manifestFile);
      } on Exception catch (e) {
        exceptionFound = true;
        expect(e.toString(), 'Exception: Invalid .migrate_manifest file in the migrate working directory. File is missing an entry.');
      }
      expect(exceptionFound, true);
    });

    testWithoutContext('wrong entry type fails', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
        conflict_files:
          other_key:
        added_files:
        deleted_files:
      ''');
      bool exceptionFound = false;
      try {
        MigrateManifest.fromFile(manifestFile);
      } on Exception catch (e) {
        exceptionFound = true;
        expect(e.toString(), 'Exception: Invalid .migrate_manifest file in the migrate working directory. Entry is not a Yaml list.');
      }
      expect(exceptionFound, true);
    });

    testWithoutContext('unpopulated succeeds', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
        conflict_files:
        added_files:
        deleted_files:
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, true);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, true);
    });

    testWithoutContext('order does not matter', () async {
      manifestFile.writeAsStringSync('''
        added_files:
        merged_files:
        deleted_files:
        conflict_files:
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, true);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, true);
    });

    testWithoutContext('basic succeeds', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
          - file1
        conflict_files:
          - file2
        added_files:
          - file3
        deleted_files:
          - file4
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, false);
      expect(manifest.conflictFiles.isEmpty, false);
      expect(manifest.addedFiles.isEmpty, false);
      expect(manifest.deletedFiles.isEmpty, false);

      expect(manifest.mergedFiles.length, 1);
      expect(manifest.conflictFiles.length, 1);
      expect(manifest.addedFiles.length, 1);
      expect(manifest.deletedFiles.length, 1);

      expect(manifest.mergedFiles[0], 'file1');
      expect(manifest.conflictFiles[0], 'file2');
      expect(manifest.addedFiles[0], 'file3');
      expect(manifest.deletedFiles[0], 'file4');
    });

    testWithoutContext('basic multi-list succeeds', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
          - file1
          - file2
        conflict_files:
        added_files:
        deleted_files:
          - file3
          - file4
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, false);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, false);

      expect(manifest.mergedFiles.length, 2);
      expect(manifest.conflictFiles.length, 0);
      expect(manifest.addedFiles.length, 0);
      expect(manifest.deletedFiles.length, 2);

      expect(manifest.mergedFiles[0], 'file1');
      expect(manifest.mergedFiles[1], 'file2');
      expect(manifest.deletedFiles[0], 'file3');
      expect(manifest.deletedFiles[1], 'file4');
    });
  });

  group('manifest MigrateResult creation', () {
    testWithoutContext('empty MigrateResult', () async {
      final MigrateManifest manifest = MigrateManifest(migrateRootDir: fileSystem.directory('root'), migrateResult: MigrateResult(
        mergeResults: <MergeResult>[],
        addedFiles: <FilePendingMigration>[],
        deletedFiles: <FilePendingMigration>[],
        mergeTypeMap: <String, MergeType>{},
        diffMap: <String, DiffResult>{},
        tempDirectories: <Directory>[],
        sdkDirs: <String, Directory>{},
      ));
      expect(manifest.mergedFiles.isEmpty, true);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, true);
    });

    testWithoutContext('simple MigrateResult', () async {
      final MigrateManifest manifest = MigrateManifest(migrateRootDir: fileSystem.directory('root'), migrateResult: MigrateResult(
        mergeResults: <MergeResult>[
          StringMergeResult.explicit(
            localPath: 'merged_file',
            mergedString: 'str',
            hasConflict: false,
            exitCode: 0,
          ),
          StringMergeResult.explicit(
            localPath: 'conflict_file',
            mergedString: '<<<<<<<<<<<',
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
      expect(manifest.mergedFiles.isEmpty, false);
      expect(manifest.conflictFiles.isEmpty, false);
      expect(manifest.addedFiles.isEmpty, false);
      expect(manifest.deletedFiles.isEmpty, false);

      expect(manifest.mergedFiles.length, 1);
      expect(manifest.conflictFiles.length, 1);
      expect(manifest.addedFiles.length, 1);
      expect(manifest.deletedFiles.length, 1);

      expect(manifest.mergedFiles[0], 'merged_file');
      expect(manifest.conflictFiles[0], 'conflict_file');
      expect(manifest.addedFiles[0], 'added_file');
      expect(manifest.deletedFiles[0], 'deleted_file');
    });
  });

  group('manifest write', () {
    testWithoutContext('empty', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
        conflict_files:
        added_files:
        deleted_files:
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, true);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, true);

      manifest.writeFile();
      expect(manifestFile.readAsStringSync(), '''
merged_files:
conflict_files:
added_files:
deleted_files:
''');
    });

    testWithoutContext('basic multi-list', () async {
      manifestFile.writeAsStringSync('''
        merged_files:
          - file1
          - file2
        conflict_files:
        added_files:
        deleted_files:
          - file3
          - file4
      ''');
      final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
      expect(manifest.mergedFiles.isEmpty, false);
      expect(manifest.conflictFiles.isEmpty, true);
      expect(manifest.addedFiles.isEmpty, true);
      expect(manifest.deletedFiles.isEmpty, false);

      expect(manifest.mergedFiles.length, 2);
      expect(manifest.conflictFiles.length, 0);
      expect(manifest.addedFiles.length, 0);
      expect(manifest.deletedFiles.length, 2);

      expect(manifest.mergedFiles[0], 'file1');
      expect(manifest.mergedFiles[1], 'file2');
      expect(manifest.deletedFiles[0], 'file3');
      expect(manifest.deletedFiles[1], 'file4');

      manifest.writeFile();
      expect(manifestFile.readAsStringSync(), '''
merged_files:
  - file1
  - file2
conflict_files:
added_files:
deleted_files:
  - file3
  - file4
''');
    });
  });
}
