// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';

import 'common.dart';
import 'pipeline.dart';
import 'steps/compile_tests_step.dart';
import 'steps/run_tests_step.dart';
import 'utils.dart';

/// Runs build and test steps.
///
/// This command is designed to be invoked by the LUCI build graph. However, it
/// is also usable locally.
///
/// Usage:
///
///     felt run name_of_build_step
class RunCommand extends Command<bool> with ArgUtils<bool> {
  RunCommand() {
    argParser.addFlag(
      'list',
      abbr: 'l',
      defaultsTo: false,
      help: 'Lists all available build steps.',
    );
    argParser.addFlag(
      'require-skia-gold',
      defaultsTo: false,
      help: 'Whether we require Skia Gold to be available or not. When this '
            'flag is true, the tests will fail if Skia Gold is not available.',
    );
  }

  @override
  String get name => 'run';

  bool get isListSteps => boolArg('list');

  /// When running screenshot tests, require Skia Gold to be available and
  /// reachable.
  bool get requireSkiaGold => boolArg('require-skia-gold');

  @override
  String get description => 'Runs a build step.';

  /// Build steps to run, in order specified.
  List<String> get stepNames => argResults!.rest;

  @override
  FutureOr<bool> run() async {
    // All available build steps.
    final Map<String, PipelineStep> buildSteps = <String, PipelineStep>{
      'compile_tests': CompileTestsStep(),
      for (final String browserName in kAllBrowserNames)
        'run_tests_$browserName': RunTestsStep(
          browserName: browserName,
          isDebug: false,
          doUpdateScreenshotGoldens: false,
          requireSkiaGold: requireSkiaGold,
          overridePathToCanvasKit: null,
        ),
    };

    if (isListSteps) {
      buildSteps.keys.forEach(print);
      return true;
    }

    if (stepNames.isEmpty) {
      throw UsageException('No build steps specified.', argParser.usage);
    }

    final List<String> unrecognizedStepNames = <String>[];
    for (final String stepName in stepNames) {
      if (!buildSteps.containsKey(stepName)) {
        unrecognizedStepNames.add(stepName);
      }
    }
    if (unrecognizedStepNames.isNotEmpty) {
      io.stderr.writeln(
        'Unknown build steps specified: ${unrecognizedStepNames.join(', ')}',
      );
      return false;
    }

    final List<PipelineStep> steps = <PipelineStep>[];
    print('Running steps ${steps.join(', ')}');
    for (final String stepName in stepNames) {
      steps.add(buildSteps[stepName]!);
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    final Pipeline pipeline = Pipeline(steps: steps);
    await pipeline.run();
    stopwatch.stop();
    print('Finished running steps in ${stopwatch.elapsedMilliseconds / 1000} seconds.');

    return true;
  }
}
