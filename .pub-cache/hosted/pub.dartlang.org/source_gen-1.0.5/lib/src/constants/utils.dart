// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

/// Throws a [FormatException] if [root] does not have a given field [name].
///
/// Super types [ClassElement.supertype] are also checked before throwing.
void assertHasField(ClassElement root, String name) {
  ClassElement? element = root;
  while (element != null) {
    final field = element.getField(name);
    if (field != null) {
      return;
    }
    element = element.supertype?.element;
  }
  final allFields = root.fields.toSet()
    ..addAll(root.allSupertypes.expand((t) => t.element.fields));
  throw FormatException(
    'Class ${root.name} does not have field "$name".',
    'Fields: \n  - ${allFields.map((e) => e.name).join('\n  - ')}',
  );
}

/// Returns whether or not [object] is or represents a `null` value.
bool isNullLike(DartObject? object) => object?.isNull != false;

/// Similar to [DartObject.getField], but traverses super classes.
///
/// Returns `null` if ultimately [field] is never found.
DartObject? getFieldRecursive(DartObject? object, String field) {
  if (isNullLike(object)) {
    return null;
  }
  final result = object!.getField(field);
  if (isNullLike(result)) {
    return getFieldRecursive(object.getField('(super)'), field);
  }
  return result;
}
