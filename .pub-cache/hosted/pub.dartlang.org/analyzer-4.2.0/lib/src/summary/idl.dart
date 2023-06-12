// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file is an "idl" style description of the summary format.  It
/// contains abstract classes which declare the interface for reading data from
/// summaries.  It is parsed and transformed into code that implements the
/// summary format.
///
/// The code generation process introduces the following semantics:
/// - Getters of type List never return null, and have a default value of the
///   empty list.
/// - Getters of type int return unsigned 32-bit integers, never null, and have
///   a default value of zero.
/// - Getters of type String never return null, and have a default value of ''.
/// - Getters of type bool never return null, and have a default value of false.
/// - Getters of type double never return null, and have a default value of
///   `0.0`.
/// - Getters whose type is an enum never return null, and have a default value
///   of the first value declared in the enum.
///
/// Terminology used in this document:
/// - "Unlinked" refers to information that can be determined from reading a
///   single .dart file in isolation.
/// - "Prelinked" refers to information that can be determined from the defining
///   compilation unit of a library, plus direct imports, plus the transitive
///   closure of exports reachable from those libraries, plus all part files
///   constituting those libraries.
/// - "Linked" refers to all other information; in theory, this information may
///   depend on all files in the transitive import/export closure.  However, in
///   practice we expect that the number of additional dependencies will usually
///   be small, since the additional dependencies only need to be consulted for
///   type propagation, type inference, and constant evaluation, which typically
///   have short dependency chains.
///
/// Since we expect "linked" and "prelinked" dependencies to be similar, we only
/// rarely distinguish between them; most information is that is not "unlinked"
/// is typically considered "linked" for simplicity.
///
/// Except as otherwise noted, synthetic elements are not stored in the summary;
/// they are re-synthesized at the time the summary is read.
import 'package:analyzer/src/summary/base.dart' as base;
import 'package:analyzer/src/summary/base.dart' show Id, TopLevel;
import 'package:analyzer/src/summary/format.dart' as generated;

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
///
/// Information that has purely local effect (in other words, it does not affect
/// the API of the code being analyzed) is also marked as `informative`.
const informative = null;

/// Information about the context of an exception in analysis driver.
@TopLevel('ADEC')
abstract class AnalysisDriverExceptionContext extends base.SummaryClass {
  factory AnalysisDriverExceptionContext.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverExceptionContext(buffer);

  /// The exception string.
  @Id(1)
  String get exception;

  /// The state of files when the exception happened.
  @Id(3)
  List<AnalysisDriverExceptionFile> get files;

  /// The path of the file being analyzed when the exception happened.
  @Id(0)
  String get path;

  /// The exception stack trace string.
  @Id(2)
  String get stackTrace;
}

/// Information about a single file in [AnalysisDriverExceptionContext].
abstract class AnalysisDriverExceptionFile extends base.SummaryClass {
  /// The content of the file.
  @Id(1)
  String get content;

  /// The path of the file.
  @Id(0)
  String get path;
}

/// Information about a resolved unit.
@TopLevel('ADRU')
abstract class AnalysisDriverResolvedUnit extends base.SummaryClass {
  factory AnalysisDriverResolvedUnit.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverResolvedUnit(buffer);

  /// The full list of analysis errors, both syntactic and semantic.
  @Id(0)
  List<AnalysisDriverUnitError> get errors;

  /// The index of the unit.
  @Id(1)
  AnalysisDriverUnitIndex? get index;
}

/// Information about a subtype of one or more classes.
abstract class AnalysisDriverSubtype extends base.SummaryClass {
  /// The names of defined instance members.
  /// They are indexes into [AnalysisDriverUnitError.strings] list.
  /// The list is sorted in ascending order.
  @Id(1)
  List<int> get members;

  /// The name of the class.
  /// It is an index into [AnalysisDriverUnitError.strings] list.
  @Id(0)
  int get name;
}

/// Information about an error in a resolved unit.
abstract class AnalysisDriverUnitError extends base.SummaryClass {
  /// The context messages associated with the error.
  @Id(5)
  List<DiagnosticMessage> get contextMessages;

  /// The optional correction hint for the error.
  @Id(4)
  String get correction;

  /// The length of the error in the file.
  @Id(1)
  int get length;

  /// The message of the error.
  @Id(3)
  String get message;

  /// The offset from the beginning of the file.
  @Id(0)
  int get offset;

  /// The unique name of the error code.
  @Id(2)
  String get uniqueName;
}

