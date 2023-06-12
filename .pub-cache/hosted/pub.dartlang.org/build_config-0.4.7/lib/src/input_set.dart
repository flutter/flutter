// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'input_set.g.dart';

/// A filter on files inputs or sources.
///
/// Takes a list of strings in glob format for [include] and [exclude]. Matches
/// the `glob()` function in skylark.
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class InputSet {
  static const anything = InputSet();

  /// The globs to include in the set.
  ///
  /// May be null or empty which means every possible path (like `'**'`).
  final List<String> include;

  /// The globs as a subset of [include] to remove from the set.
  ///
  /// May be null or empty which means every path in [include].
  final List<String> exclude;

  const InputSet({this.include, this.exclude});

  factory InputSet.fromJson(dynamic json) {
    if (json is List) {
      json = {'include': json};
    } else if (json is! Map) {
      throw ArgumentError.value(json, 'sources',
          'Expected a Map or a List but got a ${json.runtimeType}');
    }
    final parsed = _$InputSetFromJson(json as Map);
    if (parsed.include != null &&
        parsed.include.any((s) => s == null || s.isEmpty)) {
      throw ArgumentError.value(
          parsed.include, 'include', 'Include globs must not be empty');
    }
    if (parsed.exclude != null &&
        parsed.exclude.any((s) => s == null || s.isEmpty)) {
      throw ArgumentError.value(
          parsed.exclude, 'exclude', 'Exclude globs must not be empty');
    }
    return parsed;
  }

  @override
  String toString() {
    final result = StringBuffer();
    if (include == null || include.isEmpty) {
      result.write('any path');
    } else {
      result.write('paths matching $include');
    }
    if (exclude != null && exclude.isNotEmpty) {
      result.write(' except $exclude');
    }
    return '$result';
  }
}
