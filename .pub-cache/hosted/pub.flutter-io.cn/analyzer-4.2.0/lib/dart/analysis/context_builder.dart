// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';

/// A utility class used to build an analysis context based on a context root.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ContextBuilder {
  /// Initialize a newly created context builder. If a [resourceProvider] is
  /// given, then it will be used to access the file system, otherwise the
  /// default resource provider will be used.
  factory ContextBuilder({ResourceProvider resourceProvider}) =
      ContextBuilderImpl;

  /// Return an analysis context corresponding to the given [contextRoot].
  ///
  /// If a set of [declaredVariables] is provided, the values will be used to
  /// map the variable names found in `fromEnvironment` invocations to the
  /// constant value that will be returned. If none is given, then no variables
  /// will be defined.
  ///
  /// If a list of [librarySummaryPaths] is provided, then the summary files at
  /// those paths will be used, when possible, when analyzing the libraries
  /// contained in the summary files.
  ///
  /// If an [sdkPath] is provided, and if it is a valid path to a directory
  /// containing a valid SDK, then the SDK in the referenced directory will be
  /// used when analyzing the code in the context.
  ///
  /// If an [sdkSummaryPath] is provided, then that file will be used as the
  /// summary file for the SDK.
  AnalysisContext createContext(
      {required ContextRoot contextRoot,
      DeclaredVariables? declaredVariables,
      List<String>? librarySummaryPaths,
      String? sdkPath,
      String? sdkSummaryPath});
}
