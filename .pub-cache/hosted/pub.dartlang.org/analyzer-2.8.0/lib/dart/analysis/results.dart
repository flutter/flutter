// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';

/// The result of performing some kind of analysis on a single file. Every
/// result that implements this interface will also implement a sub-interface.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResult {
  /// The absolute and normalized path of the file that was analyzed.
  @Deprecated('Use FileResult.path instead')
  String get path;

  /// Return the session used to compute this result.
  AnalysisSession get session;

  /// The state of the results.
  @Deprecated('Check for specific Result subtypes instead')
  ResultState get state;

  /// The absolute URI of the file that was analyzed.
  @Deprecated('Use FileResult.uri instead')
  Uri get uri;
}

/// An analysis result that includes the errors computed during analysis.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResultWithErrors implements FileResult {
  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors;
}

/// The type of [InvalidResult] returned when the given URI cannot be resolved.
///
/// Clients may not extend, implement or mix-in this class.
class CannotResolveUriResult
    implements
        InvalidResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The declaration of an [Element].
abstract class ElementDeclarationResult {
  /// The [Element] that this object describes.
  Element get element;

  /// The node that declares the [element]. Depending on whether it is returned
  /// from [ResolvedLibraryResult] or [ParsedLibraryResult] it might be resolved
  /// or just parsed.
  AstNode get node;

  /// If this declaration is returned from [ParsedLibraryResult], the parsed
  /// unit that contains the [node]. Otherwise `null`.
  ParsedUnitResult? get parsedUnit;

  /// If this declaration is returned from [ResolvedLibraryResult], the
  /// resolved unit that contains the [node]. Otherwise `null`.
  ResolvedUnitResult? get resolvedUnit;
}

/// The result of computing all of the errors contained in a single file, both
/// syntactic and semantic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ErrorsResult
    implements SomeErrorsResult, AnalysisResultWithErrors {}

/// The result of computing some cheap information for a single file, when full
/// parsed file is not required, so [ParsedUnitResult] is not necessary.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FileResult implements SomeFileResult, AnalysisResult {
  /// Whether the file is a part.
  bool get isPart;

  /// Information about lines in the content.
  LineInfo get lineInfo;

  /// The absolute and normalized path of the file that was analyzed.
  @override
  String get path;

  /// The absolute URI of the file that was analyzed.
  @override
  Uri get uri;
}

/// The type of [InvalidResult] returned when the given file path is invalid,
/// for example is not absolute and normalized.
///
/// Clients may not extend, implement or mix-in this class.
class InvalidPathResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeFileResult,
        SomeParsedLibraryResult,
        SomeParsedUnitResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The base class for any invalid result.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InvalidResult {}

/// The result of building the element model for a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryElementResult implements SomeLibraryElementResult {
  /// The element of the library.
  LibraryElement get element;
}

/// The type of [InvalidResult] returned when the given element was not
/// created by the requested session.
///
/// Clients may not extend, implement or mix-in this class.
class NotElementOfThisSessionResult
    implements
        InvalidResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The type of [InvalidResult] returned when the given file is not a library,
/// but a part of a library.
///
/// Clients may not extend, implement or mix-in this class.
class NotLibraryButPartResult
    implements
        InvalidResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The type of [InvalidResult] returned when the given file path does not
