// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'build_step.dart';
import 'builder.dart';

/// A [Builder] that runs multiple delegate builders asynchronously.
///
/// **Note**: All builders are ran without ordering guarantees. Thus, none of
/// the builders can use the outputs of other builders in this group. All
/// builders must also have distinct outputs.
class MultiplexingBuilder implements Builder {
  final Iterable<Builder> _builders;

  MultiplexingBuilder(this._builders);

  @override
  FutureOr<void> build(BuildStep buildStep) {
    return Future.wait(_builders
            .where((builder) => builder.buildExtensions.keys
                .any(buildStep.inputId.path.endsWith))
            .map((builder) => builder.build(buildStep))
            .whereType<Future<void>>())
        .then((_) {});
  }

  /// Merges output extensions from all builders.
  ///
  /// If multiple builders declare the same output it will appear in this List
  /// more than once. This should be considered an error.
  @override
  Map<String, List<String>> get buildExtensions =>
      _mergeMaps(_builders.map((b) => b.buildExtensions));

  @override
  String toString() => '$_builders';
}

Map<String, List<String>> _mergeMaps(Iterable<Map<String, List<String>>> maps) {
  var result = <String, List<String>>{};
  for (var map in maps) {
    for (var key in map.keys) {
      result.putIfAbsent(key, () => []).addAll(map[key]!);
    }
  }
  return result;
}
