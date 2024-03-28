// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'environment.dart';
import 'proc_utils.dart';

/// Canonicalized build targets start with this prefix.
const String buildTargetPrefix = '//';

/// A suffix to build targets that recursively selects all child build targets.
const String _buildTargetGlobSuffix = '/...';

/// Information about a test build target.
final class TestTarget {
  /// Construct a test target.
  TestTarget(this.label, this.executable);

  /// The build target label. `//flutter/fml:fml_unittests`
  final String label;

  /// The executable file produced after the build target is built.
  final File executable;

  @override
  String toString() {
    return 'target=$label executable=${executable.path}';
  }
}

/// Returns test targets for a given build directory.
Future<Map<String, TestTarget>> findTestTargets(
    Environment environment, Directory buildDir) async {
  final Map<String, TestTarget> r = <String, TestTarget>{};
  final List<String> getLabelsCommandLine = <String>[
    gnBinPath(environment),
    'ls',
    buildDir.path,
    '--type=executable',
    '--testonly=true',
    '--as=label',
  ];
  final List<String> getOutputsCommandLine = <String>[
    gnBinPath(environment),
    'ls',
    buildDir.path,
    '--type=executable',
    '--testonly=true',
    '--as=output'
  ];

  // Spawn the two processes concurrently.
  final Future<ProcessRunnerResult> futureLabelsResult =
      environment.processRunner.runProcess(getLabelsCommandLine,
          workingDirectory: environment.engine.srcDir, failOk: true);
  final Future<ProcessRunnerResult> futureOutputsResult =
      environment.processRunner.runProcess(getOutputsCommandLine,
          workingDirectory: environment.engine.srcDir, failOk: true);

  // Await the futures, we need both to complete so the order doesn't matter.
  final ProcessRunnerResult labelsResult = await futureLabelsResult;
  final ProcessRunnerResult outputsResult = await futureOutputsResult;

  // Handle any process failures.
  fatalIfFailed(environment, getLabelsCommandLine, labelsResult);
  fatalIfFailed(environment, getOutputsCommandLine, outputsResult);

  // Extract the labels
  final String rawLabels = labelsResult.stdout;
  final String rawOutputs = outputsResult.stdout;
  final List<String> labels = rawLabels.split('\n');
  final List<String> outputs = rawOutputs.split('\n');
  if (labels.length != outputs.length) {
    environment.logger.fatal(
        'gn ls output is inconsistent A and B should be the same length:\nA=$labels\nB=$outputs');
  }
  // Drop the empty line at the end of the output.
  if (labels.isNotEmpty) {
    if (labels.last.isNotEmpty || outputs.last.isNotEmpty) {
      throw AssertionError('expected last line of output to be blank.');
    }
    labels.removeLast();
    outputs.removeLast();
  }
  for (int i = 0; i < labels.length; i++) {
    final String label = labels[i];
    final String output = outputs[i];
    if (label.isEmpty) {
      throw AssertionError('expected line to not be empty.');
    }
    if (output.isEmpty) {
      throw AssertionError('expected line to not be empty.');
    }
    r[label] = TestTarget(label, File(p.join(buildDir.path, output)));
  }
  return r;
}

/// Process selectors and filter allTargets for matches.
///
/// We support:
///   1) Exact label matches (the '//' prefix will be stripped off).
///   2) '/...' suffix which selects all targets that match the prefix.
Set<TestTarget> selectTargets(
    List<String> selectors, Map<String, TestTarget> allTargets) {
  final Set<TestTarget> selected = <TestTarget>{};
  for (String selector in selectors) {
    if (!selector.startsWith(buildTargetPrefix)) {
      // Insert the prefix when necessary.
      selector = '$buildTargetPrefix$selector';
    }
    final bool recursiveMatch = selector.endsWith(_buildTargetGlobSuffix);
    if (recursiveMatch) {
      // Remove the /... suffix.
      selector = selector.substring(
          0, selector.length - _buildTargetGlobSuffix.length);
      // TODO(johnmccutchan): Accelerate this by using a trie.
      for (final TestTarget target in allTargets.values) {
        if (target.label.startsWith(selector)) {
          selected.add(target);
        }
      }
    } else {
      for (final TestTarget target in allTargets.values) {
        if (target.label == selector) {
          selected.add(target);
        }
      }
    }
  }
  return selected;
}
