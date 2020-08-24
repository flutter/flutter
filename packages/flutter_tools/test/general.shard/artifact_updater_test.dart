// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file/src/interface/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('ArtifactUpdater can download a zip archive', () async {
    final FakeNet net = FakeNet();
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      net: net,
      operatingSystemUtils: operatingSystemUtils,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will de-download a file if unzipping fails', () async {
    final FakeNet net = FakeNet();
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      net: net,
      operatingSystemUtils: operatingSystemUtils,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 1;

    await artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(logger.statusText, contains('test message'));
    expect(fileSystem.file('out/test'), exists);
    expect(net.attempts, 2);
  });

  testWithoutContext('ArtifactUpdater will bail if unzipping fails more than twice', () async {
    final FakeNet net = FakeNet();
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      net: net,
      operatingSystemUtils: operatingSystemUtils,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );
    operatingSystemUtils.failures = 2;

    expect(artifactUpdater.downloadZipArchive(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    ), throwsA(isA<ProcessException>()));
    expect(fileSystem.file('te,[/test'), isNot(exists));
    expect(fileSystem.file('out/test'), isNot(exists));
  });

  testWithoutContext('ArtifactUpdater can download a tar archive', () async {
    final FakeNet net = FakeNet();
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      net: net,
      operatingSystemUtils: operatingSystemUtils,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    await artifactUpdater.downloadZippedTarball(
      'test message',
      Uri.parse('http:///test.zip'),
      fileSystem.currentDirectory.childDirectory('out'),
    );
    expect(fileSystem.file('out/test'), exists);
  });

  testWithoutContext('ArtifactUpdater will delete downloaded files if they exist.', () async {
    final FakeNet net = FakeNet();
    final MockOperatingSystemUtils operatingSystemUtils = MockOperatingSystemUtils();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final ArtifactUpdater artifactUpdater = ArtifactUpdater(
      fileSystem: fileSystem,
      logger: logger,
      net: net,
      operatingSystemUtils: operatingSystemUtils,
      tempStorage: fileSystem.currentDirectory.childDirectory('temp')
        ..createSync(),
    );

    artifactUpdater.downloadedFiles.addAll(<File>[
      fileSystem.file('a/b/c/d')..createSync(recursive: true),
      fileSystem.file('d/e/f'),
    ]);

    artifactUpdater.removeDownloadedFiles();

    expect(fileSystem.file('a/b/c/d'), isNot(exists));
    expect(logger.errorText, isEmpty);
  });
}

class FakeNet implements Net {
  int attempts = 0;

  @override
  Future<bool> doesRemoteFileExist(Uri url) async {
    return true;
  }

  @override
  Future<List<int>> fetchUrl(Uri url, {int maxAttempts, File destFile}) async {
    attempts += 1;
    if (destFile != null) {
      destFile.createSync();
      return null;
    }
    return <int>[];
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {
  int failures = 0;

  @override
  void unzip(File file, Directory targetDirectory) {
    if (failures > 0) {
      failures -= 1;
      throw const ProcessException('zip', <String>[], 'Failed to unzip');
    }
    targetDirectory.childFile(file.fileSystem.path.basenameWithoutExtension(file.path))
      .createSync();
  }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    if (failures > 0) {
      failures -= 1;
      throw const ProcessException('zip', <String>[], 'Failed to unzip');
    }
    targetDirectory.childFile(gzippedTarFile.fileSystem.path.basenameWithoutExtension(gzippedTarFile.path))
      .createSync();
  }
}
