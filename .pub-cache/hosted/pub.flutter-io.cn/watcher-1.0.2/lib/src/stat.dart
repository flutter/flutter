// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A function that takes a file path and returns the last modified time for
/// the file at that path.
typedef MockTimeCallback = DateTime Function(String path);

MockTimeCallback? _mockTimeCallback;

/// Overrides the default behavior for accessing a file's modification time
/// with [callback].
///
/// The OS file modification time has pretty rough granularity (like a few
/// seconds) which can make for slow tests that rely on modtime. This lets you
/// replace it with something you control.
void mockGetModificationTime(MockTimeCallback callback) {
  _mockTimeCallback = callback;
}

/// Gets the modification time for the file at [path].
/// Completes with `null` if the file does not exist.
Future<DateTime?> modificationTime(String path) async {
  var mockTimeCallback = _mockTimeCallback;
  if (mockTimeCallback != null) {
    return mockTimeCallback(path);
  }

  final stat = await FileStat.stat(path);
  if (stat.type == FileSystemEntityType.notFound) return null;
  return stat.modified;
}
