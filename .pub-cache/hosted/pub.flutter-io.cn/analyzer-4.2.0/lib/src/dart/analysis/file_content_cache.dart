// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// Information about the content of a file.
class FileContent {
  final String path;
  final bool exists;
  final String content;
  final String contentHash;

  FileContent._(this.path, this.exists, this.content, this.contentHash);
}

/// The cache of information about content of files.
abstract class FileContentCache {
  final ResourceProvider _resourceProvider;

  factory FileContentCache(ResourceProvider resourceProvider) {
    return _FileContentCacheImpl(resourceProvider);
  }

  factory FileContentCache.ephemeral(ResourceProvider resourceProvider) {
    return _FileContentCacheEphemeral(resourceProvider);
  }

  FileContentCache._(this._resourceProvider);

  /// Return the content of the file with the given [path].
  FileContent get(String path);

  /// Discard the cache value for the file with the given [path].
  void invalidate(String path) {}

  void invalidateAll() {}

  FileContent _read(String path) {
    Uint8List contentBytes;
    String content;
    bool exists;
    try {
      contentBytes = _resourceProvider.getFile(path).readAsBytesSync();
      content = utf8.decode(contentBytes);
      exists = true;
    } catch (_) {
      contentBytes = Uint8List(0);
      content = '';
      exists = false;
    }

    List<int> contentHashBytes = md5.convert(contentBytes).bytes;
    String contentHash = hex.encode(contentHashBytes);

    return FileContent._(path, exists, content, contentHash);
  }
}

/// [FileContentCache] that caches never.
class _FileContentCacheEphemeral extends FileContentCache {
  _FileContentCacheEphemeral(super.resourceProvider) : super._();

  @override
  FileContent get(String path) {
    return _read(path);
  }
}

/// [FileContentCache] that caches forever.
class _FileContentCacheImpl extends FileContentCache {
  final Map<String, FileContent> _pathToFile = {};

  _FileContentCacheImpl(super.resourceProvider) : super._();

  @override
  FileContent get(String path) {
    var file = _pathToFile[path];

    if (file != null) {
      return file;
    }

    file = _read(path);
    _pathToFile[path] = file;
    return file;
  }

  @override
  void invalidate(String path) {
    _pathToFile.remove(path);
  }

  @override
  void invalidateAll() {
    _pathToFile.clear();
  }
}
