// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/ast_binary_tag.dart';

class AstBundle {
  /// The blob with libraries.
  ///
  /// Items of [libraryOffsets] point here.
  List<AstLibrary>? libraries;

  /// Pointers to libraries in the [libraries] blob.
  ///
  /// We need these offsets because we read [ResolutionLibrary] only
  /// partially - URI, offsets of units, but nothing about units. So,
  /// we don't know where one library ends, and another starts.
  ///
  /// TODO(scheglov) too complicated? Read all?
  List<Uint30>? libraryOffsets;

  /// [stringTableOffset] points here.
  StringTableFormat? stringTable;

  /// We record `uint32` to know exactly the location of this field.
  /// It is always at the end of the byte buffer `-4`.
  Uint32? librariesOffset;

  /// We record `uint32` to know exactly the location of this field.
  /// It is always at the end of the byte buffer `-0`.
  Uint32? stringTableOffset;
}

class AstLibrary {
  /// The name from the `library` directive, might be the empty string.
  StringRef? name;

  /// The offset `+1` of the name in the `library` directive.
  /// So, `0` if absent, decoded then into `-1`.
  Uint30? nameOffset;

  /// The length of the name in the `library` directive, `0` if absent.
  Uint30? nameLength;

  /// Offsets pointing at [AstUnitFormat.headerOffset].
  List<Uint30>? unitOffsets;
}

class AstUnitFormat {
  /// The header of the unit, read when create the reader.
  /// [headerOffset] points here.
  AstUnitHeader? header;

  /// [AstUnitIndexItem.offset] from [indexOfMembers] points into here.
  Object? declarations;

  /// The offset of [header].
  Uint30? headerOffset;

  /// The index of declarations in the unit.
  List<AstUnitIndexItem>? indexOfMembers;
}

class AstUnitHeader {
  /// Four elements: package major/minor, override major/minor.
  /// The override is `+1`, if `0` then no override.
  FormatUint32List? languageVersion;

  /// Encoded feature set.
  FormatUint32List? featureSet;
}

class AstUnitIndexItem {
  /// The offset in [AstUnitFormat.declarations].
  Uint30? offset;

  /// The tag of the declaration from [Tag].
  Byte? tag;

  /// If not [Tag.TopLevelVariableDeclaration], the name of the declaration.
  /// Otherwise absent, [topLevelVariableNames] instead.
  StringRef? name;

  /// If [Tag.TopLevelVariableDeclaration], the names of the variables.
  /// Otherwise absent, [name] instead.
  List<StringRef>? topLevelVariableNames;
}

class Byte {}

class FormatUint32List {}

class ResolutionBundle {
  /// The blob with libraries.
  ///
  /// [libraryOffsets] points here.
  List<ResolutionLibrary>? libraries;

  /// Pointers to libraries in the [libraries] blob.
  ///
  /// We need these offsets because we read [ResolutionLibrary] only
  /// partially - URI, offsets of units, but nothing about units. So,
  /// we don't know where one library ends, and another starts.
  ///
  /// TODO(scheglov) too complicated? Read all?
  List<Uint30>? libraryOffsets;

  /// The index of the parent reference, so we can add its name from
  /// the [referenceNames]. Is `0` for the root.
  ///
  /// [referencesOffset] points here.
  List<Uint30>? referenceParents;

  /// The name of this component of a reference, e.g. `String` or `@class`.
  /// Is the empty string for the root.
  List<StringRef>? referenceNames;

  /// We record `uint32` to know exactly the location of this field.
  /// It is always at the end of the byte buffer `-8`.
  Uint32? librariesOffset;

  /// We record `uint32` to know exactly the location of this field.
  /// It is always at the end of the byte buffer `-4`.
  ///
  /// Points at [referenceParents].
  Uint32? referencesOffset;

  /// We record `uint32` to know exactly the location of this field.
  /// It is always at the end of the byte buffer `-0`.
  Uint32? stringTableOffset;
}

class ResolutionLibrary {
  /// The blob with units.
  List<ResolutionUnitFormat>? units;

  /// [ResolutionBundle.libraryOffsets] points here.
  StringRef? uriStr;

  /// Indexes of exported elements in [ResolutionBundle.referenceNames].
  List<Uint30>? exportedReferences;

  /// Absolute offsets pointing at [ResolutionUnitFormat.uriStr].
  List<Uint30>? unitOffsets;
}

class ResolutionUnitFormat {
  /// [ResolutionLibrary.unitOffsets] points here.
  StringRef? uriStr;

  Byte? isSynthetic;

  Byte? isPart;

  /// If [isPart], the URI that is used in the `part` directive.
  /// The empty string for the defining unit.
  StringRef? partUriStr;

  /// The offset of the resolution information for directives.
  /// For example resolution of metadata.
  Uint30? directivesResolutionOffset;

  /// Offsets of the resolution information for each declaration.
  List<Uint30>? declarationOffsets;
}

/// The reference to a [String], in form of [Uint30].
class StringRef {}

/// Any string is witten as [Uint30] and is an index into the string table.
/// So, we can write each unique string only once.
class StringTableFormat {
  /// The blob with WTF8 encoded strings.
  Object? strings;

  /// The length of [strings] in bytes. So, we know how much to go back in
  /// the byte buffer from here to start reading strings.
  Uint30? lengthInBytes;

  /// The length of each string in bytes inside [strings].
  ///
  /// This allows us to read strings lazily as they are requested.
  List<Uint30>? lengths;
}

class Uint30 {}

class Uint32 {}
