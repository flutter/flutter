// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'annotated_code_helper.dart';

enum IdKind {
  /// Id used for top level or class members. This is used in [MemberId].
  member,

  /// Id used for classes. This is used in [ClassId].
  cls,

  /// Id used for libraries. This is used in [LibraryId].
  library,

  /// Id used for a code point at certain offset. The id represents the default
  /// use of the code point, often a read access. This is used in [NodeId].
  node,

  /// Id used for an invocation at certain offset. This is used in [NodeId].
  invoke,

  /// Id used for an assignment at certain offset. This is used in [NodeId].
  update,

  /// Id used for the iterator expression of a for-in at certain offset. This is
  /// used in [NodeId].
  iterator,

  /// Id used for the implicit call to `Iterator.current` in a for-in at certain
  /// offset. This is used in [NodeId].
  current,

  /// Id used for the implicit call to `Iterator.moveNext` in a for-in at
  /// certain offset. This is used in [NodeId].
  moveNext,

  /// Id used for the implicit as expression inserted by the compiler.
  implicitAs,

  /// Id used for the statement at certain offset. This is used in [NodeId].
  stmt,

  /// Id used for the error reported at certain offset. This is used in
  /// [NodeId].
  error,
}

/// Id for a code point or element.
abstract class Id {
  IdKind get kind;

  /// Indicates whether the id refers to an element defined outside of the test
  /// case itself (e.g. some tests may need to refer to properties of elements
  /// in `dart:core`).
  bool get isGlobal;

  /// Display name for this id.
  String get descriptor;
}

class IdValue {
  final Id id;
  final Annotation annotation;
  final String value;

  const IdValue(this.id, this.annotation, this.value);

  @override
  int get hashCode => id.hashCode * 13 + value.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! IdValue) return false;
    return id == other.id && value == other.value;
  }

  @override
  String toString() => idToString(id, value);

  static String idToString(Id id, String value) {
    switch (id.kind) {
      case IdKind.member:
        MemberId elementId = id as MemberId;
        return '$memberPrefix${elementId.name}:$value';
      case IdKind.cls:
        ClassId classId = id as ClassId;
        return '$classPrefix${classId.name}:$value';
      case IdKind.library:
        return '$libraryPrefix$value';
      case IdKind.node:
        return value;
      case IdKind.invoke:
        return '$invokePrefix$value';
      case IdKind.update:
        return '$updatePrefix$value';
      case IdKind.iterator:
        return '$iteratorPrefix$value';
      case IdKind.current:
        return '$currentPrefix$value';
      case IdKind.moveNext:
        return '$moveNextPrefix$value';
      case IdKind.implicitAs:
        return '$implicitAsPrefix$value';
      case IdKind.stmt:
        return '$stmtPrefix$value';
      case IdKind.error:
        return '$errorPrefix$value';
    }
  }

  static const String globalPrefix = "global#";
  static const String memberPrefix = "member: ";
  static const String classPrefix = "class: ";
  static const String libraryPrefix = "library: ";
  static const String invokePrefix = "invoke: ";
  static const String updatePrefix = "update: ";
  static const String iteratorPrefix = "iterator: ";
  static const String currentPrefix = "current: ";
  static const String moveNextPrefix = "moveNext: ";
  static const String implicitAsPrefix = "as: ";
  static const String stmtPrefix = "stmt: ";
  static const String errorPrefix = "error: ";

  static IdValue decode(Uri sourceUri, Annotation annotation, String text,
      {bool preserveWhitespaceInAnnotations = false,
      bool preserveInfixWhitespace = false}) {
    int offset = annotation.offset;
    Id id;
    String expected;
    if (text.startsWith(memberPrefix)) {
      text = text.substring(memberPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid member id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new MemberId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(classPrefix)) {
      text = text.substring(classPrefix.length);
      int colonPos = text.indexOf(':');
      if (colonPos == -1) throw "Invalid class id: '$text'";
      String name = text.substring(0, colonPos);
      bool isGlobal = name.startsWith(globalPrefix);
      if (isGlobal) {
        name = name.substring(globalPrefix.length);
      }
      id = new ClassId(name, isGlobal: isGlobal);
      expected = text.substring(colonPos + 1);
    } else if (text.startsWith(libraryPrefix)) {
      id = new LibraryId(sourceUri);
      expected = text.substring(libraryPrefix.length);
    } else if (text.startsWith(invokePrefix)) {
      id = new NodeId(offset, IdKind.invoke);
      expected = text.substring(invokePrefix.length);
    } else if (text.startsWith(updatePrefix)) {
      id = new NodeId(offset, IdKind.update);
      expected = text.substring(updatePrefix.length);
    } else if (text.startsWith(iteratorPrefix)) {
      id = new NodeId(offset, IdKind.iterator);
      expected = text.substring(iteratorPrefix.length);
    } else if (text.startsWith(currentPrefix)) {
      id = new NodeId(offset, IdKind.current);
      expected = text.substring(currentPrefix.length);
    } else if (text.startsWith(moveNextPrefix)) {
      id = new NodeId(offset, IdKind.moveNext);
      expected = text.substring(moveNextPrefix.length);
    } else if (text.startsWith(implicitAsPrefix)) {
      id = new NodeId(offset, IdKind.implicitAs);
      expected = text.substring(implicitAsPrefix.length);
    } else if (text.startsWith(stmtPrefix)) {
      id = new NodeId(offset, IdKind.stmt);
      expected = text.substring(stmtPrefix.length);
    } else if (text.startsWith(errorPrefix)) {
      id = new NodeId(offset, IdKind.error);
      expected = text.substring(errorPrefix.length);
    } else {
      id = new NodeId(offset, IdKind.node);
      expected = text;
    }
    if (preserveWhitespaceInAnnotations) {
      // Keep all whitespace.
    } else if (preserveInfixWhitespace) {
      // Remove heading and trailing whitespace.
      expected = expected.trim();
    } else {
      // Remove unneeded whitespace.
      expected = expected.replaceAll(new RegExp(r'\s*(\n\s*)+\s*'), '');
    }
    return new IdValue(id, annotation, expected);
  }
}

