// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:crypto/crypto.dart';

import '../base/file_system.dart';
import '../globals.dart';
import 'build_system.dart';

/// The file cache is a globally accessible cache of file hashes.
///
/// In cases where multiple targets read the same source files as inputs, we
/// avoid recomputing or storing multiple copies of hashes by delegating
/// through this class. All file hashes are held in memory during a build
/// operation, and persisted to cache in `{BUILD_DIR}/.filecache`.
///
/// To avoid persisting entries forever, it has a built in limit of 1,000,000
/// entries.
///
/// The format of the file cache is subject to change and not part of its API.
class FileCache {
  FileCache(this.environment);

  final Environment environment;
  final HashMap<String, String> previousHashes = HashMap<String, String>();
  final HashMap<String, String> currentHashes = HashMap<String, String>();

  // The name of the file which stores the file hashes.
  static const String _kFileCache = '.filecache';

  // The name of the file which stores the cache version.
  static const String _kFileCacheVersion = '.filecache_version';

  // The current version of the file cache storage format.
  static const String _kVersion = '1';

  /// Read file hashes from disk.
  void initialize() {
    printTrace('Initializing file cache');
    if (!_versionFile.existsSync()) {
      return;
    }
    if (_versionFile.readAsStringSync() != _kVersion) {
      _cacheFile.deleteSync();
      _versionFile.deleteSync();
    } else if (!_cacheFile.existsSync()) {
      return;
    }

    for (String line in _cacheFile.readAsLinesSync()) {
      final List<String> parts = line.split(' : ');
      if (parts.length != 2) {
        continue;
      }
      previousHashes[parts[0]] = parts[1];
    }
  }

  /// Persist file hashes to disk.
  void persist() {
    final File version = _versionFile;
    version.writeAsStringSync(_kVersion);
    final File file = _cacheFile;
    if (!file.existsSync()) {
      file.createSync();
    }
    // Overwrite any outdated hashes.
    for (MapEntry<String, String> entry in currentHashes.entries) {
      previousHashes[entry.key] = entry.value;
    }

    // Write 100 entries at a time to disk.
    String fencepost = '';
    final StringBuffer buffer = StringBuffer();
    int count = 0;
    for (MapEntry<String, String> entry in previousHashes.entries) {
      buffer.write('$fencepost${entry.key} : ${entry.value}');
      fencepost = '\n';
      count += 1;
      if (count >= 100) {
        file.writeAsStringSync(buffer.toString(), mode: FileMode.write);
        count = 0;
        buffer.clear();
      }
    }
    if (count != 0) {
      file.writeAsStringSync(buffer.toString(), mode: FileMode.write);
    }
  }

  /// Computes a hash of the provided files and returns a list of entities
  /// that were dirty.
  // TODO(jonahwilliams): compare hash performance with md5 tool on macOS and
  // linux and certutil on Windows, as well as dividing up computation across
  // isolates. This also related to the current performance issue with checking
  // APKs before installing them on device.
  Future<List<SourceFile>> hashFiles(List<SourceFile> files) async {
    final List<SourceFile> dirty = <SourceFile>[];
    for (SourceFile file in files) {
      final String absolutePath = file.path;
      final String previousHash = previousHashes[absolutePath];
      final List<int> bytes = file.bytesForVersion();
      final String currentHash = md5.convert(bytes).toString();

      if (currentHash != previousHash) {
        dirty.add(file);
      }
      currentHashes[absolutePath] = currentHash;
    }
    return dirty;
  }

  File get _versionFile => environment.rootBuildDir.childFile(_kFileCacheVersion);

  File get _cacheFile => environment.rootBuildDir.childFile(_kFileCache);
}
