// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../convert.dart';
import 'hash.dart';

/// An encoded representation of all file hashes.
class FileStorage {
  FileStorage(this.version, this.files);

  factory FileStorage.fromBuffer(Uint8List buffer) {
    final Map<String, dynamic>? json = castStringKeyedMap(jsonDecode(utf8.decode(buffer)));
    if (json == null) {
      throw Exception('File storage format invalid');
    }
    final int version = json['version'] as int;
    final List<Map<String, dynamic>> rawCachedFiles = (json['files'] as List<dynamic>).cast<Map<String, dynamic>>();
    final List<FileHash> cachedFiles = <FileHash>[
      for (final Map<String, dynamic> rawFile in rawCachedFiles) FileHash._fromJson(rawFile),
    ];
    return FileStorage(version, cachedFiles);
  }

  final int version;
  final List<FileHash> files;

  List<int> toBuffer() {
    final Map<String, Object> json = <String, Object>{
      'version': version,
      'files': <Object>[
        for (final FileHash file in files) file.toJson(),
      ],
    };
    return utf8.encode(jsonEncode(json));
  }
}

/// A stored file hash and path.
class FileHash {
  FileHash(this.path, this.hash);

  factory FileHash._fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('path') || !json.containsKey('hash')) {
      throw Exception('File storage format invalid');
    }
    return FileHash(json['path']! as String, json['hash']! as String);
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

/// The strategy used by [FileStore] to determine if a file has been
/// invalidated.
enum FileStoreStrategy {
  /// The [FileStore] will compute an md5 hash of the file contents.
  hash,

  /// The [FileStore] will check for differences in the file's last modified
  /// timestamp.
  timestamp,
}

/// A globally accessible cache of files.
///
/// In cases where multiple targets read the same source files as inputs, we
/// avoid recomputing or storing multiple copies of hashes by delegating
/// through this class.
///
/// This class uses either timestamps or file hashes depending on the
/// provided [FileStoreStrategy]. All information  is held in memory during
/// a build operation, and may be persisted to cache in the root build
/// directory.
///
/// The format of the file store is subject to change and not part of its API.
class FileStore {
  FileStore({
    required File cacheFile,
    required Logger logger,
    FileStoreStrategy strategy = FileStoreStrategy.hash,
  }) : _logger = logger,
       _strategy = strategy,
       _cacheFile = cacheFile;

  final File _cacheFile;
  final Logger _logger;
  final FileStoreStrategy _strategy;

  final HashMap<String, String> previousAssetKeys = HashMap<String, String>();
  final HashMap<String, String> currentAssetKeys = HashMap<String, String>();

  // The name of the file which stores the file hashes.
  static const String kFileCache = '.filecache';

  // The current version of the file cache storage format.
  static const int _kVersion = 2;

  /// Read file hashes from disk.
  void initialize() {
    _logger.printTrace('Initializing file store');
    if (!_cacheFile.existsSync()) {
      return;
    }
    Uint8List data;
    try {
      data = _cacheFile.readAsBytesSync();
    } on FileSystemException catch (err) {
      _logger.printError(
        'Failed to read file store at ${_cacheFile.path} due to $err.\n'
        'Build artifacts will not be cached. Try clearing the cache directories '
        'with "flutter clean"',
      );
      return;
    }

    FileStorage fileStorage;
    try {
      fileStorage = FileStorage.fromBuffer(data);
    } on Exception catch (err) {
      _logger.printTrace('Filestorage format changed: $err');
      _cacheFile.deleteSync();
      return;
    }
    if (fileStorage.version != _kVersion) {
      _logger.printTrace('file cache format updating, clearing old hashes.');
      _cacheFile.deleteSync();
      return;
    }
    for (final FileHash fileHash in fileStorage.files) {
      previousAssetKeys[fileHash.path] = fileHash.hash;
    }
    _logger.printTrace('Done initializing file store');
  }

  /// Persist file marks to disk for a non-incremental build.
  void persist() {
    _logger.printTrace('Persisting file store');
    if (!_cacheFile.existsSync()) {
      _cacheFile.createSync(recursive: true);
    }
    final List<FileHash> fileHashes = <FileHash>[];
    for (final MapEntry<String, String> entry in currentAssetKeys.entries) {
      fileHashes.add(FileHash(entry.key, entry.value));
    }
    final FileStorage fileStorage = FileStorage(
      _kVersion,
      fileHashes,
    );
    final List<int> buffer = fileStorage.toBuffer();
    try {
      _cacheFile.writeAsBytesSync(buffer);
    } on FileSystemException catch (err) {
      _logger.printError(
        'Failed to persist file store at ${_cacheFile.path} due to $err.\n'
        'Build artifacts will not be cached. Try clearing the cache directories '
        'with "flutter clean"',
      );
    }
    _logger.printTrace('Done persisting file store');
  }

  /// Reset `previousMarks` for an incremental build.
  void persistIncremental() {
    previousAssetKeys.clear();
    previousAssetKeys.addAll(currentAssetKeys);
    currentAssetKeys.clear();
  }

