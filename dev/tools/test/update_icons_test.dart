// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../update_icons.dart';

Map<String, String> codepointsA = <String, String>{
  'airplane': '111',
  'boat': '222',
};
Map<String, String> codepointsB = <String, String>{
  'airplane': '333',
};
Map<String, String> codepointsC = <String, String>{
  'airplane': '111',
  'train': '444',
};
Map<String, String> codepointsUnderscore = <String, String>{
  'airplane__123': '111',
};

void main() {
  group('safety checks', () {
    test('superset', () {
      expect(testIsSuperset(codepointsA, codepointsA), true);

      expect(testIsSuperset(codepointsA, codepointsB), true);
      expect(testIsSuperset(codepointsB, codepointsA), false);
    });
    test('stability', () {
      expect(testIsStable(codepointsA, codepointsA), true);

      expect(testIsStable(codepointsA, codepointsB), false);
      expect(testIsStable(codepointsB, codepointsA), false);

      expect(testIsStable(codepointsA, codepointsC), true);
      expect(testIsStable(codepointsC, codepointsA), true);
    });
  });

  test('no double underscores', () {
    expect(Icon(codepointsUnderscore.entries.first), 'abc_123');
  });

  test('usage string is correct', () {
    expect(
      Icon(const MapEntry<String, String>('abc', '')).usage,
      'Icon(Icons.abc),',
    );
  });

  test('usage string is correct with replacement', () {
    expect(
      Icon(const MapEntry<String, String>('123', '')).usage,
      'Icon(Icons.onetwothree),',
    );
    expect(
      Icon(const MapEntry<String, String>('123_rounded', '')).usage,
      'Icon(Icons.onetwothree_rounded),',
    );
  });
}
