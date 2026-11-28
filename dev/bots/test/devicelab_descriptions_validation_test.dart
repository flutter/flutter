// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;
import 'package:path/path.dart' as p;

import './common.dart';

class _TaskEntry {
  _TaskEntry({
    required this.hasHostPlatform,
    required this.hasTargetPlatform,
    required this.hasDescription,
  });

  bool hasHostPlatform;
  bool hasTargetPlatform;
  bool hasDescription;
}

void main() {
  final String flutterRoot = () {
    io.Directory current = io.Directory.current;
    while (!io.File(p.join(current.path, 'DEPS')).existsSync()) {
      if (current.path == current.parent.path) {
        fail(
          'Could not find flutter repository root (${io.Directory.current.path} -> ${current.path})',
        );
      }
      current = current.parent;
    }
    return current.path;
  }();

  final descriptionsFile = io.File(p.join(flutterRoot, 'dev', 'devicelab', 'DESCRIPTIONS.md'));
  final documentedTasks = <String, _TaskEntry>{};

  String? currentTask;

  for (final String line in descriptionsFile.readAsLinesSync()) {
    if (line.startsWith('### [')) {
      final RegExpMatch? match = RegExp(r'### \[([^\]]+)\]').firstMatch(line);
      if (match != null) {
        currentTask = match.group(1);
        if (currentTask != null) {
          documentedTasks[currentTask] = _TaskEntry(
            hasHostPlatform: false,
            hasTargetPlatform: false,
            hasDescription: false,
          );
        }
      }
    } else if (currentTask != null) {
      final _TaskEntry? entry = documentedTasks[currentTask];
      if (entry != null) {
        if (line.trim().startsWith('- host_platform:')) {
          entry.hasHostPlatform = true;
        } else if (line.trim().startsWith('- target_platform:')) {
          entry.hasTargetPlatform = true;
        } else if (line.trim().startsWith('- description:')) {
          entry.hasDescription = true;
        }
      }
    }
  }

  group('DeviceLab DESCRIPTIONS.md validation', () {
    final tasksDir = io.Directory(p.join(flutterRoot, 'dev', 'devicelab', 'bin', 'tasks'));
    final List<io.File> taskFiles = tasksDir
        .listSync()
        .whereType<io.File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    for (final file in taskFiles) {
      final String taskName = p.basenameWithoutExtension(file.path);
      test(
        'DeviceLab task "$taskName" must have a complete description in dev/devicelab/DESCRIPTIONS.md',
        () {
          final _TaskEntry? entry = documentedTasks[taskName];
          if (entry == null) {
            fail(
              'Task "$taskName" (${file.path}) is missing an entry in dev/devicelab/DESCRIPTIONS.md.',
            );
          }
          expect(
            entry.hasHostPlatform,
            isTrue,
            reason:
                'Task "$taskName" is missing "- host_platform:" in dev/devicelab/DESCRIPTIONS.md.',
          );
          expect(
            entry.hasTargetPlatform,
            isTrue,
            reason:
                'Task "$taskName" is missing "- target_platform:" in dev/devicelab/DESCRIPTIONS.md.',
          );
          expect(
            entry.hasDescription,
            isTrue,
            reason:
                'Task "$taskName" is missing "- description:" in dev/devicelab/DESCRIPTIONS.md.',
          );
        },
      );
    }
  });
}
