// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../base/file_system.dart';
import '../globals.dart';
import 'build_system.dart';
import 'filecache.pb.dart' as pb;

/// A globally accessible cache of file hashes.
///
/// In cases where multiple targets read the same source files as inputs, we
/// avoid recomputing or storing multiple copies of hashes by delegating
/// through this class. All file hashes are held in memory during a build
/// operation, and persisted to cache in the root build directory.
///
/// The format of the file store is subject to change and not part of its API.
///
/// To regenerate the protobuf entries used to construct the cache:
///   1. If not already installed, https://developers.google.com/protocol-buffers/docs/downloads
///   2. pub global active `protoc-gen-dart`
///   3. protoc -I=lib/src/build_system/  --dart_out=lib/src/build_system/  lib/src/build_system/filecache.proto
///   4. Add licenses headers to the newly generated file and check-in.
///
/// See also: https://developers.google.com/protocol-buffers/docs/darttutorial
// TODO(jonahwilliams): find a better way to clear out old entries, perhaps
// track the last access or modification date?
class FileHashStore {
  FileHashStore(this.environment);

  final Environment environment;
  final HashMap<String, String> previousHashes = HashMap<String, String>();
  final HashMap<String, String> currentHashes = HashMap<String, String>();

  // The name of the file which stores the file hashes.
  static const String _kFileCache = '.filecache';

  // The current version of the file cache storage format.
  static const int _kVersion = 1;

  /// Read file hashes from disk.
  void initialize() {
    printTrace('Initializing file store');
    if (!_cacheFile.existsSync()) {
      return;
    }
    final List<int> data = _cacheFile.readAsBytesSync();
    final pb.FileStorage fileStorage = pb.FileStorage.fromBuffer(data);
    if (fileStorage.version != _kVersion) {
      _cacheFile.deleteSync();
      return;
    }
    for (pb.FileHash fileHash in fileStorage.files) {
      previousHashes[fileHash.path] = fileHash.hash;
    }
    printTrace('Done initializing file store');
  }

  /// Persist file hashes to disk.
  void persist() {
    printTrace('Persisting file store');
    final pb.FileStorage fileStorage = pb.FileStorage();
    fileStorage.version = _kVersion;
    final File file = _cacheFile;
    if (!file.existsSync()) {
      file.createSync();
    }
    for (MapEntry<String, String> entry in currentHashes.entries) {
      previousHashes[entry.key] = entry.value;
    }
    for (MapEntry<String, String> entry in previousHashes.entries) {
      final pb.FileHash fileHash = pb.FileHash();
      fileHash.path = entry.key;
      fileHash.hash = entry.value;
      fileStorage.files.add(fileHash);
    }
    final Uint8List buffer = fileStorage.writeToBuffer();
    file.writeAsBytesSync(buffer);
    printTrace('Done persisting file store');
  }

  /// Computes a hash of the provided files and returns a list of entities
  /// that were dirty.
  // TODO(jonahwilliams): compare hash performance with md5 tool on macOS and
  // linux and certutil on Windows, as well as dividing up computation across
  // isolates. This also related to the current performance issue with checking
  // APKs before installing them on device.
  Future<List<File>> hashFiles(List<File> files) async {
    final List<File> dirty = <File>[];
    for (File file in files) {
      final String absolutePath = file.resolveSymbolicLinksSync();
      final String previousHash = previousHashes[absolutePath];
      final List<int> bytes = file.readAsBytesSync();
      final String currentHash = md5.convert(bytes).toString();

      if (currentHash != previousHash) {
        dirty.add(file);
      }
      currentHashes[absolutePath] = currentHash;
    }
    return dirty;
  }

  File get _cacheFile => environment.buildDir.childFile(_kFileCache);
}
