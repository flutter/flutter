// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  final parser = ArgParser();

  late final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('ERROR: $e');
    _usage(parser);
  }

  if (options.rest.length != 1) {
    stderr.writeln('ERROR: Expected exactly one argument specifying the new SDK constraint.');
    _usage(parser);
  }

  final String newVersion = options.rest.first;

  final File script = File.fromUri(Platform.script).absolute;
  final Directory flutterRoot = script.parent.parent.parent.parent;

  var updatedCount = 0;
  var errorCount = 0;

  final List<File> pubspecs = _findPubspecs(flutterRoot);

  for (final file in pubspecs) {
    final String relativePath = path.relative(file.path, from: flutterRoot.path);
    try {
      final List<String> lines = file.readAsLinesSync();
      var inEnvironment = false;
      var fileUpdated = false;

      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final String trimmed = line.trim();

        if (trimmed.startsWith('environment:')) {
          inEnvironment = true;
          continue;
        }

        if (inEnvironment) {
          if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
            inEnvironment = false;
          } else if (trimmed.startsWith('sdk:')) {
            final int sdkIndex = line.indexOf('sdk:');
            final String indentation = line.substring(0, sdkIndex);
            final newLine = '${indentation}sdk: $newVersion';
            if (line != newLine) {
              lines[i] = newLine;
              fileUpdated = true;
            }
            inEnvironment = false;
          }
        }
      }

      if (fileUpdated) {
        file.writeAsStringSync('${lines.join('\n')}\n');
        stdout.writeln('Updated $relativePath');
        updatedCount++;
      }
    } catch (e) {
      stderr.writeln('Error updating $relativePath: $e');
      errorCount++;
    }
  }

  stdout.writeln('Done. Updated $updatedCount pubspec.yaml file${updatedCount == 1 ? '' : 's'}.');
  if (errorCount > 0) {
    exit(1);
  }
}

List<File> _findPubspecs(Directory dir) {
  final result = <File>[];
  void search(Directory currentDir) {
    try {
      for (final FileSystemEntity entity in currentDir.listSync(followLinks: false)) {
        if (entity is Directory) {
          final String name = path.basename(entity.path);
          if (name.startsWith('.')) {
            continue;
          }
          search(entity);
        } else if (entity is File) {
          if (path.basename(entity.path) == 'pubspec.yaml') {
            result.add(entity);
          }
        }
      }
    } catch (e) {
      stderr.writeln('Error traversing ${currentDir.path}: $e');
    }
  }

  search(dir);
  return result;
}

void _usage(ArgParser parser) {
  stderr.writeln('Usage: dart dev/tools/bin/bump_version_constraints.dart <new_sdk_constraint>');
  stderr.writeln('Example: dart dev/tools/bin/bump_version_constraints.dart ^3.13.0-0');
  exit(1);
}
