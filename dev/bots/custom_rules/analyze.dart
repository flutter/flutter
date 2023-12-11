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

/// Analyzes the given `flutterRootDirectory` containing the flutter framework
/// source files, with the given [AnalyzeRule]s.
///
/// If a compilation unit can not be resolved, this function ignores the
/// corresponding dart source file and logs an error using [foundError].
Future<void> analyzeFrameworkWithRules(String flutterRootDirectory, List<AnalyzeRule> rules) async {
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
/// about code that violates the best practices in a [ResolvedUnitResult].
///
/// The [analyzeFrameworkWithRules] function scans and analyzes the specified
/// source directory using the dart analyzer package, and applies custom rules
/// defined in the form of this interface on each resulting [ResolvedUnitResult].
/// The [reportViolations] method will be called at the end, once all
/// [ResolvedUnitResult]s are parsed.
///
/// Implementers can assume each [ResolvedUnitResult] is valid compilable dart
/// code, as the caller only applies the custom rules once the code passes
/// `flutter analyze`.
abstract class AnalyzeRule {
  /// Applies this rule to the given [ResolvedUnitResult] (typically a file), and
  /// collects information about violations occurred in the compilation unit.
  void applyTo(ResolvedUnitResult unit);

  /// Reports all violations in the resolved compilation units [applyTo] was
  /// called on, if any.
  ///
  /// This method is called once all [ResolvedUnitResult] are parsed.
  ///
  /// The implementation typically calls [foundErrors] to report violations.
  void reportViolations(String workingDirectory);
}
