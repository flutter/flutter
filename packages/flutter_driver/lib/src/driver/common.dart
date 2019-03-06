// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

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
/// Tests should write any output files to this directory. Defaults to the path
/// set in the FLUTTER_TEST_OUTPUTS_DIR environment variable, or `build` if
/// unset.
String get testOutputsDirectory => Platform.environment['FLUTTER_TEST_OUTPUTS_DIR'] ?? 'build';
