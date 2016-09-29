// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'package:flutter_devicelab/framework/manifest.dart';
import 'package:flutter_devicelab/framework/runner.dart';
import 'package:flutter_devicelab/framework/utils.dart';

/// Runs tasks.
///
/// The tasks are chosen depending on the command-line options
/// (see [_argParser]).
Future<Null> main(List<String> rawArgs) async {
  ArgResults args;
  try {
    args = _argParser.parse(rawArgs);
  } on FormatException catch(error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(_argParser.usage);
    exitCode = 1;
    return null;
  }

  List<String> taskNames = <String>[];
  if (args.wasParsed('task')) {
    taskNames.addAll(args['task']);
  } else if (args.wasParsed('stage')) {
    String stageName = args['stage'];
    List<ManifestTask> tasks = loadTaskManifest().tasks;
    for (ManifestTask task in tasks) {
      if (task.stage == stageName)
        taskNames.add(task.name);
    }
  } else if (args.wasParsed('all')) {
    List<ManifestTask> tasks = loadTaskManifest().tasks;
    for (ManifestTask task in tasks) {
      taskNames.add(task.name);
    }
  }

  if (taskNames.isEmpty) {
    stderr.writeln('Failed to find tasks to run based on supplied options.');
    exitCode = 1;
    return null;
  }

  bool silent = args['silent'];

  for (String taskName in taskNames) {
    section('Running task "$taskName"');
    Map<String, dynamic> result = await runTask(taskName, silent: silent);

    if (!result['success'])
      exitCode = 1;

    print('Task result:');
    print(new JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName"');
  }
}

/// Command-line options for the `run.dart` command.
final ArgParser _argParser = new ArgParser()
  ..addOption(
    'task',
    abbr: 't',
    allowMultiple: true,
    splitCommas: true,
    help: 'Name of the task to run. This option may be repeated to '
    'specify multiple tasks. A task selected by name does not have to be '
    'defined in manifest.yaml. It only needs a Dart executable in bin/tasks.',
  )
  ..addOption(
    'stage',
    abbr: 's',
    help: 'Name of the stage. Runs all tasks for that stage. '
        'The tasks and their stages are read from manifest.yaml.',
  )
  ..addOption(
    'all',
    abbr: 'a',
    help: 'Runs all tasks defined in manifest.yaml.',
  )
  ..addOption(
    'test',
    hide: true,
    allowMultiple: true,
    splitCommas: true,
    callback: (List<String> value) {
      if (value.isNotEmpty) {
        throw new FormatException(
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
