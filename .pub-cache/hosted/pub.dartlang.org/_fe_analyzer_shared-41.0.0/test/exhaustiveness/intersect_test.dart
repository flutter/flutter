// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/intersect.dart';
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
    expectIntersect(rec(x: a, y: a), rec(x: a, y: a), rec(x: a, y: a));
    expectIntersect(rec(x: a, y: a), rec(x: a), rec(x: a, y: a));
    expectIntersect(
        rec(w: a, x: a), rec(y: a, z: a), rec(w: a, x: a, y: a, z: a));
    expectIntersect(rec(w: a, x: a, y: a), rec(x: a, y: a, z: a),
        rec(w: a, x: a, y: a, z: a));
  });

  test('types', () {
    // Note: More comprehensive tests under intersect_types_test.dart.
    expectIntersect(a, a, a);
    expectIntersect(a, b, b);
    expectIntersect(a, c, c);
    expectIntersect(b, c, '∅');
  });

  test('field types', () {
    expectIntersect(rec(x: a, y: b), rec(x: b, y: a), rec(x: b, y: b));
    expectIntersect(rec(x: b), rec(x: c), '∅');
  });

  test('types and fields', () {
    expectIntersect(A(x: a), A(x: a), A(x: a));
    expectIntersect(A(x: a), A(x: b), A(x: b));
    expectIntersect(A(x: b), A(x: c), '∅');

    expectIntersect(A(x: a), B(x: a), B(x: a));
    expectIntersect(A(x: a), B(x: b), B(x: b));
    expectIntersect(A(x: b), B(x: c), '∅');

    expectIntersect(B(x: a), A(x: a), B(x: a));
    expectIntersect(B(x: a), A(x: b), B(x: b));
    expectIntersect(B(x: b), A(x: c), '∅');

    expectIntersect(B(x: a), B(x: a), B(x: a));
    expectIntersect(B(x: a), B(x: b), B(x: b));
    expectIntersect(B(x: b), B(x: c), '∅');

    expectIntersect(B(x: a), C(x: a), '∅');
    expectIntersect(B(x: a), C(x: b), '∅');
    expectIntersect(B(x: b), C(x: c), '∅');
  });
}

void expectIntersect(Object left, Object right, Object expected) {
  var leftSpace = parseSpace(left);
  var rightSpace = parseSpace(right);
  var expectedText = parseSpace(expected).toString();

  // Intersection is symmetric so try both directions.
  expect(intersect(leftSpace, rightSpace).toString(), expectedText);
  expect(intersect(rightSpace, leftSpace).toString(), expectedText);
}
