// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

void _appendTypeError(
  Map<String, Object?> map,
  String field,
  String expected,
  List<String> errors, {
  Object? element,
}) {
  if (element == null) {
    final Type actual = map[field]!.runtimeType;
    errors.add(
      'For field "$field", expected type: $expected, actual type: $actual.',
    );
  } else {
    final Type actual = element.runtimeType;
    errors.add(
      'For element "$element" of "$field", '
      'expected type: $expected, actual type: $actual',
    );
  }
}

/// Type safe getter of a List<String> field from map.
List<String>? stringListOfJson(
  Map<String, Object?> map,
  String field,
  List<String> errors,
) {
  if (map[field] == null) {
    return <String>[];
  }
  if (map[field]! is! List<Object?>) {
    _appendTypeError(map, field, 'list', errors);
    return null;
  }
  for (final Object? obj in map[field]! as List<Object?>) {
    if (obj is! String) {
      _appendTypeError(map, field, element: obj, 'string', errors);
      return null;
    }
  }
  return (map[field]! as List<Object?>).cast<String>();
}

/// Type safe getter of a String field from map.
String? stringOfJson(
  Map<String, Object?> map,
  String field,
  List<String> errors,
) {
  if (map[field] == null) {
    return '<undef>';
  }
  if (map[field]! is! String) {
    _appendTypeError(map, field, 'string', errors);
    return null;
  }
  return map[field]! as String;
}

/// Type safe getter of an int field from map.
int? intOfJson(
  Map<String, Object?> map,
  String field,
  List<String> errors, {
  int fallback = 0,
}) {
  if (map[field] == null) {
    return fallback;
  }
  if (map[field]! is! int) {
    _appendTypeError(map, field, 'int', errors);
    return null;
  }
  return map[field]! as int;
}

const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('    ');

/// Same as [jsonEncode] but is formatted to be human readable.
String jsonEncodePretty(Object? object) => _jsonEncoder.convert(object);
