// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/io.dart';
import 'package:file/sync_io.dart';
import 'package:path/path.dart' as path;

export 'package:file/io.dart';
export 'package:file/sync_io.dart';

/// Currently active implmenetation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem fs = new LocalFileSystem();
SyncFileSystem syncFs = new SyncLocalFileSystem();

/// Restores [fs] and [syncFs] to the default local disk-based implementation.
void restoreFileSystem() {
  fs = new LocalFileSystem();
  syncFs = new SyncLocalFileSystem();
}

void useInMemoryFileSystem() {
  MemoryFileSystem memFs = new MemoryFileSystem();
  fs = memFs;
  syncFs = new SyncMemoryFileSystem(backedBy: memFs.storage);
}

/// Create the ancestor directories of a file path if they do not already exist.
void ensureDirectoryExists(String filePath) {
  String dirPath = path.dirname(filePath);

  if (syncFs.type(dirPath) == FileSystemEntityType.DIRECTORY)
    return;
  syncFs.directory(dirPath).create(recursive: true);
}
