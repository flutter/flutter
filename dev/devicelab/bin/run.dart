// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/manifest.dart';
import 'package:flutter_devicelab/framework/runner.dart';
import 'package:flutter_devicelab/framework/utils.dart';

List<String> _taskNames = <String>[];

/// Runs tasks.
///
/// The tasks are chosen depending on the command-line options
/// (see [_argParser]).
Future<Null> main(List<String> rawArgs) async {
  ArgResults args;
  try {
    args = _argParser.parse(rawArgs);
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(_argParser.usage);
    exitCode = 1;
    return null;
  }

  if (!args.wasParsed('task')) {
    if (args.wasParsed('stage')) {
      final String stageName = args['stage'];
      final List<ManifestTask> tasks = loadTaskManifest().tasks;
      for (ManifestTask task in tasks) {
        if (task.stage == stageName)
          _taskNames.add(task.name);
      }
    } else if (args.wasParsed('all')) {
      final List<ManifestTask> tasks = loadTaskManifest().tasks;
      for (ManifestTask task in tasks) {
        _taskNames.add(task.name);
      }
    }
  }

  if (_taskNames.isEmpty) {
    stderr.writeln('Failed to find tasks to run based on supplied options.');
    exitCode = 1;
    return null;
  }

  final bool silent = args['silent'];

  for (String taskName in _taskNames) {
    section('Running task "$taskName"');
    final Map<String, dynamic> result = await runTask(taskName, silent: silent);

    if (!result['success'])
      exitCode = 1;

    print('Task result:');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName"');
  }
}

/// Command-line options for the `run.dart` command.
final ArgParser _argParser = new ArgParser()
  ..addMultiOption(
    'task',
    abbr: 't',
    splitCommas: true,
    help: 'Either:\n'
        ' - the name of a task defined in manifest.yaml. Example: complex_layout__start_up.\n'
        ' - the path to a Dart file corresponding to a task, which resides in bin/tasks. Example: bin/tasks/complex_layout__start_up.dart.\n'
        '\n'
        'This option may be repeated to specify multiple tasks.',
    callback: (List<String> value) {
      for (String nameOrPath in value) {
        final List<String> fragments = path.split(nameOrPath);
        final bool isDartFile = fragments.last.endsWith('.dart');

        if (fragments.length == 1 && !isDartFile) {
          // Not a path
          _taskNames.add(nameOrPath);
        } else if (!isDartFile || fragments.length != 3 || !_listsEqual(<String>['bin', 'tasks'], fragments.take(2).toList())) {
          // Unsupported executable location
          throw new FormatException('Invalid value for option -t (--task): $nameOrPath');
        } else {
          _taskNames.add(path.withoutExtension(fragments.last));
        }
      }
    },
  )
  ..addOption(
    'stage',
    abbr: 's',
    help: 'Name of the stage. Runs all tasks for that stage. '
        'The tasks and their stages are read from manifest.yaml.',
  )
  ..addFlag(
    'all',
    abbr: 'a',
    help: 'Runs all tasks defined in manifest.yaml.',
  )
  ..addMultiOption(
    'test',
    hide: true,
    splitCommas: true,
    callback: (List<String> value) {
      if (value.isNotEmpty) {
        throw const FormatException(
          'Invalid option --test. Did you mean --task (-t)?',
        );
      }
    },
  )
  ..addFlag(
    'silent',
    negatable: true,
    defaultsTo: false,
  );

bool _listsEqual(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length)
    return false;

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i])
      return false;
  }

  return true;
}
