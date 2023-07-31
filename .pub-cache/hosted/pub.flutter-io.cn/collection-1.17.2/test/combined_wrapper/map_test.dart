// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../unmodifiable_collection_test.dart' as common;

void main() {
  var map1 = const {1: 1, 2: 2, 3: 3};
  var map2 = const {4: 4, 5: 5, 6: 6};
  var map3 = const {7: 7, 8: 8, 9: 9};
  var map4 = const {1: -1, 2: -2, 3: -3};
  var concat = SplayTreeMap<int, int>()
    // The duplicates map appears first here but last in the CombinedMapView
    // which has the opposite semantics of `concat`. Keys/values should be
    // returned from the first map that contains them.
    ..addAll(map4)
    ..addAll(map1)
    ..addAll(map2)
    ..addAll(map3);

  // In every way possible this should test the same as an UnmodifiableMapView.
  common.testReadMap(
      concat, CombinedMapView([map1, map2, map3, map4]), 'CombinedMapView');

  common.testReadMap(
      concat,
      CombinedMapView([map1, {}, map2, {}, map3, {}, map4, {}]),
      'CombinedMapView (some empty)');

  test('should function as an empty map when no maps are passed', () {
    var empty = CombinedMapView([]);
    expect(empty, isEmpty);
    expect(empty.length, 0);
  });

  test('should function as an empty map when only empty maps are passed', () {
    var empty = CombinedMapView([{}, {}, {}]);
    expect(empty, isEmpty);
    expect(empty.length, 0);
  });

  test('should reflect underlying changes back to the combined map', () {
    var backing1 = <int, int>{};
    var backing2 = <int, int>{};
    var combined = CombinedMapView([backing1, backing2]);
    expect(combined, isEmpty);
    backing1.addAll(map1);
    expect(combined, map1);
    backing2.addAll(map2);
    expect(combined, Map.from(backing1)..addAll(backing2));
  });

  test('should reflect underlying changes with a single map', () {
    var backing1 = <int, int>{};
    var combined = CombinedMapView([backing1]);
    expect(combined, isEmpty);
    backing1.addAll(map1);
    expect(combined, map1);
  });

  test('re-iterating keys produces same result', () {
    var combined = CombinedMapView([map1, map2, map3, map4]);
    var keys = combined.keys;
    expect(keys.toList(), keys.toList());
  });
}
