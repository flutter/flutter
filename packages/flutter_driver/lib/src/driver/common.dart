// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';

/// The file system implementation used by this library.
///
/// See [useMemoryFileSystemForTesting] and [restoreFileSystem].
FileSystem fs = const LocalFileSystem();

/// Overrides the file system so it can be tested without hitting the hard
/// drive.
void useMemoryFileSystemForTesting() {
  fs = MemoryFileSystem();
}

/// Restores the file system to the default local file system implementation.
void restoreFileSystem() {
  fs = const LocalFileSystem();
}

/// Flutter Driver test output directory.
///
/// Tests should write any output files to this directory. Defaults `build`.
String get defaultTestOutputDirectory => fs.systemTempDirectory.createTempSync('build').path;


/// Parses the arguments passed to test driver main function.
///
/// Some flags and options from `flutter drive` are propagated to the test driver
/// as arguments to its main function.
String getTestOutputDirectory(List<String> args) {
  for (final String arg in args){
    if (arg=='--test-output-directory') {
      return args[args.indexOf(arg) + 1];
    }
  }
  return defaultTestOutputDirectory;
}
