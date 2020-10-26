// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';

class BundleProcessor {
  BundleProcessor({
    @required FileSystem fileSystem,
    @required Logger logger,
  }) : _fileSystem = fileSystem,
       _logger = logger;

  final FileSystem _fileSystem;
  final Logger _logger;

  /// Tests whether a [FileSystemEntity] is an macOS bundle directory.
  static bool isBundleDirectory(FileSystemEntity entity) =>
      entity is Directory && entity.path.endsWith('.app');

  /// Return the directory of an app bundle given some [FileSystemEntity].
  ///
  /// The default implementation of this function checks that the input is a
  /// directory that ends with the `.app` extension.
  Directory getAppBundle(FileSystemEntity applicationBundle) {
    final FileSystemEntityType entityType = _fileSystem.typeSync(applicationBundle.path);
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = _fileSystem.directory(applicationBundle);
      if (!isBundleDirectory(directory)) {
        _logger.printError('Folder "${applicationBundle.path}" is not an app bundle.');
        return null;
      }
      return directory;
    } else {
      _logger.printError('Folder "${applicationBundle.path}" is not an app bundle.');
      return null;
    }
  }
}
