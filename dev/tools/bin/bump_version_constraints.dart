// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Platform, exit, stderr, stdout;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main(List<String> arguments) {
  const FileSystem fileSystem = LocalFileSystem();
  final File script = fileSystem.file(io.Platform.script).absolute;
  final Directory flutterRoot = script.parent.parent.parent.parent;

  run(
    arguments,
    fileSystem: fileSystem,
    flutterRoot: flutterRoot,
    stdout: io.stdout,
    stderr: io.stderr,
    exit: io.exit,
  );
}

void run(
  List<String> arguments, {
  required FileSystem fileSystem,
  required Directory flutterRoot,
  required StringSink stdout,
  required StringSink stderr,
  required void Function(int) exit,
}) {
  final parser = ArgParser();

  late final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('ERROR: $e');
    _usage(parser, stderr, exit);
    return;
  }

  if (options.rest.length != 2) {
    stderr.writeln(
      'ERROR: Expected exactly two arguments specifying the old SDK constraint and the new SDK constraint.',
    );
    _usage(parser, stderr, exit);
    return;
  }

  final String oldVersion = options.rest[0];
  final String newVersion = options.rest[1];

  var updatedCount = 0;
  var errorCount = 0;

  final List<File> pubspecs = _findPubspecs(flutterRoot, stderr);

  for (final file in pubspecs) {
    final String relativePath = fileSystem.path.relative(file.path, from: flutterRoot.path);
    try {
      final String content = file.readAsStringSync();
      final yamlEditor = YamlEditor(content);

      final YamlNode doc = loadYamlNode(content);
      if (doc is! YamlMap) {
        stderr.writeln('Error: $relativePath is not a valid YAML map.');
        errorCount++;
        continue;
      }

      var fileUpdated = false;
      if (doc.containsKey('environment')) {
        final Object? env = doc['environment'];
        if (env is YamlMap && env.containsKey('sdk')) {
          final Object? currentSdk = env['sdk'];
          if (currentSdk == newVersion) {
            // Already updated.
          } else if (currentSdk == oldVersion) {
            yamlEditor.update(<String>['environment', 'sdk'], newVersion);
            fileUpdated = true;
          } else {
            stdout.writeln(
              'Skipping $relativePath: SDK constraint "$currentSdk" does not match expected "$oldVersion".',
            );
          }
        }
      }

      if (fileUpdated) {
        var newContent = yamlEditor.toString();
        if (!newContent.endsWith('\n')) {
          newContent += '\n';
        }
        file.writeAsStringSync(newContent);
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

List<File> _findPubspecs(Directory dir, StringSink stderr) {
  final FileSystem fileSystem = dir.fileSystem;
  final result = <File>[];
  void search(Directory currentDir) {
    try {
      for (final FileSystemEntity entity in currentDir.listSync(followLinks: false)) {
        if (entity is Directory) {
          final String name = fileSystem.path.basename(entity.path);
          if (name.startsWith('.') || name == 'build') {
            continue;
          }
          search(entity);
        } else if (entity is File) {
          if (fileSystem.path.basename(entity.path) == 'pubspec.yaml') {
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

void _usage(ArgParser parser, StringSink stderr, void Function(int) exit) {
  stderr.writeln(
    'Usage: dart dev/tools/bin/bump_version_constraints.dart <old_sdk_constraint> <new_sdk_constraint>',
  );
  stderr.writeln('Example: dart dev/tools/bin/bump_version_constraints.dart ^3.10.0-0 ^3.11.0-0');
  exit(1);
}
