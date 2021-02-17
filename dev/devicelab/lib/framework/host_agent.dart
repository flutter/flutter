// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';

/// The current host machine running the tests.
HostAgent get hostAgent => HostAgent(platform: const LocalPlatform(), fileSystem: const LocalFileSystem());

/// Host machine running the tests.
class HostAgent {
  HostAgent({@required Platform platform, @required FileSystem fileSystem})
      : _platform = platform,
        _fileSystem = fileSystem;

  final Platform _platform;
  final FileSystem _fileSystem;

  /// Creates a directory to dump file artifacts.
  Directory get dumpDirectory {
    if (_dumpDirectory == null) {
      // Set in LUCI recipe.
      final String directoryPath = _platform.environment['FLUTTER_LOGS_DIR'];
      if (directoryPath == null) {
        _dumpDirectory = _fileSystem.systemTempDirectory.createTempSync('flutter_test_logs.');
        print('Created tmp dump directory ${_dumpDirectory.path}');
      } else {
        _dumpDirectory = _fileSystem.directory(directoryPath)..createSync(recursive: true);
        print('Found FLUTTER_LOGS_DIR dump directory ${_dumpDirectory.path}');
      }
    }
    return _dumpDirectory;
  }

  void dumpFiles(List<String> paths) {
    if (paths == null || paths.isEmpty) {
      return;
    }

    for (final String detail in paths) {
      final File resultFile = _fileSystem.file(detail);
      final String destination = path.join(dumpDirectory.path, resultFile.basename);
      if (resultFile.existsSync()) {
        resultFile.copySync(destination);
        continue;
      }

      final Directory resultDirectory = _fileSystem.directory(detail);
      if (resultDirectory.existsSync()) {
        _recursiveCopy(resultDirectory, _fileSystem.directory(destination));
      }
    }
  }

  static Directory _dumpDirectory;

  @visibleForTesting
  void resetDumpDirectory() {
    _dumpDirectory = null;
  }
}

void _recursiveCopy(Directory source, Directory target) {
  target.createSync();

  for (final FileSystemEntity entity in source.listSync(followLinks: false)) {
    final String name = entity.basename;
    if (entity is Directory) {
      _recursiveCopy(entity, target.childDirectory(name));
    } else if (entity is File) {
      entity.copySync(path.join(target.path, name));
    }
  }
}
