// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory, File, IOOverrides, Link;

import 'package:flutter_tools/src/base/file_system.dart';

/// An [IOOverrides] that can delegate to [FileSystem] implementation if provided.
///
/// Does not override any of the socket facilities.
///
/// Do not provide a [LocalFileSystem] as a delegate. Since internally this calls
/// out to `dart:io` classes, it will result in a stack overflow error as the
/// IOOverrides and LocalFileSystem call each other endlessly.
///
/// The only safe delegate types are those that do not call out to `dart:io`,
/// like the [MemoryFileSystem].
class FlutterIOOverrides extends io.IOOverrides {
  FlutterIOOverrides({ FileSystem? fileSystem })
    : _fileSystemDelegate = fileSystem;

  final FileSystem? _fileSystemDelegate;

  @override
  io.Directory createDirectory(String path) {
    if (_fileSystemDelegate == null) {
      return super.createDirectory(path);
    }
    return _fileSystemDelegate.directory(path);
  }

  @override
  io.File createFile(String path) {
    if (_fileSystemDelegate == null) {
      return super.createFile(path);
    }
    return _fileSystemDelegate.file(path);
  }

  @override
  io.Link createLink(String path) {
    if (_fileSystemDelegate == null) {
      return super.createLink(path);
    }
    return _fileSystemDelegate.link(path);
  }

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) {
    if (_fileSystemDelegate == null) {
      return super.fsWatch(path, events, recursive);
    }
    return _fileSystemDelegate.file(path).watch(events: events, recursive: recursive);
  }

  @override
  bool fsWatchIsSupported() {
    if (_fileSystemDelegate == null) {
      return super.fsWatchIsSupported();
    }
    return _fileSystemDelegate.isWatchSupported;
  }

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) {
    if (_fileSystemDelegate == null) {
      return super.fseGetType(path, followLinks);
    }
    return _fileSystemDelegate.type(path, followLinks: followLinks);
  }

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) {
    if (_fileSystemDelegate == null) {
      return super.fseGetTypeSync(path, followLinks);
    }
    return _fileSystemDelegate.typeSync(path, followLinks: followLinks);
  }

  @override
  Future<bool> fseIdentical(String path1, String path2) {
    if (_fileSystemDelegate == null) {
      return super.fseIdentical(path1, path2);
    }
    return _fileSystemDelegate.identical(path1, path2);
  }

  @override
  bool fseIdenticalSync(String path1, String path2) {
    if (_fileSystemDelegate == null) {
      return super.fseIdenticalSync(path1, path2);
    }
    return _fileSystemDelegate.identicalSync(path1, path2);
  }

  @override
  io.Directory getCurrentDirectory() {
    if (_fileSystemDelegate == null) {
      return super.getCurrentDirectory();
    }
    return _fileSystemDelegate.currentDirectory;
  }

  @override
  io.Directory getSystemTempDirectory() {
    if (_fileSystemDelegate == null) {
      return super.getSystemTempDirectory();
    }
    return _fileSystemDelegate.systemTempDirectory;
  }

  @override
  void setCurrentDirectory(String path) {
    if (_fileSystemDelegate == null) {
      return super.setCurrentDirectory(path);
    }
    _fileSystemDelegate.currentDirectory = path;
  }

  @override
  Future<FileStat> stat(String path) {
    if (_fileSystemDelegate == null) {
      return super.stat(path);
    }
    return _fileSystemDelegate.stat(path);
  }

  @override
  FileStat statSync(String path) {
    if (_fileSystemDelegate == null) {
      return super.statSync(path);
    }
    return _fileSystemDelegate.statSync(path);
  }
}
