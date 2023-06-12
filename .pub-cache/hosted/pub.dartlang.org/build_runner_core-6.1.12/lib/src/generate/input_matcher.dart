// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';

/// A filter on files to run through a Builder.
class InputMatcher {
  /// The files to include
  ///
  /// Null or empty means include everything.
  final List<Glob> includeGlobs;

  /// The files within [includeGlobs] to exclude.
  ///
  /// Null or empty means exclude nothing.
  final List<Glob> excludeGlobs;

  InputMatcher(InputSet inputSet, {List<String> defaultInclude})
      : includeGlobs =
            (inputSet.include ?? defaultInclude)?.map((p) => Glob(p))?.toList(),
        excludeGlobs = inputSet.exclude?.map((p) => Glob(p))?.toList();

  /// Whether [input] is included in this set of assets.
  bool matches(AssetId input) => includes(input) && !excludes(input);

  /// Whether [input] matches any [includeGlobs].
  ///
  /// If there are no [includeGlobs] this always returns `true`.
  bool includes(AssetId input) =>
      includeGlobs == null ||
      includeGlobs.isEmpty ||
      includeGlobs.any((g) => g.matches(input.path));

  /// Whether [input] matches any [excludeGlobs].
  ///
  /// If there are no [excludeGlobs] this always returns `false`.
  bool excludes(AssetId input) =>
      excludeGlobs != null &&
      excludeGlobs.isNotEmpty &&
      excludeGlobs.any((g) => g.matches(input.path));

  @override
  String toString() {
    final result = StringBuffer();
    if (includeGlobs == null || includeGlobs.isEmpty) {
      result.write('any assets');
    } else {
      result.write('assets matching ${_patterns(includeGlobs).toList()}');
    }
    if (excludeGlobs != null && excludeGlobs.isNotEmpty) {
      result.write(' except ${_patterns(excludeGlobs).toList()}');
    }
    return '$result';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InputMatcher &&
          _deepEquals.equals(
              _patterns(includeGlobs), _patterns(other.includeGlobs)) &&
          _deepEquals.equals(
              _patterns(excludeGlobs), _patterns(other.excludeGlobs)));

  @override
  int get hashCode =>
      _deepEquals.hash([_patterns(includeGlobs), _patterns(excludeGlobs)]);
}

final _deepEquals = const DeepCollectionEquality();

Iterable<String> _patterns(Iterable<Glob> globs) =>
    globs?.map((g) => g.pattern);
