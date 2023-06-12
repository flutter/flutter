// Copyright 2020 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'package:flutter_test/flutter_test.dart';

import 'package:visibility_detector_example/main.dart';

void main() {
  test('collate works', () {
    expect(collate(<List<int>>[]).toList(), <int>[]);
    expect(collate([<int>[]]).toList(), <int>[]);
    expect(
        collate([
          [1]
        ]).toList(),
        [1]);
    expect(
        collate([
          [1],
          <int>[]
        ]).toList(),
        [1]);
    expect(
        collate([
          <int>[],
          [1]
        ]).toList(),
        [1]);
    expect(
        collate([
          [1, 2]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          [1, 2],
          <int>[]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          <int>[],
          [1, 2]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          [1],
          [2]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          <int>[],
          [1],
          [2]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          [1],
          <int>[],
          [2]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          [1],
          [2],
          <int>[]
        ]).toList(),
        [1, 2]);
    expect(
        collate([
          [1],
          [2],
          [3]
        ]).toList(),
        [1, 2, 3]);
    expect(
        collate([
          [1, 4],
          [2],
          [3]
        ]).toList(),
        [1, 2, 3, 4]);
    expect(
        collate([
          [1],
          [2, 4],
          [3]
        ]).toList(),
        [1, 2, 3, 4]);
    expect(
        collate([
          [1],
          [2],
          [3, 4]
        ]).toList(),
        [1, 2, 3, 4]);

    expect(
      collate([
        [1, 4, 7],
        [2, 5, 8, 9],
        [3, 6]
      ]).toList(),
      [1, 2, 3, 4, 5, 6, 7, 8, 9],
    );
  });
}
