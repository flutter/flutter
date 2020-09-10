// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/ab.dart';
import 'package:flutter_devicelab/framework/manifest.dart';
import 'package:flutter_devicelab/framework/runner.dart';
import 'package:flutter_devicelab/framework/utils.dart';

ArgResults args;

List<String> _taskNames = <String>[];

/// Suppresses standard output, prints only standard error output.
bool silent;

/// The build of the local engine to use.
///
/// Required for A/B test mode.
String localEngine;

/// The path to the engine "src/" directory.
String localEngineSrcPath;

/// Whether to exit on first test failure.
bool exitOnFirstTestFailure;

/// The device-id to run test on.
String deviceId;

/// Runs tasks.
///
/// The tasks are chosen depending on the command-line options
/// (see [_argParser]).
Future<void> main(List<String> rawArgs) async {
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

  silent = args['silent'] as bool;
  localEngine = args['local-engine'] as String;
  localEngineSrcPath = args['local-engine-src-path'] as String;
  exitOnFirstTestFailure = args['exit'] as bool;
  deviceId = args['device-id'] as String;

  if (args.wasParsed('ab')) {
    await _runABTest();
  } else {
    await _runTasks();
  }
}

Future<void> _runTasks() async {
  for (final String taskName in _taskNames) {
    section('Running task "$taskName"');
    final Map<String, dynamic> result = await runTask(
      taskName,
      silent: silent,
      localEngine: localEngine,
      localEngineSrcPath: localEngineSrcPath,
      deviceId: deviceId,
    );

    print('Task result:');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName"');

    if (!(result['success'] as bool)) {
      exitCode = 1;
      if (exitOnFirstTestFailure) {
        return;
      }
    }
  }
}

Future<void> _runABTest() async {
  final int runsPerTest = int.parse(args['ab'] as String);

  if (_taskNames.length > 1) {
    stderr.writeln('When running in A/B test mode exactly one task must be passed but got ${_taskNames.join(', ')}.\n');
    stderr.writeln(_argParser.usage);
    exit(1);
  }

  if (!args.wasParsed('local-engine')) {
    stderr.writeln('When running in A/B test mode --local-engine is required.\n');
    stderr.writeln(_argParser.usage);
    exit(1);
  }

  final String taskName = _taskNames.single;

  print('$taskName A/B test. Will run $runsPerTest times.');

  final ABTest abTest = ABTest(localEngine, taskName);
  for (int i = 1; i <= runsPerTest; i++) {
    section('Run #$i');

    print('Running with the default engine (A)');
    final Map<String, dynamic> defaultEngineResult = await runTask(
      taskName,
      silent: silent,
      deviceId: deviceId,
    );

    print('Default engine result:');
    print(const JsonEncoder.withIndent('  ').convert(defaultEngineResult));

    if (!(defaultEngineResult['success'] as bool)) {
      stderr.writeln('Task failed on the default engine.');
      exit(1);
    }

    abTest.addAResult(defaultEngineResult);

    print('Running with the local engine (B)');
    final Map<String, dynamic> localEngineResult = await runTask(
      taskName,
      silent: silent,
      localEngine: localEngine,
      localEngineSrcPath: localEngineSrcPath,
      deviceId: deviceId,
    );

    print('Task localEngineResult:');
    print(const JsonEncoder.withIndent('  ').convert(localEngineResult));

    if (!(localEngineResult['success'] as bool)) {
      stderr.writeln('Task failed on the local engine.');
      exit(1);
    }

    abTest.addBResult(localEngineResult);

    if (!silent && i < runsPerTest) {
      section('A/B results so far');
      print(abTest.printSummary());
    }
  }
  abTest.finalize();

  final File jsonFile = _uniqueFile(args['ab-result-file'] as String ?? 'ABresults#.json');
  jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(abTest.jsonMap));

  if (!silent) {
    section('Raw results');
    print(abTest.rawResults());
  }

  section('Final A/B results');
  print(abTest.printSummary());

  print('');
  print('Results saved to ${jsonFile.path}');
}

File _uniqueFile(String filenameTemplate) {
  final List<String> parts = filenameTemplate.split('#');
  if (parts.length != 2) {
    return File(filenameTemplate);
  }
  File file = File(parts[0] + parts[1]);
  int i = 1;
  while (file.existsSync()) {
    file = File(parts[0]+i.toString()+parts[1]);
    i++;
  }
  return file;
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
  final String stage = args['stage'] as String;
  for (final ManifestTask task in tasks) {
    final bool isQualifyingStage = stage == null || task.stage == stage;
    final bool isQualifyingHost = !(args['match-host-platform'] as bool) || task.isSupportedByHost();
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
        ' - the name of a task defined in manifest.yaml.\n'
        '   Example: complex_layout__start_up.\n'
        ' - the path to a Dart file corresponding to a task,\n'
        '   which resides in bin/tasks.\n'
        '   Example: bin/tasks/complex_layout__start_up.dart.\n'
        '\n'
        'This option may be repeated to specify multiple tasks.',
    callback: (List<String> value) {
      for (final String nameOrPath in value) {
        final List<String> fragments = path.split(nameOrPath);
        final bool isDartFile = fragments.last.endsWith('.dart');

        if (fragments.length == 1 && !isDartFile) {
          // Not a path
          _taskNames.add(nameOrPath);
        } else if (!isDartFile || !path.equals(path.dirname(nameOrPath), path.join('bin', 'tasks'))) {
          // Unsupported executable location
          throw FormatException('Invalid value for option -t (--task): $nameOrPath');
        } else {
          _taskNames.add(path.withoutExtension(fragments.last));
        }
      }
    },
  )
  ..addOption(
    'device-id',
    abbr: 'd',
    help: 'Target device id (prefixes are allowed, names are not supported).\n'
          'The option will be ignored if the test target does not run on a\n'
          'mobile device. This still respects the device operating system\n'
          'settings in the test case, and will results in error if no device\n'
          'with given ID/ID prefix is found.',
  )
  ..addOption(
    'ab',
    help: 'Runs an A/B test comparing the default engine with the local\n'
          'engine build for one task. This option does not support running\n'
          'multiple tasks. The value is the number of times to run the task.\n'
          'The task is expected to be a benchmark that reports score keys.\n'
          'The A/B test collects the metrics collected by the test and\n'
          'produces a report containing averages, noise, and the speed-up\n'
          'between the two engines. --local-engine is required when running\n'
          'an A/B test.',
    callback: (String value) {
      if (value != null && int.tryParse(value) == null) {
        throw ArgParserException('Option --ab must be a number, but was "$value".');
      }
    },
  )
  ..addOption(
    'ab-result-file',
    help: 'The filename in which to place the json encoded results of an A/B test.\n'
          'The filename may contain a single # character to be replaced by a sequence\n'
          'number if the name already exists.',
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
          'This path is relative to --local-engine-src-path/out. This option\n'
          'is required when running an A/B test (see the --ab option).',
  )
  ..addFlag(
    'list',
    abbr: 'l',
    help: "Don't actually run the tasks, but list out the tasks that would\n"
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
          'on a windows host). Each test publishes its '
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
