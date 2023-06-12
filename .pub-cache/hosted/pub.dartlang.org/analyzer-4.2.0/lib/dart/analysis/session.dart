// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';

/// A consistent view of the results of analyzing one or more files.
///
/// The methods in this class that return analysis results will throw an
/// [InconsistentAnalysisException] if the result to be returned might be
/// inconsistent with any previously returned results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisSession {
  /// The analysis context that created this session.
  AnalysisContext get analysisContext;

  /// The declared environment variables.
  DeclaredVariables get declaredVariables;

  /// Return the [ResourceProvider] that is used to access the file system.
  ResourceProvider get resourceProvider;

  /// Return the URI converter used to convert between URI's and file paths.
  UriConverter get uriConverter;

  /// Return a future that will complete with information about the errors
  /// contained in the file with the given absolute, normalized [path].
  ///
  /// If the file cannot be analyzed by this session, then the result will have
  /// a result state indicating the nature of the problem.
  Future<SomeErrorsResult> getErrors(String path);

  /// Return information about the file at the given absolute, normalized
  /// [path].
  SomeFileResult getFile(String path);

  /// Return a future that will complete with information about the library
  /// element representing the library with the given [uri].
  Future<SomeLibraryElementResult> getLibraryByUri(String uri);

  /// Return information about the results of parsing units of the library file
  /// with the given absolute, normalized [path].
  SomeParsedLibraryResult getParsedLibrary(String path);

  /// Return information about the results of parsing units of the library file
  /// with the given library [element].
  SomeParsedLibraryResult getParsedLibraryByElement(LibraryElement element);

  /// Return information about the results of parsing the file with the given
  /// absolute, normalized [path].
  SomeParsedUnitResult getParsedUnit(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the given absolute,
  /// normalized [path].
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  Future<SomeResolvedLibraryResult> getResolvedLibraryByElement(
      LibraryElement element);

  /// Return a future that will complete with information about the results of
  /// resolving the file with the given absolute, normalized [path].
  Future<SomeResolvedUnitResult> getResolvedUnit(String path);

  /// Return a future that will complete with information about the results of
  /// building the element model for the file with the given absolute,
  /// normalized [path].
  Future<SomeUnitElementResult> getUnitElement(String path);
}

/// The exception thrown by an [AnalysisSession] if a result is requested that
/// might be inconsistent with any previously returned results.
class InconsistentAnalysisException extends AnalysisException {
  InconsistentAnalysisException()
      : super('Requested result might be inconsistent with previously '
            'returned results');
}
