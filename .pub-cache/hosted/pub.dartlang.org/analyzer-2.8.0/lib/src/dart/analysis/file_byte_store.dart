// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/fletcher16.dart';
import 'package:path/path.dart';

/// The request that is sent from the main isolate to the clean-up isolate.
class CacheCleanUpRequest {
  final String cachePath;
  final int maxSizeBytes;
  final SendPort replyTo;

  CacheCleanUpRequest(this.cachePath, this.maxSizeBytes, this.replyTo);
}

/// [ByteStore] that stores values as files and performs cache eviction.
///
/// Only the process that manages the cache, e.g. Analysis Server, should use
/// this class. Other processes, e.g. Analysis Server plugins, should use
/// [FileByteStore] instead and let the main process to perform eviction.
class EvictingFileByteStore implements ByteStore {
  static bool _cleanUpSendPortShouldBePrepared = true;
  static SendPort? _cleanUpSendPort;

  final String _cachePath;
  final int _maxSizeBytes;
  final FileByteStore _fileByteStore;

  int _bytesWrittenSinceCleanup = 0;
  bool _evictionIsolateIsRunning = false;

  EvictingFileByteStore(this._cachePath, this._maxSizeBytes)
      : _fileByteStore = FileByteStore(_cachePath) {
    _requestCacheCleanUp();
  }

  @override
  Uint8List? get(String key) => _fileByteStore.get(key);

  @override
  void put(String key, Uint8List bytes) {
    _fileByteStore.put(key, bytes);
    // Update the current size.
    _bytesWrittenSinceCleanup += bytes.length;
    if (_bytesWrittenSinceCleanup > _maxSizeBytes ~/ 8) {
      _requestCacheCleanUp();
    }
  }

  /// If the cache clean up process has not been requested yet, request it.
  Future<void> _requestCacheCleanUp() async {
    if (_cleanUpSendPortShouldBePrepared) {
      _cleanUpSendPortShouldBePrepared = false;
      ReceivePort response = ReceivePort();
      await Isolate.spawn(_cacheCleanUpFunction, response.sendPort);
      _cleanUpSendPort = await response.first as SendPort;
    } else {
      while (_cleanUpSendPort == null) {
        await Future.delayed(Duration(milliseconds: 100), () {});
      }
    }

    if (!_evictionIsolateIsRunning) {
      _evictionIsolateIsRunning = true;
      try {
        ReceivePort response = ReceivePort();
        _cleanUpSendPort!.send(
            CacheCleanUpRequest(_cachePath, _maxSizeBytes, response.sendPort));
        await response.first;
      } finally {
        _evictionIsolateIsRunning = false;
        _bytesWrittenSinceCleanup = 0;
      }
    }
  }

  /// This function is started in a new isolate, receives cache folder clean up
  /// requests and evicts older files from the folder.
  static void _cacheCleanUpFunction(Object message) {
    var initialReplyTo = message as SendPort;
    ReceivePort port = ReceivePort();
    initialReplyTo.send(port.sendPort);
    port.listen((request) {
      if (request is CacheCleanUpRequest) {
        _cleanUpFolder(request.cachePath, request.maxSizeBytes);
        // Let the client know that we're done.
        request.replyTo.send(true);
      }
    });
  }

  static void _cleanUpFolder(String cachePath, int maxSizeBytes) {
    List<FileSystemEntity> resources;
    try {
      resources = Directory(cachePath).listSync(recursive: true);
    } catch (_) {
      return;
    }

    // Prepare the list of files and their statistics.
    List<File> files = <File>[];
    Map<File, FileStat> fileStatMap = {};
    int currentSizeBytes = 0;
    for (FileSystemEntity resource in resources) {
      if (resource is File) {
        try {
          final FileStat fileStat = resource.statSync();
          // Make sure that the file was not deleted out from under us (a return
          // value of FileSystemEntityType.notFound).
          if (fileStat.type == FileSystemEntityType.file) {
            files.add(resource);
            fileStatMap[resource] = fileStat;
            currentSizeBytes += fileStat.size;
          }
        } catch (_) {}
      }
    }
    files.sort((a, b) {
      return fileStatMap[a]!.accessed.millisecondsSinceEpoch -
          fileStatMap[b]!.accessed.millisecondsSinceEpoch;
    });

    // Delete files until the current size is less than the max.
    for (File file in files) {
      if (currentSizeBytes < maxSizeBytes) {
        break;
      }
      try {
        file.deleteSync();
      } catch (_) {}
      currentSizeBytes -= fileStatMap[file]!.size;
    }
  }
}