/// represent the corresponding URI.
///
/// This usually happens in Bazel workspaces, when a URI is resolved to
/// a generated file, but there is also a writable file to which this URI
/// would be resolved, if there were no generated file.
///
/// Clients may not extend, implement or mix-in this class.
class NotPathOfUriResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The result of building parsed AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParsedLibraryResult
    implements SomeParsedLibraryResult, AnalysisResult {
  /// The parsed units of the library.
  List<ParsedUnitResult> get units;

  /// Return the declaration of the [element], or `null` if the [element]
  /// is synthetic. Throw [ArgumentError] if the [element] is not defined in
  /// this library.
  ElementDeclarationResult? getElementDeclaration(Element element);
}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParsedUnitResult
    implements SomeParsedUnitResult, AnalysisResultWithErrors {
  /// The content of the file that was scanned and parsed.
  String get content;

  /// The parsed, unresolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Similar to [ParsedUnitResult], but does not allow access to an analysis
/// session.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParseStringResult {
  /// The content of the file that was scanned and parsed.
  String get content;

  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors;

  /// Information about lines in the content.
  LineInfo get lineInfo;

  /// The parsed, unresolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// The result of building resolved AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ResolvedLibraryResult
    implements SomeResolvedLibraryResult, AnalysisResult {
  /// The element representing this library.
  LibraryElement get element;

  /// The type provider used when resolving the library.
  TypeProvider get typeProvider;

  /// The resolved units of the library.
  List<ResolvedUnitResult> get units;

  /// Return the declaration of the [element], or `null` if the [element]
  /// is synthetic. Throw [ArgumentError] if the [element] is not defined in
  /// this library.
  ElementDeclarationResult? getElementDeclaration(Element element);
}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ResolvedUnitResult
    implements SomeResolvedUnitResult, AnalysisResultWithErrors {
  /// The content of the file that was scanned, parsed and resolved.
  String get content;

  /// Return `true` if the file exists.
  bool get exists;

  /// The element representing the library containing the compilation [unit].
  LibraryElement get libraryElement;

  /// The type provider used when resolving the compilation [unit].
  TypeProvider get typeProvider;

  /// The type system used when resolving the compilation [unit].
  TypeSystem get typeSystem;

  /// The fully resolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// An indication of whether an analysis result is valid, and if not why.
@Deprecated('Check for specific Result subtypes instead')
enum ResultState {
  /// An indication that analysis could not be performed because the path
  /// represents a file of a type that cannot be analyzed.
  INVALID_FILE_TYPE,

  /// An indication that analysis could not be performed because the path does
  /// not represent a file. It might represent something else, such as a
  /// directory, or it might not represent anything.
  @Deprecated("Check 'get exists' flag instead")
  NOT_A_FILE,

  /// An indication that analysis could not be performed because the path does
  /// not represent the corresponding URI.
  ///
  /// This usually happens in Bazel workspaces, when a URI is resolved to
  /// a generated file, but there is also a writable file to which this URI
  /// would be resolved, if there were no generated file.
  NOT_FILE_OF_URI,

  /// An indication that analysis completed normally and the results are valid.
  VALID
}

/// The result of computing all of the errors contained in a single file, both
/// syntactic and semantic.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ErrorsResult] represents a valid result.
abstract class SomeErrorsResult {}

/// The result of computing some cheap information for a single file, when full
/// parsed file is not required, so [ParsedUnitResult] is not necessary.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [FileResult] represents a valid result.
abstract class SomeFileResult {}

/// The result of building the element model for a library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [LibraryElementResult] represents a valid result.
abstract class SomeLibraryElementResult {}

/// The result of building parsed AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ParsedLibraryResult] represents a valid result.
abstract class SomeParsedLibraryResult {}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ParsedUnitResult] represents a valid result.
abstract class SomeParsedUnitResult {}

/// The result of building resolved AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ResolvedLibraryResult] represents a valid result.
abstract class SomeResolvedLibraryResult {}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ResolvedUnitResult] represents a valid result.
abstract class SomeResolvedUnitResult {}

/// The result of building the element model for a single file.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [UnitElementResult] represents a valid result.
abstract class SomeUnitElementResult {}

/// The result of building the element model for a single file.
///
/// Clients may not extend, implement or mix-in this class.
abstract class UnitElementResult implements SomeUnitElementResult, FileResult {
  /// The element of the file.
  CompilationUnitElement get element;

  /// The signature of the library containing the [element]. This is the same
  /// signature returned by the method [AnalysisSession.getUnitElementSignature]
  /// when given the path to the compilation unit represented by the [element].
  ///
  /// The signature is based on the APIs of the files of the library (including
  /// the file itself), and the transitive closure of files imported and
  /// exported by the library. If the signature of a file has not changed, then
  /// there have been no changes that would cause any files that depend on it
  /// to need to be re-analyzed.
  @Deprecated('This field is not used by clients and will be removed')
  String get signature;
}

/// The type of [InvalidResult] returned when something is wrong, but we
/// don't know what exactly. Usually this result should not happen.
///
/// Clients may not extend, implement or mix-in this class.
class UnspecifiedInvalidResult
    implements
        InvalidResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult {}

/// The type of [InvalidResult] returned when the given URI corresponds to
/// a library that is served from an external summary bundle.
///
/// Clients may not extend, implement or mix-in this class.
class UriOfExternalLibraryResult
    implements
        InvalidResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}
