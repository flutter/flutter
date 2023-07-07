// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:yaml/yaml.dart';

/// Test if the given [value] is `false` or the string "false"
/// (case-insensitive).
bool isFalse(Object value) =>
    value is bool ? !value : toLowerCase(value) == 'false';

/// Test if the given [value] is `true` or the string "true" (case-insensitive).
bool isTrue(Object value) =>
    value is bool ? value : toLowerCase(value) == 'true';

/// Safely convert the given [value] to a bool value, or return `null` if the
/// value could not be converted.
bool? toBool(Object value) {
  if (value is YamlScalar) {
    value = value.value;
  }
  if (value is bool) {
    return value;
  }
  var string = toLowerCase(value);
  if (string == 'true') {
    return true;
  }
  if (string == 'false') {
    return false;
  }
  return null;
}

/// Safely convert this [value] to lower case, returning `null` if [value] is
/// null.
String? toLowerCase(Object? value) => value?.toString().toLowerCase();

/// Safely convert this [value] to upper case, returning `null` if [value] is
/// null.
String? toUpperCase(Object? value) => value?.toString().toUpperCase();

/// A simple limited queue.
class LimitedQueue<E> extends ListQueue<E> {
  final int limit;

  /// Create a queue with [limit] items.
  LimitedQueue(this.limit);

  @override
  void add(E value) {
    super.add(value);
    while (length > limit) {
      remove(first);
    }
  }
}
