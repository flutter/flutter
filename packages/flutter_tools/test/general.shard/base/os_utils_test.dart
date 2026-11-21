// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class _WithoutRsyncProcessManager extends LocalProcessManager {
  const _WithoutRsyncProcessManager();

  @override
  bool canRun(Object? executable, {String? workingDirectory}) {
    if (executable == 'rsync') {
      return false;
    }
    return executable is String && super.canRun(executable, workingDirectory: workingDirectory);
  }
}

Archive _buildZipSlipArchive() {
  final List<int> payload = utf8.encode('pwned');
  return Archive()
    ..addFile(ArchiveFile('../../escape.txt', payload.length, payload))
    ..addFile(ArchiveFile('sub/../../target-sibling/mid_marker.txt', payload.length, payload))
    ..addFile(ArchiveFile('../target-sibling/poc_marker.txt', payload.length, payload));
}

void main() {
  group('OperatingSystemUtils', () {
    late Directory tempDir;
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = LocalFileSystem.test(signals: FakeSignals());
      tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_tools_os_utils_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testWithoutContext('makeExecutable', () async {
      const Platform platform = LocalPlatform();
      final operatingSystemUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
        processManager: const LocalProcessManager(),
      );
      final File file = fileSystem.file(fileSystem.path.join(tempDir.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      operatingSystemUtils.makeExecutable(file);

      // Skip this test on windows.
      if (!platform.isWindows) {
        final String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    });

    testWithoutContext('unzip extracts valid archive', () {
      const Platform platform = LocalPlatform();
      final File zipFile = tempDir.childFile('valid.zip');
      final List<int> content = utf8.encode('hello zip');
      final archive = Archive()..addFile(ArchiveFile('nested/hello.txt', content.length, content));
      zipFile.writeAsBytesSync(ZipEncoder().encode(archive)!);

      void verifyUnzip(ProcessManager processManager, String targetName) {
        final Directory targetDirectory = tempDir.childDirectory(targetName)..createSync();
        final operatingSystemUtils = OperatingSystemUtils(
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          platform: platform,
          processManager: processManager,
        );
        operatingSystemUtils.unzip(zipFile, targetDirectory);

        final File extractedFile = targetDirectory.childDirectory('nested').childFile('hello.txt');
        expect(extractedFile, exists);
        expect(extractedFile.readAsStringSync(), 'hello zip');
      }

      verifyUnzip(const LocalProcessManager(), 'target');
      if (platform.isMacOS) {
        verifyUnzip(const _WithoutRsyncProcessManager(), 'target_without_rsync');
      }
    });

    testWithoutContext('unzip protects against zip-slip path traversal', () {
      const Platform platform = LocalPlatform();
      final File zipFile = tempDir.childFile('zip_slip.zip')
        ..writeAsBytesSync(ZipEncoder().encode(_buildZipSlipArchive())!);

      void verifyZipSlipProtection(ProcessManager processManager, String cacheName) {
        final Directory cacheDir = tempDir.childDirectory(cacheName)..createSync(recursive: true);
        final Directory targetDirectory = cacheDir.childDirectory('target')
          ..createSync(recursive: true);
        final Directory siblingDirectory = cacheDir.childDirectory('target-sibling');
        final operatingSystemUtils = OperatingSystemUtils(
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          platform: platform,
          processManager: processManager,
        );

        if (platform.isWindows) {
          expect(
            () => operatingSystemUtils.unzip(zipFile, targetDirectory),
            throwsProcessException(),
          );
        } else {
          try {
            operatingSystemUtils.unzip(zipFile, targetDirectory);
          } on ProcessException {
            // Some unzip builds return a non-zero warning code when stripping '..'.
          }
        }

        expect(tempDir.childFile('escape.txt'), isNot(exists));
        expect(siblingDirectory, isNot(exists));
        expect(cacheDir.listSync().map((FileSystemEntity e) => e.path), <String>[
          targetDirectory.path,
        ]);
      }

      verifyZipSlipProtection(const LocalProcessManager(), 'cache');
      if (platform.isMacOS) {
        verifyZipSlipProtection(const _WithoutRsyncProcessManager(), 'cache_without_rsync');
      }
    });

    testWithoutContext('unpack extracts valid archive', () {
      const Platform platform = LocalPlatform();
      final Directory targetDirectory = tempDir.childDirectory('target')..createSync();
      final File tarGzFile = tempDir.childFile('valid.tar.gz');
      final List<int> content = utf8.encode('hello tar');
      final archive = Archive()..addFile(ArchiveFile('nested/hello.txt', content.length, content));
      tarGzFile.writeAsBytesSync(GZipEncoder().encode(TarEncoder().encode(archive))!);

      final operatingSystemUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
        processManager: const LocalProcessManager(),
      );
      operatingSystemUtils.unpack(tarGzFile, targetDirectory);

      final File extractedFile = targetDirectory.childDirectory('nested').childFile('hello.txt');
      expect(extractedFile, exists);
      expect(extractedFile.readAsStringSync(), 'hello tar');
    });

    testWithoutContext('unpack protects against zip-slip path traversal', () {
      const Platform platform = LocalPlatform();
      final Directory cacheDir = tempDir.childDirectory('cache')..createSync(recursive: true);
      final Directory targetDirectory = cacheDir.childDirectory('target')
        ..createSync(recursive: true);
      final Directory siblingDirectory = cacheDir.childDirectory('target-sibling');
      final File tarGzFile = tempDir.childFile('zip_slip.tar.gz')
        ..writeAsBytesSync(GZipEncoder().encode(TarEncoder().encode(_buildZipSlipArchive()))!);

      final operatingSystemUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: platform,
        processManager: const LocalProcessManager(),
      );

      expect(
        () => operatingSystemUtils.unpack(tarGzFile, targetDirectory),
        throwsProcessException(),
      );
      expect(tempDir.childFile('escape.txt'), isNot(exists));
      expect(siblingDirectory, isNot(exists));
    });
  });
}
