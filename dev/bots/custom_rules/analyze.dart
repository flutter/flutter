// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:path/path.dart' as path;

import '../utils.dart';

/// Analyzes the given `flutterRootDirectory` with the given set of
/// [AnalyzeRule]s.
///
/// If a compilation unit can not be resolved, this function ignores the
/// corresponding dart source file and logs an error using [foundError].
Future<void> analyzeDirectoryWithRules(String flutterRootDirectory, List<AnalyzeRule> rules) async {
  final String flutterLibPath = path.canonicalize('$flutterRootDirectory/packages/flutter/lib');
  if (!Directory(flutterLibPath).existsSync()) {
    foundError(<String>['Analyzer error: the specified $flutterLibPath does not exist.']);
  }
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[flutterLibPath],
    excludedPaths: <String>[path.canonicalize('$flutterLibPath/fix_data')],
  );

  final List<String> analyzerErrors = <String>[];
  for (final AnalysisContext context in collection.contexts) {
    final Iterable<String> analyzedFilePaths = context.contextRoot.analyzedFiles();
    final AnalysisSession session = context.currentSession;

    for (final String filePath in analyzedFilePaths) {
      final SomeResolvedUnitResult unit = await session.getResolvedUnit(filePath);
      if (unit is ResolvedUnitResult) {
        for (final AnalyzeRule rule in rules) {
          rule.applyTo(unit);
        }
      } else {
        analyzerErrors.add('Analyzer error: file $unit could not be resolved. Expected "ResolvedUnitResult", got ${unit.runtimeType}.');
      }
    }
  }

  if (analyzerErrors.isNotEmpty) {
    foundError(analyzerErrors);
  }
  for (final AnalyzeRule verifier in rules) {
    verifier.reportViolations(flutterRootDirectory);
  }
}

/// An interface that defines a set of best practices, and collects information
/// about code that violates the defined best practices when it is applied to
/// dart source files.
///
/// The [analyzeDirectoryWithRules] function uses this interface to verify that
/// a collection of resolved compilation units ([ResolvedUnitResult]s) follow
/// the defined best practices.
abstract class AnalyzeRule {
  /// Applies this rule to the given resolved compilation unit (which is
  /// typically a file) and collects information about violations occurred in
  /// the compilation unit if any.
  void applyTo(ResolvedUnitResult unit);

  /// Reports all violations in the resolved compilation units [applyTo] was
  /// called on.
  ///
  /// The implementation typically calls [foundErrors] to report violations.
  void reportViolations(String workingDirectory);
}
