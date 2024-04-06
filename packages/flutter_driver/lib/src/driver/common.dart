// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
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
String get testOutputsDirectory => fs.systemTempDirectory.createTempSync('build').path;

/// Parses the arguments passed to test driver main function.
///
/// Some flags and options from `flutter drive` are propagated to the test driver
/// as arguments to its main function.
String? parseTestDriverArguments(List<String> args) {
  final ArgParser parser = ArgParser();
  parser.addOption('reporter', abbr: 'r', allowed: <String>['expanded']);
  parser.addOption('test-output-directory');
  final ArgResults argResults = parser.parse(args);
  return argResults['test-output-directory'] as String;
}
