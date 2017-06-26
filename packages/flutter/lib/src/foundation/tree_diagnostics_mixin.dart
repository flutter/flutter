// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'print.dart';

/// Returns a 5 character long hexadecimal string generated from
/// Object.hashCode's 20 least-significant bits.
String shortHash(Object object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}

/// Returns a summary of the runtime type and hash code of `object`.
String describeIdentity(Object object) =>
    '${object.runtimeType}#${shortHash(object)}';

/// Returns a short description of an enum value.
///
/// Strips off the enum class name from the `enumEntry.toString()`.
///
/// ## Sample code
///
/// This example shows the result of calling `enumEntry.toString() and the
/// result of calling describeEnum.
///
/// ```dart
/// enum Day {
///   monday, tuesday, wednesday, thursday, friday, saturday, sunday
/// }
///
/// main() {
///   assert(Day.monday.toString() == 'Day.monday');
///   assert(describeEnum(Day.monday) == 'monday');
/// }
/// ```
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

/// A mixin that helps dump string representations of trees.
abstract class TreeDiagnosticsMixin {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory TreeDiagnosticsMixin._() => null;

  /// A brief description of this object, usually just the [runtimeType] and the
  /// [hashCode].
  ///
  /// See also:
  ///
  ///  * [toStringShallow], for a detailed description of the object.
  ///  * [toStringDeep], for a description of the subtree rooted at this object.
  @override
  String toString() => describeIdentity(this);

  /// Returns a one-line detailed description of the object.
  ///
  /// This description includes everything from [debugFillDescription], but does
  /// not recurse to any children.
  ///
  /// The [toStringShallow] method can take an argument, which is the string to
  /// place between each part obtained from [debugFillDescription]. Passing a
  /// string such as `'\n '` will result in a multiline string that indents the
  /// properties of the object below its name (as per [toString]).
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object.
  ///  * [toStringDeep], for a description of the subtree rooted at this object.
  String toStringShallow([String joiner = '; ']) {
    final StringBuffer result = new StringBuffer();
    result.write(toString());
    result.write(joiner);
    final List<String> description = <String>[];
    debugFillDescription(description);
    result.write(description.join(joiner));
    return result.toString();
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// This includes the information from [debugFillDescription], and then
  /// recurses into the children using [debugDescribeChildren].
  ///
  /// The [toStringDeep] method takes arguments, but those are intended for
  /// internal use when recursing to the descendants, and so can be ignored.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object but not its children.
  ///  * [toStringShallow], for a detailed description of the object but not its
  ///    children.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    String result = '$prefixLineOne$this\n';
    final String childrenDescription = debugDescribeChildren(prefixOtherLines);
    final String descriptionPrefix = childrenDescription != '' ? '$prefixOtherLines \u2502 ' : '$prefixOtherLines   ';
    final List<String> description = <String>[];
    debugFillDescription(description);
    result += description
      .expand((String description) => debugWordWrap(description, 65, wrapIndent: '  '))
      .map<String>((String line) => "$descriptionPrefix$line\n")
      .join();
    if (childrenDescription == '') {
      final String prefix = prefixOtherLines.trimRight();
      if (prefix != '')
        result += '$prefix\n';
    } else {
      result += childrenDescription;
    }
    return result;
  }

  /// Add additional information to the given description for use by
  /// [toStringDeep] and [toStringShallow].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) { }

  /// Returns a description of this node's children for use by [toStringDeep].
  @protected
  String debugDescribeChildren(String prefix) => '';
}
