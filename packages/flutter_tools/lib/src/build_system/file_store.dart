// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../convert.dart';
import 'build_system.dart';

/// The default threshold for file chunking is 250 KB, or about the size of `framework.dart`.
const int kDefaultFileChunkThresholdBytes = 250000;

/// An encoded representation of all file hashes.
class FileStorage {
  FileStorage(this.version, this.files);

  factory FileStorage.fromBuffer(Uint8List buffer) {
    final Map<String, dynamic> json = castStringKeyedMap(jsonDecode(utf8.decode(buffer)));
    final int version = json['version'] as int;
    final List<Map<String, Object>> rawCachedFiles = (json['files'] as List<dynamic>).cast<Map<String, Object>>();
    final List<FileHash> cachedFiles = <FileHash>[
      for (final Map<String, Object> rawFile in rawCachedFiles) FileHash.fromJson(rawFile),
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
    @required File cacheFile,
    @required Logger logger,
    FileStoreStrategy strategy = FileStoreStrategy.hash,
    int fileChunkThreshold = kDefaultFileChunkThresholdBytes,
  }) : _logger = logger,
       _strategy = strategy,
       _cacheFile = cacheFile,
       _fileChunkThreshold = fileChunkThreshold;

  final File _cacheFile;
  final Logger _logger;
  final FileStoreStrategy _strategy;
  final int _fileChunkThreshold;

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
        final Pool openFiles = Pool(kMaxOpenFiles);
        await Future.wait(<Future<void>>[
          for (final File file in files) _hashFile(file, dirty, openFiles)
        ]);
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
    final String previousTime = previousAssetKeys[absolutePath];

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

  Future<void> _hashFile(File file, List<File> dirty, Pool pool) async {
    final PoolResource resource = await pool.request();
    try {
      final String absolutePath = file.path;
      final String previousHash = previousAssetKeys[absolutePath];
      // If the file is missing it is assumed to be dirty.
      if (!file.existsSync()) {
        currentAssetKeys.remove(absolutePath);
        previousAssetKeys.remove(absolutePath);
        dirty.add(file);
        return;
      }
      Digest digest;
      final int fileBytes = file.lengthSync();
      // For files larger than a given threshold, chunk the conversion.
      if (fileBytes > _fileChunkThreshold) {
        final StreamController<Digest> digests = StreamController<Digest>();
        final ByteConversionSink inputSink = md5.startChunkedConversion(digests);
        await file.openRead().forEach(inputSink.add);
        inputSink.close();
        digest = await digests.stream.last;
      } else {
        digest = md5.convert(await file.readAsBytes());
      }
      final String currentHash = digest.toString();
      if (currentHash != previousHash) {
        dirty.add(file);
      }
      currentAssetKeys[absolutePath] = currentHash;
    } finally {
      resource.release();
    }
  }
}