/// Information about a resolved unit.
@TopLevel('ADUI')
abstract class AnalysisDriverUnitIndex extends base.SummaryClass {
  factory AnalysisDriverUnitIndex.fromBuffer(List<int> buffer) =>
      generated.readAnalysisDriverUnitIndex(buffer);

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  @Id(4)
  List<IndexSyntheticElementKind> get elementKinds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// index.
  @Id(7)
  List<int> get elementNameClassMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this index.
  @Id(8)
  List<int> get elementNameParameterIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this index.
  @Id(6)
  List<int> get elementNameUnitMemberIds;

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  @Id(5)
  List<int> get elementUnits;

  /// Identifier of the null string in [strings].
  @Id(1)
  int get nullStringId;

  /// List of unique element strings used in this index.  The list is sorted in
  /// ascending order, so that the client can quickly check the presence of a
  /// string in this index.
  @Id(0)
  List<String> get strings;

  /// The list of classes declared in the unit.
  @Id(19)
  List<AnalysisDriverSubtype> get subtypes;

  /// The identifiers of supertypes of elements at corresponding indexes
  /// in [subtypes].  They are indexes into [strings] list. The list is sorted
  /// in ascending order.  There might be more than one element with the same
  /// value if there is more than one subtype of this supertype.
  @Id(18)
  List<int> get supertypes;

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  @Id(2)
  List<int> get unitLibraryUris;

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  @Id(3)
  List<int> get unitUnitUris;

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  @Id(13)
  List<bool> get usedElementIsQualifiedFlags;

  /// Each item of this list is the kind of the element usage.
  @Id(10)
  List<IndexRelationKind> get usedElementKinds;

  /// Each item of this list is the length of the element usage.
  @Id(12)
  List<int> get usedElementLengths;

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  @Id(11)
  List<int> get usedElementOffsets;

  /// Each item of this list is the index into [elementUnits],
  /// [elementNameUnitMemberIds], [elementNameClassMemberIds] and
  /// [elementNameParameterIds].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this index.
  @Id(9)
  List<int> get usedElements;

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  @Id(17)
  List<bool> get usedNameIsQualifiedFlags;

  /// Each item of this list is the kind of the name usage.
  @Id(15)
  List<IndexRelationKind> get usedNameKinds;

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  @Id(16)
  List<int> get usedNameOffsets;

  /// Each item of this list is the index into [strings] for a used name.  The
  /// list is sorted in ascending order, so that the client can quickly find
  /// whether a name is used in this index.
  @Id(14)
  List<int> get usedNames;
}

/// Information about a single declaration.
abstract class AvailableDeclaration extends base.SummaryClass {
  @Id(0)
  List<AvailableDeclaration> get children;

  @Id(1)
  int get codeLength;

  @Id(2)
  int get codeOffset;

  @Id(3)
  String get defaultArgumentListString;

  @Id(4)
  List<int> get defaultArgumentListTextRanges;

  @Id(5)
  String get docComplete;

  @Id(6)
  String get docSummary;

  @Id(7)
  int get fieldMask;

  @Id(8)
  bool get isAbstract;

  @Id(9)
  bool get isConst;

  @Id(10)
  bool get isDeprecated;

  @Id(11)
  bool get isFinal;

  @Id(12)
  bool get isStatic;

  /// The kind of the declaration.
  @Id(13)
  AvailableDeclarationKind get kind;

  @Id(14)
  int get locationOffset;

  @Id(15)
  int get locationStartColumn;

  @Id(16)
  int get locationStartLine;

  /// The first part of the declaration name, usually the only one, for example
  /// the name of a class like `MyClass`, or a function like `myFunction`.
  @Id(17)
  String get name;

  @Id(18)
  List<String> get parameterNames;

  @Id(19)
  String get parameters;

  @Id(20)
  List<String> get parameterTypes;

  /// The partial list of relevance tags.  Not every declaration has one (for
  /// example, function do not currently), and not every declaration has to
  /// store one (for classes it can be computed when we know the library that
  /// includes this file).
  @Id(21)
  List<String> get relevanceTags;

  @Id(22)
  int get requiredParameterCount;

  @Id(23)
  String get returnType;

  @Id(24)
  String get typeParameters;
}

/// Enum of declaration kinds in available files.
enum AvailableDeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  EXTENSION,
  FIELD,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  METHOD,
  MIXIN,
  SETTER,
  TYPE_ALIAS,
  VARIABLE
}

/// Information about an available, even if not yet imported file.
@TopLevel('UICF')
abstract class AvailableFile extends base.SummaryClass {
  factory AvailableFile.fromBuffer(List<int> buffer) =>
      generated.readAvailableFile(buffer);

  /// Declarations of the file.
  @Id(0)
  List<AvailableDeclaration> get declarations;

  /// The Dartdoc directives in the file.
  @Id(1)
  DirectiveInfo? get directiveInfo;

