// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  // Here, "(_)" means "sealed". A bare name is unsealed.
  //
  //     (A)
  //     / \
  //   (B) (C)
  //   / \   \
  //  D   E   F
  //         / \
  //        G   H
  var a = StaticType('A', isSealed: true);
  var b = StaticType('B', isSealed: true, inherits: [a]);
  var c = StaticType('C', isSealed: true, inherits: [a]);
  var d = StaticType('D', inherits: [b]);
  var e = StaticType('E', inherits: [b]);
  var f = StaticType('F', inherits: [c]);
  var g = StaticType('G', inherits: [f]);
  var h = StaticType('H', inherits: [f]);

  test('exhaustiveness', () {
    // Case matching top type covers all subtypes.
    expectReportErrors(a, [a]);
    expectReportErrors(b, [a]);
    expectReportErrors(d, [a]);

    // Case matching subtype doesn't cover supertype.
    expectReportErrors(a, [b], 'A is not exhaustively matched by B.');
    expectReportErrors(b, [b]);
    expectReportErrors(d, [b]);
    expectReportErrors(e, [b]);

    // Matching subtypes of sealed type is exhaustive.
    expectReportErrors(a, [b, c]);
    expectReportErrors(a, [d, e, f]);
    expectReportErrors(a, [b, f]);
    expectReportErrors(a, [c, d], 'A is not exhaustively matched by C|D.');
    expectReportErrors(f, [g, h], 'F is not exhaustively matched by G|H.');
  });

  test('unreachable case', () {
    // Same type.
    expectReportErrors(b, [b, b], 'Case #2 B is covered by B.');

    // Previous case is supertype.
    expectReportErrors(b, [a, b], 'Case #2 B is covered by A.');

    // Previous subtype cases cover sealed supertype.
    expectReportErrors(a, [b, c, a], 'Case #3 A is covered by B|C.');
    expectReportErrors(a, [d, e, f, a], 'Case #4 A is covered by D|E|F.');
    expectReportErrors(a, [b, f, a], 'Case #3 A is covered by B|F.');
    expectReportErrors(a, [c, d, a]);

    // Previous subtype cases do not cover unsealed supertype.
    expectReportErrors(f, [g, h, f]);
  });

  test('covered record destructuring', () {
    var r = StaticType('R', fields: {'x': a, 'y': a, 'z': a});

    // Wider field is not covered.
    expectReportErrors(r, [
      {'x': b},
      {'x': a}
    ]);

    // Narrower field is covered.
    expectReportErrors(
        r,
        [
          {'x': a},
          {'x': b}
        ],
        'Case #2 (x: B) is covered by (x: A).');
  });

  test('nullable sealed', () {
    //     (A)
    //     / \
    //    B  (C)
    //       / \
    //      D   E
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', isSealed: true, inherits: [a]);
    var d = StaticType('D', inherits: [c]);
    var e = StaticType('E', inherits: [c]);

    // Must cover null.
    expectReportErrors(
        a.nullable, [b, d, e], 'A? is not exhaustively matched by B|D|E.');

    // Can cover null with any nullable subtype.
    expectReportErrors(a.nullable, [b.nullable, c]);
    expectReportErrors(a.nullable, [b, c.nullable]);
    expectReportErrors(a.nullable, [b, d.nullable, e]);
    expectReportErrors(a.nullable, [b, d, e.nullable]);

    // Can cover null with a null space.
    expectReportErrors(a.nullable, [b, c, StaticType.nullType]);
    expectReportErrors(a.nullable, [b, d, e, StaticType.nullType]);

    // Nullable covers the non-null.
    expectReportErrors(
        a.nullable, [a.nullable, a], 'Case #2 A is covered by A?.');
    expectReportErrors(
        b.nullable, [a.nullable, b], 'Case #2 B is covered by A?.');

    // Nullable covers null.
    expectReportErrors(a.nullable, [a.nullable, StaticType.nullType],
        'Case #2 Null is covered by A?.');
    expectReportErrors(b.nullable, [a.nullable, StaticType.nullType],
        'Case #2 Null is covered by A?.');
  });
}

void expectReportErrors(StaticType valueType, List<Object> cases,
    [String errors = '']) {
  expect(reportErrors(valueType, parseSpaces(cases)), errors);
}
