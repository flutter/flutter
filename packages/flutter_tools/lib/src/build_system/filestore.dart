// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../convert.dart';
import '../globals.dart';
import 'build_system.dart';

/// An encoded representation of all file hashes.
class FileStorage {
  FileStorage(this.version, this.files);

  factory FileStorage.fromBuffer(Uint8List buffer) {
    final Map<String, Object> json = jsonDecode(utf8.decode(buffer));
    final int version = json['version'];
    final List<Object> rawCachedFiles = json['files'];
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
    return FileHash(json['path'], json['hash']);
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

/// A globally accessible cache that determines if files are up to date.
///
/// In cases where multiple targets read the same source files as inputs, we
/// avoid recomputing or storing multiple copies of stamps by delegating
/// through this class. All file stamps are held in memory during a build
/// operation, and persisted to cache in the build directory.
///
/// By default, md5 hashes are used as the file stamp. [_timestampModeEnabled]
/// can be used to configure faster checks for incremental builds.
///
/// The format of the file store is subject to change and not part of its API.
class FileStore {
  FileStore(this.environment, this.fileSystem, [this._timestampModeEnabled = false]) :
    _cachePath = environment.buildDir.childFile(_kFileCache).path;

  final FileSystem fileSystem;
  final String _cachePath;
  final bool _timestampModeEnabled;

  final Environment environment;
  final HashMap<String, String> previousStamps = HashMap<String, String>();
  final HashMap<String, String> currentStamps = HashMap<String, String>();

  // The name of the file which stores the file hashes.
  static const String _kFileCache = '.filecache';

  // The current version of the file cache storage format.
  static const int _kVersion = 2;

  /// Read file store from disk.
  void initialize() {
    printTrace('Initializing file store');
    final File cacheFile = fileSystem.file(_cachePath);
    if (!cacheFile.existsSync()) {
      return;
    }
    List<int> data;
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
      printTrace('file cache format updating, clearing old files.');
      cacheFile.deleteSync();
      return;
    }
    for (FileHash fileHash in fileStorage.files) {
      previousStamps[fileHash.path] = fileHash.hash;
    }
    printTrace('Done initializing file store');
  }

  /// Persist file store to disk.
  void persist() {
    printTrace('Persisting file store');
    final File cacheFile = fileSystem.file(_cachePath);
    if (!cacheFile.existsSync()) {
      cacheFile.createSync(recursive: true);
    }
    final List<FileHash> fileHashes = <FileHash>[];
    for (MapEntry<String, String> entry in currentStamps.entries) {
      fileHashes.add(FileHash(entry.key, entry.value));
    }
    final FileStorage fileStorage = FileStorage(
      _kVersion,
      fileHashes,
    );
    final Uint8List buffer = fileStorage.toBuffer();
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
  Future<List<File>> updateFiles(List<File> files) async {
    final List<File> dirty = <File>[];
    if (!_timestampModeEnabled) {
      final Pool openFiles = Pool(kMaxOpenFiles);
      await Future.wait(<Future<void>>[
        for (File file in files) _hashFile(file, dirty, openFiles)
      ]);
    } else {
      for (File file in files) {
        _timestampCheckFile(file, dirty);
      }
    }
    return dirty;
  }

  void _timestampCheckFile(File file, List<File> dirty) {
    final String absolutePath = file.path;
    final String previousTimestamp = previousStamps[absolutePath];
    // If the file is missing it is assumed to be dirty.
    if (!file.existsSync()) {
      currentStamps.remove(absolutePath);
      previousStamps.remove(absolutePath);
      dirty.add(file);
      return;
    }
    final String currentTimestamp = file.lastModifiedSync().millisecondsSinceEpoch.toString();
    if (currentTimestamp != previousTimestamp) {
      dirty.add(file);
    }
    currentStamps[absolutePath] = currentTimestamp;
  }

  Future<void> _hashFile(File file, List<File> dirty, Pool pool) async {
    final PoolResource resource = await pool.request();
    try {
      final String absolutePath = file.path;
      final String previousHash = previousStamps[absolutePath];
      // If the file is missing it is assumed to be dirty.
      if (!file.existsSync()) {
        currentStamps.remove(absolutePath);
        previousStamps.remove(absolutePath);
        dirty.add(file);
        return;
      }
      final Digest digest = md5.convert(await file.readAsBytes());
      final String currentHash = digest.toString();
      if (currentHash != previousHash) {
        dirty.add(file);
      }
      currentStamps[absolutePath] = currentHash;
    } finally {
      resource.release();
    }
  }
}
