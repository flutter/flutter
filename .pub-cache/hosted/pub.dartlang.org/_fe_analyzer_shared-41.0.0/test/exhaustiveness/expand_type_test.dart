// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/subtract.dart';
import 'package:test/test.dart';

void main() {
  test('sealed', () {
    //   (A)
    //   /|\
    //  B C(D)
    //     / \
    //    E   F
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', isSealed: true, inherits: [a]);
    var e = StaticType('E', inherits: [d]);
    var f = StaticType('F', inherits: [d]);

    expectExpand(a, a, 'A');
    expectExpand(a, b, 'B|C|D');
    expectExpand(a, c, 'B|C|D');
    expectExpand(a, d, 'B|C|D');
    expectExpand(a, e, 'B|C|E|F');
    expectExpand(a, f, 'B|C|E|F');

    expectExpand(d, a, 'D');
    expectExpand(d, b, 'D');
    expectExpand(d, c, 'D');
    expectExpand(d, d, 'D');
    expectExpand(d, e, 'E|F');
    expectExpand(d, f, 'E|F');
  });

  test('unsealed', () {
    //    A
    //   /|\
    //  B C D
    //     / \
    //    E   F
    var a = StaticType('A');
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [a]);
    var e = StaticType('E', inherits: [d]);
    var f = StaticType('F', inherits: [d]);

    expectExpand(a, a, 'A');
    expectExpand(a, b, 'A');
    expectExpand(a, c, 'A');
    expectExpand(a, d, 'A');
    expectExpand(a, e, 'A');
    expectExpand(a, f, 'A');

    expectExpand(d, a, 'D');
    expectExpand(d, b, 'D');
    expectExpand(d, c, 'D');
    expectExpand(d, d, 'D');
    expectExpand(d, e, 'D');
    expectExpand(d, f, 'D');
  });

  test('unsealed in middle', () {
    //    (A)
    //    / \
    //   B   C
    //      / \
    //     D  (E)
    //        / \
    //       F   G
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [c]);
    var e = StaticType('E', isSealed: true, inherits: [c]);
    var f = StaticType('F', inherits: [e]);
    var g = StaticType('G', inherits: [e]);

    expectExpand(a, a, 'A');
    expectExpand(a, b, 'B|C');
    expectExpand(a, c, 'B|C');
    expectExpand(a, d, 'B|C');
    expectExpand(a, e, 'B|C');
    expectExpand(a, f, 'B|C');

    expectExpand(c, a, 'C');
    expectExpand(c, b, 'C');
    expectExpand(c, c, 'C');
    expectExpand(c, d, 'C');
    expectExpand(c, e, 'C');
    expectExpand(c, f, 'C');

    expectExpand(e, a, 'E');
    expectExpand(e, b, 'E');
    expectExpand(e, c, 'E');
    expectExpand(e, e, 'E');
    expectExpand(e, f, 'F|G');
    expectExpand(e, g, 'F|G');
  });

  test('transitive sealed family', () {
    //     (A)
    //     / \
    //   (B) (C)
    //   / | | \
    //  D  E F  G
    //     \ /
    //      H
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', isSealed: true, inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b]);
    var f = StaticType('F', inherits: [c]);
    var g = StaticType('G', inherits: [c]);
    var h = StaticType('H', inherits: [e, f]);

    expectExpand(a, a, 'A');
    expectExpand(a, b, 'B|C');
    expectExpand(a, c, 'B|C');
    expectExpand(a, d, 'D|E|C');
    expectExpand(a, e, 'D|E|C');
    expectExpand(a, f, 'B|F|G');
    expectExpand(a, g, 'B|F|G');
    expectExpand(a, h, 'D|E|F|G');

    expectExpand(b, a, 'B');
    expectExpand(b, b, 'B');
    expectExpand(b, c, 'B');
    expectExpand(b, d, 'D|E');
    expectExpand(b, e, 'D|E');
    expectExpand(b, f, 'B');
    expectExpand(b, h, 'D|E');

    expectExpand(d, a, 'D');
    expectExpand(d, b, 'D');
    expectExpand(d, c, 'D');
    expectExpand(d, d, 'D');
    expectExpand(d, e, 'D');
    expectExpand(d, f, 'D');

    expectExpand(e, a, 'E');
    expectExpand(e, b, 'E');
    expectExpand(e, c, 'E');
    expectExpand(e, d, 'E');
    expectExpand(e, e, 'E');
    expectExpand(e, f, 'E');
    expectExpand(e, h, 'E');

    expectExpand(h, a, 'H');
    expectExpand(h, b, 'H');
    expectExpand(h, d, 'H');
    expectExpand(h, e, 'H');
    expectExpand(h, h, 'H');
  });

  test('sealed with multiple paths', () {
    //     (A)
    //     / \
    //   (B)  C
    //   / \ /
    //  D   E
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b, c]);

    expectExpand(a, a, 'A');
    expectExpand(a, b, 'B|C');
    expectExpand(a, c, 'B|C');
    expectExpand(a, d, 'D|E|C');
    expectExpand(a, e, 'D|E|C');

    expectExpand(b, a, 'B');
    expectExpand(b, b, 'B');
    expectExpand(b, c, 'B');
    expectExpand(b, d, 'D|E');
    expectExpand(b, e, 'D|E');

    expectExpand(c, a, 'C');
    expectExpand(c, b, 'C');
    expectExpand(c, c, 'C');
    expectExpand(c, d, 'C');
    expectExpand(c, e, 'C');

    expectExpand(d, a, 'D');
    expectExpand(d, b, 'D');
    expectExpand(d, c, 'D');
    expectExpand(d, d, 'D');
    expectExpand(d, e, 'D');

    expectExpand(e, a, 'E');
    expectExpand(e, b, 'E');
    expectExpand(e, c, 'E');
    expectExpand(e, d, 'E');
    expectExpand(e, e, 'E');
  });

  test('nullable', () {
    //   (A)
    //   / \
    //  B   C
    //     / \
    //    D   E
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [c]);

    expectExpand(a.nullable, a, 'A|Null');
    expectExpand(a, a.nullable, 'A');
    expectExpand(a.nullable, a.nullable, 'A|Null');

    // Sealed subtype.
    expectExpand(a.nullable, b, 'B|C|Null');
    expectExpand(a, b.nullable, 'B|C');
    expectExpand(a.nullable, b.nullable, 'B|C|Null');

    // Unsealed subtype.
    expectExpand(c.nullable, d, 'C|Null');
    expectExpand(c, d.nullable, 'C');
    expectExpand(c.nullable, d.nullable, 'C|Null');
  });
}

void expectExpand(StaticType left, StaticType right, String expected) {
  expect(expandType(left, right).join('|'), expected);
}
