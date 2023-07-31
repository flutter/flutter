// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/intersect.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'env.dart';

void main() {
  test('hierarchy', () {
    //   (A)
    //   /|\
    //  B C(D)
    //     / \
    //    E   F
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var d = env.createClass('D', isSealed: true, inherits: [a]);
    var e = env.createClass('E', inherits: [d]);
    var f = env.createClass('F', inherits: [d]);

    expectIntersect(a, a, a);
    expectIntersect(a, b, b);
    expectIntersect(a, c, c);
    expectIntersect(a, d, d);
    expectIntersect(a, e, e);
    expectIntersect(a, f, f);

    expectIntersect(b, b, b);
    expectIntersect(b, c, StaticType.neverType);
    expectIntersect(b, d, StaticType.neverType);
    expectIntersect(b, e, StaticType.neverType);
    expectIntersect(b, f, StaticType.neverType);

    expectIntersect(c, c, c);
    expectIntersect(c, d, StaticType.neverType);
    expectIntersect(c, e, StaticType.neverType);
    expectIntersect(c, f, StaticType.neverType);

    expectIntersect(d, d, d);
    expectIntersect(d, e, e);
    expectIntersect(d, f, f);

    expectIntersect(e, e, e);
    expectIntersect(e, f, StaticType.neverType);
  });

  test('sealed with multiple paths', () {
    //     (A)
    //     / \
    //   (B)  C
    //   / \ /
    //  D   E
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', isSealed: true, inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var d = env.createClass('D', inherits: [b]);
    var e = env.createClass('E', inherits: [b, c]);

    expectIntersect(a, a, a);
    expectIntersect(a, b, b);
    expectIntersect(a, c, c);
    expectIntersect(a, d, d);
    expectIntersect(a, e, e);
    expectIntersect(b, b, b);
    expectIntersect(b, c, StaticType.neverType);
    expectIntersect(b, d, d);
    expectIntersect(b, e, e);
    expectIntersect(c, c, c);
    expectIntersect(c, d, StaticType.neverType);
    expectIntersect(c, e, e);
    expectIntersect(d, d, d);
    expectIntersect(d, e, StaticType.neverType);
    expectIntersect(e, e, e);
  });

  test('nullable', () {
    // A
    // |
    // B
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B', inherits: [a]);

    expectIntersect(a, a.nullable, a);
    expectIntersect(a, StaticType.nullType, StaticType.neverType);
    expectIntersect(a.nullable, StaticType.nullType, StaticType.nullType);

    expectIntersect(a, b.nullable, b);
    expectIntersect(a.nullable, b, b);
    expectIntersect(a.nullable, b.nullable, b.nullable);
  });
}

void expectIntersect(StaticType left, StaticType right, StaticType expected) {
  // Intersection is symmetric so try both directions.
  expect(intersectTypes(left, right), expected);
  expect(intersectTypes(right, left), expected);
}
