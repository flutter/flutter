// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import '../../util/io.dart';
import '../configuration.dart';
import '../engine.dart';
import '../reporter.dart';
import '../reporter/compact.dart';
import '../reporter/expanded.dart';
import '../reporter/github.dart';
import '../reporter/json.dart';

/// Constructs a reporter for the provided engine with the provided
/// configuration.
typedef ReporterFactory = Reporter Function(Configuration, Engine, StringSink);

/// Container for a reporter description and corresponding factory.
class ReporterDetails {
  final String description;
  final ReporterFactory factory;
  ReporterDetails(this.description, this.factory);
}

/// All reporters and their corresponding details.
final UnmodifiableMapView<String, ReporterDetails> allReporters =
    UnmodifiableMapView<String, ReporterDetails>(_allReporters);

final _allReporters = <String, ReporterDetails>{
  'expanded': ReporterDetails(
      'A separate line for each update.',
      (config, engine, sink) => ExpandedReporter.watch(engine, sink,
          color: config.color,
          printPath: config.paths.length > 1 ||
              Directory(config.paths.single.testPath).existsSync(),
          printPlatform: config.suiteDefaults.runtimes.length > 1)),
  'compact': ReporterDetails(
      'A single line, updated continuously.',
      (config, engine, sink) => CompactReporter.watch(engine, sink,
          color: config.color,
          printPath: config.paths.length > 1 ||
              Directory(config.paths.single.testPath).existsSync(),
          printPlatform: config.suiteDefaults.runtimes.length > 1)),
  'github': ReporterDetails(
      'A custom reporter for GitHub Actions (the default reporter when running on GitHub Actions).',
      (config, engine, sink) => GithubReporter.watch(engine, sink,
          printPath: config.paths.length > 1 ||
              Directory(config.paths.single.testPath).existsSync(),
          printPlatform: config.suiteDefaults.runtimes.length > 1)),
  'json': ReporterDetails(
      'A machine-readable format (see '
      'https://dart.dev/go/test-docs/json_reporter.md).',
      (config, engine, sink) =>
          JsonReporter.watch(engine, sink, isDebugRun: config.debug)),
};

final defaultReporter = inTestTests
    ? 'expanded'
    : inGithubContext
        ? 'github'
        : canUseSpecialChars
            ? 'compact'
            : 'expanded';

/// **Do not call this function without express permission from the test package
/// authors**.
///
/// This globally registers a reporter.
void registerReporter(String name, ReporterDetails reporterDetails) {
  _allReporters[name] = reporterDetails;
}
