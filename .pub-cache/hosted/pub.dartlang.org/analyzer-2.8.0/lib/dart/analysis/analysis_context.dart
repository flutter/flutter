// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/workspace/workspace.dart';

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

  /// Return the workspace for containing the context root.
  @Deprecated('Use contextRoot.workspace instead')
  Workspace get workspace;
}
