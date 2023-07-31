// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

/// A collection of analysis contexts.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisContextCollection {
  /// Initialize a newly created collection of analysis contexts that can
  /// analyze the files that are included by the list of [includedPaths].
  ///
  /// All paths must be absolute and normalized.
  ///
  /// If a [resourceProvider] is given, then it will be used to access the file
  /// system, otherwise the default resource provider will be used.
  ///
  /// If [sdkPath] is given, then Dart SDK at this path will be used, otherwise
  /// the default Dart SDK will be used.
  factory AnalysisContextCollection({
    required List<String> includedPaths,
    List<String>? excludedPaths,
    ResourceProvider? resourceProvider,
    String? sdkPath,
  }) = AnalysisContextCollectionImpl;

  /// Return all of the analysis contexts in this collection.
  List<AnalysisContext> get contexts;

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext contextFor(String path);
}