  /// Exports directives of the file.
  @Id(2)
  List<AvailableFileExport> get exports;

  /// Is `true` if this file is a library.
  @Id(3)
  bool get isLibrary;

  /// Is `true` if this file is a library, and it is deprecated.
  @Id(4)
  bool get isLibraryDeprecated;

  /// Offsets of the first character of each line in the source code.
  @informative
  @Id(5)
  List<int> get lineStarts;

  /// URIs of `part` directives.
  @Id(6)
  List<String> get parts;
}

/// Information about an export directive.
abstract class AvailableFileExport extends base.SummaryClass {
  /// Combinators contained in this export directive.
  @Id(1)
  List<AvailableFileExportCombinator> get combinators;

  /// URI of the exported library.
  @Id(0)
  String get uri;
}

/// Information about a `show` or `hide` combinator in an export directive.
abstract class AvailableFileExportCombinator extends base.SummaryClass {
  /// List of names which are hidden.  Empty if this is a `show` combinator.
  @Id(1)
  List<String> get hides;

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  @Id(0)
  List<String> get shows;
}

/// Errors for a single unit.
@TopLevel('CUEr')
abstract class CiderUnitErrors extends base.SummaryClass {
  factory CiderUnitErrors.fromBuffer(List<int> buffer) =>
      generated.readCiderUnitErrors(buffer);

  @Id(0)
  List<AnalysisDriverUnitError> get errors;
}

abstract class DiagnosticMessage extends base.SummaryClass {
  /// The absolute and normalized path of the file associated with this message.
  @Id(0)
  String get filePath;

  /// The length of the source range associated with this message.
  @Id(1)
  int get length;

  /// The text of the message.
  @Id(2)
  String get message;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  @Id(3)
  int get offset;

  /// The URL of the message, if any.
  @Id(4)
  String get url;
}

/// Information about the Dartdoc directives in an [AvailableFile].
abstract class DirectiveInfo extends base.SummaryClass {
  /// The names of the defined templates.
  @Id(0)
  List<String> get templateNames;

  /// The values of the defined templates.
  @Id(1)
  List<String> get templateValues;
}

/// Enum used to indicate the kind of an index relation.
enum IndexRelationKind {
  /// Left: class.
  ///   Is ancestor of (is extended or implemented, directly or indirectly).
  /// Right: other class declaration.
  IS_ANCESTOR_OF,

  /// Left: class.
  ///   Is extended by.
  /// Right: other class declaration.
  IS_EXTENDED_BY,

  /// Left: class.
  ///   Is implemented by.
  /// Right: other class declaration.
  IS_IMPLEMENTED_BY,

  /// Left: class.
  ///   Is mixed into.
  /// Right: other class declaration.
  IS_MIXED_IN_BY,

  /// Left: method, property accessor, function, variable.
  ///   Is invoked at.
  /// Right: location.
  IS_INVOKED_BY,

  /// Left: an unnamed constructor.
  ///   Is invoked by an enum constant, without arguments, which is special
  ///   because when the name given, an empty argument list must be added.
  /// Right: location.
  IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS,

  /// Left: any element.
  ///   Is referenced (and not invoked, read/written) at.
  /// Right: location.
  IS_REFERENCED_BY,

  /// Left: a constructor.
  ///   Is referenced by a constructor tear-off at, which is special because
  ///   the name of the constructor is required (`new` for unnamed).
  /// Right: location.
  IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF,

  /// Left: unresolved member name.
  ///   Is read at.
  /// Right: location.
  IS_READ_BY,

  /// Left: unresolved member name.
  ///   Is both read and written at.
  /// Right: location.
  IS_READ_WRITTEN_BY,

  /// Left: unresolved member name.
  ///   Is written at.
  /// Right: location.
  IS_WRITTEN_BY,
}

/// When we need to reference a synthetic element in [PackageIndex] we use a
/// value of this enum to specify which kind of the synthetic element we
/// actually reference.
enum IndexSyntheticElementKind {
  /// Not a synthetic element.
  notSynthetic,

  /// The unnamed synthetic constructor a class element.
  constructor,

  /// The synthetic field element.
  field,

  /// The synthetic getter of a property introducing element.
  getter,

  /// The synthetic setter of a property introducing element.
  setter,

  /// The synthetic top-level variable element.
  topLevelVariable,

  /// The synthetic `loadLibrary` element.
  loadLibrary,

  /// The synthetic `index` getter of an enum.
  enumIndex,

  /// The synthetic `values` getter of an enum.
  enumValues,

  /// The synthetic `toString` method of an enum.
  enumToString,

  /// The containing unit itself.
  unit
}
