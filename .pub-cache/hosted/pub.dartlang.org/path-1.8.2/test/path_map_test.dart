// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('considers equal', () {
    test('two identical paths', () {
      final map = PathMap<int>();
      map[join('foo', 'bar')] = 1;
      map[join('foo', 'bar')] = 2;
      expect(map, hasLength(1));
      expect(map, containsPair(join('foo', 'bar'), 2));
    });

    test('two logically equivalent paths', () {
      final map = PathMap<int>();
      map['foo'] = 1;
      map[absolute('foo')] = 2;
      expect(map, hasLength(1));
      expect(map, containsPair('foo', 2));
      expect(map, containsPair(absolute('foo'), 2));
    });

    test('two nulls', () {
      final map = PathMap<int>();
      map[null] = 1;
      map[null] = 2;
      expect(map, hasLength(1));
      expect(map, containsPair(null, 2));
    });
  });

  group('considers unequal', () {
    test('two distinct paths', () {
      final map = PathMap<int>();
      map['foo'] = 1;
      map['bar'] = 2;
      expect(map, hasLength(2));
      expect(map, containsPair('foo', 1));
      expect(map, containsPair('bar', 2));
    });

    test('a path and null', () {
      final map = PathMap<int>();
      map['foo'] = 1;
      map[null] = 2;
      expect(map, hasLength(2));
      expect(map, containsPair('foo', 1));
      expect(map, containsPair(null, 2));
    });
  });

  test('uses the custom context', () {
    final map = PathMap<int>(context: windows);
    map['FOO'] = 1;
    map['foo'] = 2;
    expect(map, hasLength(1));
    expect(map, containsPair('fOo', 2));
  });

  group('.of()', () {
    test("copies the existing map's keys", () {
      final map = PathMap.of({'foo': 1, 'bar': 2});
      expect(map, hasLength(2));
      expect(map, containsPair('foo', 1));
      expect(map, containsPair('bar', 2));
    });

    test('uses the second value in the case of duplicates', () {
      final map = PathMap.of({'foo': 1, absolute('foo'): 2});
      expect(map, hasLength(1));
      expect(map, containsPair('foo', 2));
      expect(map, containsPair(absolute('foo'), 2));
    });
  });
}
