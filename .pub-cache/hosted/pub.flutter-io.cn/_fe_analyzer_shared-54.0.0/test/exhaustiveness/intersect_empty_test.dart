// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/intersect_empty.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'env.dart';
import 'utils.dart';

void main() {
  //   (A)
  //   / \
  //  B   C
  var env = TestEnvironment();
  var a = env.createClass('A', isSealed: true);
  var b = env.createClass('B', inherits: [a]);
  var c = env.createClass('C', inherits: [a]);

  var x = 'x';
  var y = 'y';
  var z = 'z';
  var w = 'w';

  Space A({StaticType? x, StaticType? y, StaticType? z}) => ty(
      a, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});
  Space B({StaticType? x, StaticType? y, StaticType? z}) => ty(
      b, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});
  Space C({StaticType? x, StaticType? y, StaticType? z}) => ty(
      c, {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});

  test('records', () {
    var r = env.createRecordType({x: a, y: a, z: a, w: a});
    expectIntersectEmpty(ty(r, {x: a, y: a}), ty(r, {x: a, y: a}), isFalse);
    expectIntersectEmpty(ty(r, {x: a, y: a}), ty(r, {x: a}), isFalse);
    expectIntersectEmpty(ty(r, {w: a, x: a}), ty(r, {y: a, z: a}), isFalse);
    expectIntersectEmpty(
        ty(r, {w: a, x: a, y: a}), ty(r, {x: a, y: a, z: a}), isFalse);
  });

  test('types', () {
    // Note: More comprehensive tests under intersect_types_test.dart.
    expectIntersectEmpty(a, a, isFalse);
    expectIntersectEmpty(a, b, isFalse);
    expectIntersectEmpty(a, c, isFalse);
    expectIntersectEmpty(b, c, isTrue);
  });

  test('field types', () {
    var r = env.createRecordType({x: a, y: a});
    expectIntersectEmpty(ty(r, {x: a, y: b}), ty(r, {x: b, y: a}), isFalse);
    expectIntersectEmpty(ty(r, {x: b}), ty(r, {x: c}), isTrue);
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
  expect(spacesHaveEmptyIntersection(leftSpace, rightSpace), expected);
  expect(spacesHaveEmptyIntersection(rightSpace, leftSpace), expected);
}