/// Id for an member element.
class MemberId implements Id {
  final String? className;
  final String memberName;
  @override
  final bool isGlobal;

  factory MemberId(String text, {bool isGlobal = false}) {
    int dotPos = text.indexOf('.');
    if (dotPos != -1) {
      return new MemberId.internal(text.substring(dotPos + 1),
          className: text.substring(0, dotPos), isGlobal: isGlobal);
    } else {
      return new MemberId.internal(text, isGlobal: isGlobal);
    }
  }

  MemberId.internal(this.memberName, {this.className, this.isGlobal = false});

  @override
  int get hashCode => className.hashCode * 13 + memberName.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MemberId) return false;
    return className == other.className && memberName == other.memberName;
  }

  @override
  IdKind get kind => IdKind.member;

  String get name => className != null ? '$className.$memberName' : memberName;

  @override
  String get descriptor => 'member $name';

  @override
  String toString() => 'member:$name';
}

/// Id for a class.
class ClassId implements Id {
  final String className;
  @override
  final bool isGlobal;

  ClassId(this.className, {this.isGlobal = false});

  @override
  int get hashCode => className.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ClassId) return false;
    return className == other.className;
  }

  @override
  IdKind get kind => IdKind.cls;

  String get name => className;

  @override
  String get descriptor => 'class $name';

  @override
  String toString() => 'class:$name';
}

/// Id for a library.
class LibraryId implements Id {
  final Uri uri;

  LibraryId(this.uri);

  // TODO(johnniwinther): Support global library annotations.
  @override
  bool get isGlobal => false;

  @override
  int get hashCode => uri.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! LibraryId) return false;
    return uri == other.uri;
  }

  @override
  IdKind get kind => IdKind.library;

  String get name => uri.toString();

  @override
  String get descriptor => 'library $name';

  @override
  String toString() => 'library:$name';
}

/// Id for a code point defined by a kind and a code offset.
class NodeId implements Id {
  final int value;
  @override
  final IdKind kind;

  const NodeId(this.value, this.kind)
      :
        // ignore: unnecessary_null_comparison
        assert(value != null),
        assert(value >= 0);

  @override
  bool get isGlobal => false;

  @override
  int get hashCode => value.hashCode * 13 + kind.hashCode * 17;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! NodeId) return false;
    return value == other.value && kind == other.kind;
  }

  @override
  String get descriptor => 'offset $value ($kind)';

  @override
  String toString() => '$kind:$value';
}

class ActualData<T> {
  final Id id;
  final T value;
  final Uri uri;
  final int _offset;
  final Object object;

  ActualData(this.id, this.value, this.uri, this._offset, this.object);

  int get offset {
    if (id is NodeId) {
      NodeId nodeId = id as NodeId;
      return nodeId.value;
    } else {
      return _offset;
    }
  }

  String get objectText {
    return 'object `${'$object'.replaceAll('\n', '')}` (${object.runtimeType})';
  }

  @override
  String toString() => 'ActualData(id=$id,value=$value,uri=$uri,'
      'offset=$offset,object=$objectText)';
}

mixin DataRegistry<T> {
  Map<Id, ActualData<T>> get actualMap;

  /// Registers [value] with [id] in [actualMap].
  ///
  /// Checks for duplicate data for [id].
  void registerValue(Uri uri, int offset, Id id, T? value, Object object) {
    if (value != null) {
      ActualData<T> newData = new ActualData<T>(id, value, uri, offset, object);
      if (actualMap.containsKey(id)) {
        ActualData<T> existingData = actualMap[id]!;
        ActualData<T>? mergedData = mergeData(existingData, newData);
        if (mergedData != null) {
          actualMap[id] = mergedData;
        } else {
          report(
              uri,
              offset,
              "Duplicate id ${id}, value=$value, object=$object "
              "(${object.runtimeType})");
          report(
              uri,
              offset,
              "Duplicate id ${id}, value=${existingData.value}, "
              "object=${existingData.object} "
              "(${existingData.object.runtimeType})");
          fail("Duplicate id $id.");
        }
      } else {
        actualMap[id] = newData;
      }
    }
  }

  ActualData<T>? mergeData(ActualData<T> value1, ActualData<T> value2) => null;

  /// Called to report duplicate errors.
  void report(Uri uri, int offset, String message);

  /// Called to raise an exception on duplicate errors.
  void fail(String message);
}
