// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

/// A representation of a body of code and the context in which the code is to
/// be analyzed.
///
/// The body of code is represented as a collection of files and directories, as
/// defined by the list of included paths. If the list of included paths
/// contains one or more directories, then zero or more files or directories
/// within the included directories can be excluded from analysis, as defined by
/// the list of excluded paths.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisContext {
  /// The analysis options used to control the way the code is analyzed.
  AnalysisOptions get analysisOptions;

  /// Return the context root from which this context was created.
  ContextRoot get contextRoot;

  /// Return the currently active analysis session.
  AnalysisSession get currentSession;

  /// The root directory of the SDK against which files of this context are
  /// analyzed, or `null` if the SDK is not directory based.
  Folder? get sdkRoot;

  /// Return a [Future] that completes after pending file changes are applied,
  /// so that [currentSession] can be used to compute results.
  ///
  /// The value is the set of all files that are potentially affected by
  /// the pending changes. This set can be both wider than the set of analyzed
  /// files (because it may include files imported from other packages, and
  /// which are on the import path from a changed file to an analyzed file),
  /// and narrower than the set of analyzed files (because only files that
  /// were previously accessed are considered to be known and affected).
  Future<List<String>> applyPendingFileChanges();

  /// Schedules the file with the [path] to be read before producing new
  /// analysis results.
  ///
  /// The file is expected to be a Dart file, reporting non-Dart files, such
  /// as configuration files `analysis_options.yaml`, `package_config.json`,
  /// etc will not re-create analysis contexts.
  ///
  /// This will invalidate any previously returned [AnalysisSession], to
  /// get a new analysis session apply pending file changes:
  /// ```dart
  /// analysisContext.changeFile(...);
  /// await analysisContext.applyPendingFileChanges();
  /// var analysisSession = analysisContext.currentSession;
  /// var resolvedUnit = analysisSession.getResolvedUnit(...);
  /// ```
  void changeFile(String path);
}
