// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/intersect_empty.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  //   (A)
  //   / \
  //  B   C
  var a = StaticType('A', isSealed: true);
  var b = StaticType('B', inherits: [a]);
  var c = StaticType('C', inherits: [a]);

  Space A({StaticType? x, StaticType? y, StaticType? z}) => ty(
      a, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});
  Space B({StaticType? x, StaticType? y, StaticType? z}) => ty(
      b, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});
  Space C({StaticType? x, StaticType? y, StaticType? z}) => ty(
      c, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});

  test('records', () {
    expectIntersectEmpty(rec(x: a, y: a), rec(x: a, y: a), isFalse);
    expectIntersectEmpty(rec(x: a, y: a), rec(x: a), isFalse);
    expectIntersectEmpty(rec(w: a, x: a), rec(y: a, z: a), isFalse);
    expectIntersectEmpty(rec(w: a, x: a, y: a), rec(x: a, y: a, z: a), isFalse);
  });

  test('types', () {
    // Note: More comprehensive tests under intersect_types_test.dart.
    expectIntersectEmpty(a, a, isFalse);
    expectIntersectEmpty(a, b, isFalse);
    expectIntersectEmpty(a, c, isFalse);
    expectIntersectEmpty(b, c, isTrue);
  });

  test('field types', () {
    expectIntersectEmpty(rec(x: a, y: b), rec(x: b, y: a), isFalse);
    expectIntersectEmpty(rec(x: b), rec(x: c), isTrue);
  });

  test('types and fields', () {
    expectIntersectEmpty(A(x: a), A(x: a), isFalse);
    expectIntersectEmpty(A(x: a), A(x: b), isFalse);
    expectIntersectEmpty(A(x: b), A(x: c), isTrue);

    expectIntersectEmpty(A(x: a), B(x: a), isFalse);
    expectIntersectEmpty(A(x: a), B(x: b), isFalse);
    expectIntersectEmpty(A(x: b), B(x: c), isTrue);

    expectIntersectEmpty(B(x: a), A(x: a), isFalse);
    expectIntersectEmpty(B(x: a), A(x: b), isFalse);
    expectIntersectEmpty(B(x: b), A(x: c), isTrue);

    expectIntersectEmpty(B(x: a), B(x: a), isFalse);
    expectIntersectEmpty(B(x: a), B(x: b), isFalse);
    expectIntersectEmpty(B(x: b), B(x: c), isTrue);

    expectIntersectEmpty(B(x: a), C(x: a), isTrue);
    expectIntersectEmpty(B(x: a), C(x: b), isTrue);
    expectIntersectEmpty(B(x: b), C(x: c), isTrue);
  });
}

void expectIntersectEmpty(Object left, Object right, Matcher expected) {
  var leftSpace = parseSpace(left);
  var rightSpace = parseSpace(right);

  // Intersection is symmetric so try both directions.
  expect(intersectEmpty(leftSpace, rightSpace), expected);
  expect(intersectEmpty(rightSpace, leftSpace), expected);
}
