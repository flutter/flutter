// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../globals.dart';
import 'build_system.dart';

/// An encoded representation of all file hashes.
class FileStorage {
  FileStorage(this.version, this.files);

  factory FileStorage.fromBuffer(Uint8List buffer) {
    final Map<String, dynamic> json = castStringKeyedMap(jsonDecode(utf8.decode(buffer)));
    final int version = json['version'] as int;
    final List<Map<String, Object>> rawCachedFiles = (json['files'] as List<dynamic>).cast<Map<String, Object>>();
    final List<FileHash> cachedFiles = <FileHash>[
      for (Map<String, Object> rawFile in rawCachedFiles) FileHash.fromJson(rawFile),
    ];
    return FileStorage(version, cachedFiles);
  }

  final int version;
  final List<FileHash> files;

  List<int> toBuffer() {
    final Map<String, Object> json = <String, Object>{
      'version': version,
      'files': <Object>[
        for (FileHash file in files) file.toJson(),
      ],
    };
    return utf8.encode(jsonEncode(json));
  }
}

/// A stored file hash and path.
class FileHash {
  FileHash(this.path, this.hash);

  factory FileHash.fromJson(Map<String, Object> json) {
    return FileHash(json['path'] as String, json['hash'] as String);
  }

  final String path;
  final String hash;

  Object toJson() {
    return <String, Object>{
      'path': path,
      'hash': hash,
    };
  }
}

/// A globally accessible cache of file hashes.
///
/// In cases where multiple targets read the same source files as inputs, we
/// avoid recomputing or storing multiple copies of hashes by delegating
/// through this class. All file hashes are held in memory during a build
/// operation, and persisted to cache in the root build directory.
///
/// The format of the file store is subject to change and not part of its API.
class FileHashStore {
  FileHashStore(this.environment, this.fileSystem) :
    _cachePath = environment.buildDir.childFile(_kFileCache).path;

  final FileSystem fileSystem;
  final String _cachePath;
  final Environment environment;
  final HashMap<String, String> previousHashes = HashMap<String, String>();
  final HashMap<String, String> currentHashes = HashMap<String, String>();

  // The name of the file which stores the file hashes.
  static const String _kFileCache = '.filecache';

  // The current version of the file cache storage format.
  static const int _kVersion = 2;

  /// Read file hashes from disk.
  void initialize() {
    printTrace('Initializing file store');
    final File cacheFile = fileSystem.file(_cachePath);
    if (!cacheFile.existsSync()) {
      return;
    }
    Uint8List data;
    try {
      data = cacheFile.readAsBytesSync();
    } on FileSystemException catch (err) {
      printError(
        'Failed to read file store at ${cacheFile.path} due to $err.\n'
        'Build artifacts will not be cached. Try clearing the cache directories '
        'with "flutter clean"',
      );
      return;
    }

    FileStorage fileStorage;
    try {
      fileStorage = FileStorage.fromBuffer(data);
    } catch (err) {
      printTrace('Filestorage format changed');
      cacheFile.deleteSync();
      return;
    }
    if (fileStorage.version != _kVersion) {
      printTrace('file cache format updating, clearing old hashes.');
      cacheFile.deleteSync();
      return;
    }
    for (FileHash fileHash in fileStorage.files) {
      previousHashes[fileHash.path] = fileHash.hash;
    }
    printTrace('Done initializing file store');
  }

  /// Persist file hashes to disk.
  void persist() {
    printTrace('Persisting file store');
    final File cacheFile = fileSystem.file(_cachePath);
    if (!cacheFile.existsSync()) {
      cacheFile.createSync(recursive: true);
    }
    final List<FileHash> fileHashes = <FileHash>[];
    for (MapEntry<String, String> entry in currentHashes.entries) {
      fileHashes.add(FileHash(entry.key, entry.value));
    }
    final FileStorage fileStorage = FileStorage(
      _kVersion,
      fileHashes,
    );
    final List<int> buffer = fileStorage.toBuffer();
    try {
      cacheFile.writeAsBytesSync(buffer);
    } on FileSystemException catch (err) {
      printError(
        'Failed to persist file store at ${cacheFile.path} due to $err.\n'
        'Build artifacts will not be cached. Try clearing the cache directories '
        'with "flutter clean"',
      );
    }
    printTrace('Done persisting file store');
  }

  /// Computes a hash of the provided files and returns a list of entities
  /// that were dirty.
  Future<List<File>> hashFiles(List<File> files) async {
    final List<File> dirty = <File>[];
    final Pool openFiles = Pool(kMaxOpenFiles);
    await Future.wait(<Future<void>>[
       for (File file in files) _hashFile(file, dirty, openFiles)
    ]);
    return dirty;
  }

  Future<void> _hashFile(File file, List<File> dirty, Pool pool) async {
    final PoolResource resource = await pool.request();
    try {
      final String absolutePath = file.path;
      final String previousHash = previousHashes[absolutePath];
      // If the file is missing it is assumed to be dirty.
      if (!file.existsSync()) {
        currentHashes.remove(absolutePath);
        previousHashes.remove(absolutePath);
        dirty.add(file);
        return;
      }
      final Digest digest = md5.convert(await file.readAsBytes());
      final String currentHash = digest.toString();
      if (currentHash != previousHash) {
        dirty.add(file);
      }
      currentHashes[absolutePath] = currentHash;
    } finally {
      resource.release();
    }
  }
}
