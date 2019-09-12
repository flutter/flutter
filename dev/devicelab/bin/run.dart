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
Future<void> main(List<String> rawArgs) async {
  ArgResults args;
  try {
    args = _argParser.parse(rawArgs);
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln('Usage:\n');
    stderr.writeln(_argParser.usage);
    exitCode = 1;
    return;
  }

  if (!args.wasParsed('task')) {
    if (args.wasParsed('stage') || args.wasParsed('all')) {
      addTasks(
        tasks: loadTaskManifest().tasks,
        args: args,
        taskNames: _taskNames,
      );
    }
  }

  if (args.wasParsed('list')) {
    for (int i = 0; i < _taskNames.length; i++) {
      print('${(i + 1).toString().padLeft(3)} - ${_taskNames[i]}');
    }
    exitCode = 0;
    return;
  }

  if (_taskNames.isEmpty) {
    stderr.writeln('Failed to find tasks to run based on supplied options.');
    exitCode = 1;
    return;
  }

  final bool silent = args['silent'];
  final String localEngine = args['local-engine'];
  final String localEngineSrcPath = args['local-engine-src-path'];

  for (String taskName in _taskNames) {
    section('Running task "$taskName"');
    final Map<String, dynamic> result = await runTask(
      taskName,
      silent: silent,
      localEngine: localEngine,
      localEngineSrcPath: localEngineSrcPath,
    );

    print('Task result:');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName"');

    if (!result['success']) {
      exitCode = 1;
      if (args['exit']) {
        return;
      }
    }
  }
}

void addTasks({
  List<ManifestTask> tasks,
  ArgResults args,
  List<String> taskNames,
}) {
  if (args.wasParsed('continue-from')) {
    final int index = tasks.indexWhere((ManifestTask task) => task.name == args['continue-from']);
    if (index == -1) {
      throw Exception('Invalid task name "${args['continue-from']}"');
    }
    tasks.removeRange(0, index);
  }
  // Only start skipping if user specified a task to continue from
  final String stage = args['stage'];
  for (ManifestTask task in tasks) {
    final bool isQualifyingStage = stage == null || task.stage == stage;
    final bool isQualifyingHost = !args['match-host-platform'] || task.isSupportedByHost();
    if (isQualifyingHost && isQualifyingStage) {
      taskNames.add(task.name);
    }
  }
}

/// Command-line options for the `run.dart` command.
final ArgParser _argParser = ArgParser()
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
          throw FormatException('Invalid value for option -t (--task): $nameOrPath');
        } else {
          _taskNames.add(path.withoutExtension(fragments.last));
        }
      }
    },
  )
  ..addFlag(
    'all',
    abbr: 'a',
    help: 'Runs all tasks defined in manifest.yaml in alphabetical order.',
  )
  ..addOption(
    'continue-from',
    abbr: 'c',
    help: 'With --all or --stage, continue from the given test.',
  )
  ..addFlag(
    'exit',
    defaultsTo: true,
    help: 'Exit on the first test failure.',
  )
  ..addOption(
    'local-engine',
    help: 'Name of a build output within the engine out directory, if you\n'
          'are building Flutter locally. Use this to select a specific\n'
          'version of the engine if you have built multiple engine targets.\n'
          'This path is relative to --local-engine-src-path/out.',
  )
  ..addFlag(
    'list',
    abbr: 'l',
    help: 'Don\'t actually run the tasks, but list out the tasks that would\n'
          'have been run, in the order they would have run.',
  )
  ..addOption(
    'local-engine-src-path',
    help: 'Path to your engine src directory, if you are building Flutter\n'
          'locally. Defaults to \$FLUTTER_ENGINE if set, or tries to guess at\n'
          'the location based on the value of the --flutter-root option.',
  )
  ..addFlag(
    'match-host-platform',
    defaultsTo: true,
    help: 'Only run tests that match the host platform (e.g. do not run a\n'
          'test with a `required_agent_capabilities` value of "mac/android"\n'
          'on a windows host). Each test publishes its'
          '`required_agent_capabilities`\nin the `manifest.yaml` file.',
  )
  ..addOption(
    'stage',
    abbr: 's',
    help: 'Name of the stage. Runs all tasks for that stage. The tasks and\n'
          'their stages are read from manifest.yaml.',
  )
  ..addFlag(
    'silent',
    negatable: true,
    defaultsTo: false,
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
