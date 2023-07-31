// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/util.dart';
import 'package:path/path.dart' as p;

/// Shared IO sink for standard error reporting.
/// Visible for testing
IOSink errorSink = stderr;

/// Shared IO sink for standard out reporting.
/// Visible for testing
IOSink outSink = stdout;

/// Collect all lintable files, recursively, under this [path] root, ignoring
/// links.
Iterable<File> collectFiles(String path) {
  List<File> files = [];

  var file = File(path);
  if (file.existsSync()) {
    files.add(file);
  } else {
    var directory = Directory(path);
    if (directory.existsSync()) {
      for (var entry
          in directory.listSync(recursive: true, followLinks: false)) {
        var relative = p.relative(entry.path, from: directory.path);

        if (isLintable(entry) && !isInHiddenDir(relative)) {
          files.add(entry as File);
        }
      }
    }
  }

  return files;
}

/// Returns `true` if this [entry] is a Dart file.
bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);

/// Returns `true` if this relative path is a hidden directory.
bool isInHiddenDir(String relative) =>
    p.split(relative).any((part) => part.startsWith("."));

/// Returns `true` if this relative path is a hidden directory.
bool isLintable(FileSystemEntity file) =>
    file is File && (isDartFile(file) || isPubspecFile(file));

/// Returns `true` if this [entry] is a pubspec file.
bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));

/// Synchronously read the contents of the file at the given [path] as a string.
String readFile(String path) => File(path).readAsStringSync();