  /// Computes a diff of the provided files and returns a list of files
  /// that were dirty.
  Future<List<File>> diffFileList(List<File> files) async {
    final List<File> dirty = <File>[];
    switch (_strategy) {
      case FileStoreStrategy.hash:
        // var sw = Stopwatch()..start();
        // int totalBytes = 0;
        // for (final File file in files) {
        //   totalBytes += _hashFile(file, dirty);
        // }
        // sw.stop();
        // _logger.printStatus('Hashed $totalBytes in ${sw.elapsedMilliseconds} or ${totalBytes/sw.elapsedMilliseconds} b/ms');
        await _hashAllFiles(files, dirty);
        break;
      case FileStoreStrategy.timestamp:
        for (final File file in files) {
          _checkModification(file, dirty);
        }
        break;
    }
    return dirty;
  }

  void _checkModification(File file, List<File> dirty) {
    final String absolutePath = file.path;
    final String? previousTime = previousAssetKeys[absolutePath];

    // If the file is missing it is assumed to be dirty.
    if (!file.existsSync()) {
      currentAssetKeys.remove(absolutePath);
      previousAssetKeys.remove(absolutePath);
      dirty.add(file);
      return;
    }
    final String modifiedTime = file.lastModifiedSync().toString();
    if (modifiedTime != previousTime) {
      dirty.add(file);
    }
    currentAssetKeys[absolutePath] = modifiedTime;
  }

  // 64k is the same sized buffer used by dart:io for `File.openRead`.
  static final Uint8List _readBuffer = Uint8List(64 * 1024);

  int _hashFile(File file, List<File> dirty) {
    final String absolutePath = file.path;
    final String? previousHash = previousAssetKeys[absolutePath];
    // If the file is missing it is assumed to be dirty.
    if (!file.existsSync()) {
      currentAssetKeys.remove(absolutePath);
      previousAssetKeys.remove(absolutePath);
      dirty.add(file);
      return 0;
    }
    final int fileBytes = file.lengthSync();
    final Md5Hash hash = Md5Hash();
    RandomAccessFile? openFile;
    try {
      openFile = file.openSync();
      int bytes = 0;
      while (bytes < fileBytes) {
        final int bytesRead = openFile.readIntoSync(_readBuffer);
        hash.addChunk(_readBuffer, bytesRead);
        bytes += bytesRead;
      }
    } finally {
      openFile?.closeSync();
    }
    final Digest digest = Digest(hash.finalize().buffer.asUint8List());
    final String currentHash = digest.toString();
    if (currentHash != previousHash) {
      dirty.add(file);
    }
    currentAssetKeys[absolutePath] = currentHash;
    return fileBytes;
  }

  Future<void> _hashAllFiles(List<File> files, List<File> dirty) async {
    final Stopwatch sw = Stopwatch()..start();
    final Pool pool = Pool(4);
    final List<Future<FileHashResult>> pendingResults = <Future<FileHashResult>>[];
    for (final File file in files) {
      final PoolResource resource = await pool.request();
      try {
        final String absolutePath = file.path;
        final String? previousHash = previousAssetKeys[absolutePath];
        // If the file is missing it is assumed to be dirty.
        if (!file.existsSync()) {
          currentAssetKeys.remove(absolutePath);
          previousAssetKeys.remove(absolutePath);
          dirty.add(file);
          continue;
        }
        pendingResults.add(Isolate.run<FileHashResult>(_runWrapper(FileHashArgs(absolutePath, previousHash)), debugName: absolutePath));
      } finally {
        resource.release();
      }
    }
    final List<FileHashResult> results = await Future.wait(pendingResults);

    int totalBytes = 0;
    for (final FileHashResult result in results) {
      if (result.dirty) {
        dirty.add(_cacheFile.fileSystem.file(result.absolutePath));
      }
      currentAssetKeys[result.absolutePath] = result.currentHash;
      totalBytes += result.bytes;
    }
    sw.stop();
    _logger.printStatus('Hashed $totalBytes in ${sw.elapsedMilliseconds} or ${totalBytes/sw.elapsedMilliseconds} b/ms');
  }

  static FileHashResult Function()  _runWrapper(FileHashArgs args) {
    return () {
      return hashSingleFile(args);
    };
  }

  static FileHashResult hashSingleFile(FileHashArgs args) {
    final io.File file = io.File(args.absolutePath);
    final int fileBytes = file.lengthSync();
    final Md5Hash hash = Md5Hash();
    RandomAccessFile? openFile;
    try {
      openFile = file.openSync();
      int bytes = 0;
      while (bytes < fileBytes) {
        final int bytesRead = openFile.readIntoSync(_readBuffer);
        hash.addChunk(_readBuffer, bytesRead);
        bytes += bytesRead;
      }
    } finally {
      openFile?.closeSync();
    }
    final Digest digest = Digest(hash.finalize().buffer.asUint8List());
    final String currentHash = digest.toString();
    final bool dirty = currentHash != args.previousHash;
    return FileHashResult(dirty, currentHash, args.absolutePath, fileBytes);
  }
}

@visibleForTesting
class FileHashResult {
  const FileHashResult(this.dirty, this.currentHash, this.absolutePath, this.bytes);

  final String absolutePath;
  final bool dirty;
  final String currentHash;
  final int bytes;
}

@visibleForTesting
class FileHashArgs {
  const FileHashArgs(this.absolutePath, this.previousHash);

  final String absolutePath;
  final String? previousHash;
}