/// [ByteStore] that stores values as files.
class FileByteStore implements ByteStore {
  static final FileByteStoreValidator _validator = FileByteStoreValidator();
  static final _dotCodeUnit = '.'.codeUnitAt(0);

  final String _cachePath;
  final String _tempSuffix;
  final Map<String, Uint8List> _writeInProgress = {};
  final FuturePool _pool = FuturePool(20);

  /// If the same cache path is used from more than one isolate of the same
  /// process, then a unique [tempNameSuffix] must be provided for each isolate.
  FileByteStore(this._cachePath, {String tempNameSuffix = ''})
      : _tempSuffix =
            '-temp-$pid${tempNameSuffix.isEmpty ? '' : '-$tempNameSuffix'}';

  @override
  Uint8List? get(String key) {
    if (!_canShard(key)) return null;

    var bytes = _writeInProgress[key];
    if (bytes != null) {
      return bytes;
    }

    try {
      var shardPath = _getShardPath(key);
      var path = join(shardPath, key);
      var bytes = File(path).readAsBytesSync();
      return _validator.getData(bytes);
    } catch (_) {
      // ignore exceptions
      return null;
    }
  }

  @override
  void put(String key, Uint8List bytes) {
    if (!_canShard(key)) return;

    _writeInProgress[key] = bytes;

    final wrappedBytes = _validator.wrapData(bytes);

    // We don't wait for the write and rename to complete.
    _pool.execute(() async {
      var tempPath = join(_cachePath, '$key$_tempSuffix');
      var tempFile = File(tempPath);
      try {
        await tempFile.writeAsBytes(wrappedBytes);
        var shardPath = _getShardPath(key);
        await Directory(shardPath).create(recursive: true);
        var path = join(shardPath, key);
        await tempFile.rename(path);
        if (_writeInProgress[key] == bytes) {
          _writeInProgress.remove(key);
        }
      } catch (_) {
        // ignore exceptions
      }
    });
  }

  String _getShardPath(String key) {
    var shardName = key.substring(0, 2);
    return join(_cachePath, shardName);
  }

  static bool _canShard(String key) {
    return key.length > 2 &&
        key.codeUnitAt(0) != _dotCodeUnit &&
        key.codeUnitAt(1) != _dotCodeUnit;
  }
}

/// Generally speaking, we cannot guarantee that any data written into a file
/// will stay the same - there is always a chance of a hardware problem, file
/// system problem, truncated data, etc.
///
/// So, we need to embed some validation into data itself. This class append the
/// version and the checksum to data.
class FileByteStoreValidator {
  static const List<int> _VERSION = [0x01, 0x00];

  /// If the [rawBytes] have the valid version and checksum, extract and
  /// return the data from it. Otherwise return `null`.
  Uint8List? getData(Uint8List rawBytes) {
    // There must be at least the version and the checksum in the raw bytes.
    if (rawBytes.length < 4) {
      return null;
    }
    int len = rawBytes.length - 4;

    // Check the version.
    if (rawBytes[len + 0] != _VERSION[0] || rawBytes[len + 1] != _VERSION[1]) {
      return null;
    }

    // Check the checksum of the data.
    var data = rawBytes.sublist(0, len);
    int checksum = fletcher16(data);
    if (rawBytes[len + 2] != checksum & 0xFF ||
        rawBytes[len + 3] != (checksum >> 8) & 0xFF) {
      return null;
    }

    // OK, the data is probably valid.
    return data;
  }

  /// Return bytes that include the given [data] plus the current version and
  /// the checksum of the [data].
  Uint8List wrapData(Uint8List data) {
    int len = data.length;
    var bytes = Uint8List(len + 4);

    // Put the data.
    bytes.setRange(0, len, data);

    // Put the version.
    bytes[len + 0] = _VERSION[0];
    bytes[len + 1] = _VERSION[1];

    // Put the checksum of the data.
    int checksum = fletcher16(data);
    bytes[len + 2] = checksum & 0xFF;
    bytes[len + 3] = (checksum >> 8) & 0xFF;

    return bytes;
  }
}

class FuturePool {
  int _available;
  List waiting = [];

  FuturePool(this._available);

  void execute(Future Function() fn) {
    if (_available > 0) {
      _run(fn);
    } else {
      waiting.add(fn);
    }
  }

  void _run(Future Function() fn) {
    _available--;

    fn().whenComplete(() {
      _available++;

      if (waiting.isNotEmpty) {
        _run(waiting.removeAt(0));
      }
    });
  }
}
