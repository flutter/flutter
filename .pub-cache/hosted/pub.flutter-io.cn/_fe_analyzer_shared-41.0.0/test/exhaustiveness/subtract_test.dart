// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/subtract.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('empty', () {
    var a = StaticType('A');
    var b = StaticType('B', inherits: [a], fields: {'x': a, 'y': a});
    var c = StaticType('C', inherits: [a]);

    expectSubtract('∅', '∅', '∅');

    // Subtracting from empty stays empty.
    expectSubtract('∅', a, '∅');
    expectSubtract('∅', [b, c], '∅');
    expectSubtract('∅', {'x': a}, '∅');
    expectSubtract('∅', ty(b, {'x': a}), '∅');

    // Subtracting empty leaves unchanged.
    expectSubtract(a, '∅', 'A');
    expectSubtract([b, c], '∅', 'B|C');
    expectSubtract({'x': a}, '∅', '(x: A)');
    expectSubtract(ty(b, {'x': a}), '∅', 'B(x: A)');
  });

  group('union with sealed types', () {
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

    expectSubtract(a, b, 'C|D');
    expectSubtract(a, c, 'B|D');
    expectSubtract(a, d, 'B|C');
    expectSubtract(a, e, 'B|C|F');
    expectSubtract(a, f, 'B|C|E');
    expectSubtract(a, [b, c], 'D');
    expectSubtract(a, [b, d], 'C');
    expectSubtract(a, [b, e], 'C|F');

    expectSubtract([b, c], b, 'C');
    expectSubtract([b, c], c, 'B');
    expectSubtract([b, c, d], b, 'C|D');
    expectSubtract([b, c, d], c, 'B|D');
    expectSubtract([b, c, d], d, 'B|C');

    expectSubtract([b, c], [b, c], '∅');
    expectSubtract([b, c], [b, d], 'C');
    expectSubtract([b, d], [b, c], 'D');
    expectSubtract([b, c, d], [b, c], 'D');

    expectSubtract([b, d], e, 'B|F');
    expectSubtract([b, e], d, 'B');
  });

  group('unsealed subtype', () {
    //   A   B
    //  / \ /
    // C   D
    //  \ /
    //   E
    var a = StaticType('A');
    var b = StaticType('B');
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [a, b]);
    var e = StaticType('E', inherits: [c, d]);

    expectSubtract(a, a, '∅');
    expectSubtract(a, b, 'A');
    expectSubtract(a, c, 'A');
    expectSubtract(a, d, 'A');
    expectSubtract(a, e, 'A');

    expectSubtract(b, a, 'B');
    expectSubtract(b, b, '∅');
    expectSubtract(b, c, 'B');
    expectSubtract(b, d, 'B');
    expectSubtract(b, e, 'B');

    expectSubtract(c, a, '∅');
    expectSubtract(c, b, 'C');
    expectSubtract(c, c, '∅');
    expectSubtract(c, d, 'C');
    expectSubtract(c, e, 'C');

    expectSubtract(d, a, '∅');
    expectSubtract(d, b, '∅');
    expectSubtract(d, c, 'D');
    expectSubtract(d, d, '∅');
    expectSubtract(d, e, 'D');

    expectSubtract(e, a, '∅');
    expectSubtract(e, b, '∅');
    expectSubtract(e, c, '∅');
    expectSubtract(e, d, '∅');
    expectSubtract(e, e, '∅');
  });

  group('unsealed subtype and field', () {
    //  X  A
    //  |  |
    //  Y  B
    var x = StaticType('X');
    var y = StaticType('Y', inherits: [x]);
    var a = StaticType('A', fields: {'x': StaticType.top});
    var b = StaticType('B', inherits: [a]);

    Space A({required StaticType x}) => ty(a, {'x': x});
    Space B({required StaticType x}) => ty(b, {'x': x});

    expectSubtract(A(x: x), A(x: x), '∅');
    expectSubtract(A(x: x), B(x: x), 'A(x: X)');
    expectSubtract(B(x: x), A(x: x), '∅');
    expectSubtract(B(x: x), B(x: x), '∅');

    expectSubtract(A(x: x), A(x: y), 'A(x: X)');
    expectSubtract(A(x: x), B(x: y), 'A(x: X)');
    expectSubtract(B(x: x), A(x: y), 'B(x: X)');
    expectSubtract(B(x: x), B(x: y), 'B(x: X)');

    expectSubtract(A(x: y), A(x: x), '∅');
    expectSubtract(A(x: y), B(x: x), 'A(x: Y)');
    expectSubtract(B(x: y), A(x: x), '∅');
    expectSubtract(B(x: y), B(x: x), '∅');

    expectSubtract(A(x: y), A(x: y), '∅');
    expectSubtract(A(x: y), B(x: y), 'A(x: Y)');
    expectSubtract(B(x: y), A(x: y), '∅');
    expectSubtract(B(x: y), B(x: y), '∅');

    expectSubtract(A(x: x), a, '∅');
    expectSubtract(A(x: x), b, 'A(x: X)');
    expectSubtract(B(x: x), a, '∅');
    expectSubtract(B(x: x), b, '∅');
    expectSubtract(a, A(x: x), 'A');
    expectSubtract(b, A(x: x), 'B');
    expectSubtract(a, B(x: x), 'A');
    expectSubtract(b, B(x: x), 'B');
  });

  group('sealed subtype and field', () {
    //   (X)    (A)
    //   /|\    /|\
    //  W Y Z  B C D
    var x = StaticType('X', isSealed: true);
    StaticType('W', inherits: [x]);
    var y = StaticType('Y', inherits: [x]);
    StaticType('Z', inherits: [x]);
    var a = StaticType('A', isSealed: true, fields: {'x': StaticType.top});
    var b = StaticType('B', inherits: [a]);
    StaticType('C', inherits: [a]);
    StaticType('D', inherits: [a]);

    Space A({required StaticType x}) => ty(a, {'x': x});
    Space B({required StaticType x}) => ty(b, {'x': x});

    expectSubtract(A(x: x), A(x: x), '∅');
    expectSubtract(A(x: x), B(x: x), 'C(x: X)|D(x: X)');
    expectSubtract(B(x: x), A(x: x), '∅');
    expectSubtract(B(x: x), B(x: x), '∅');

    expectSubtract(A(x: x), A(x: y), 'A(x: W|Z)');
    expectSubtract(A(x: x), B(x: y), 'B(x: W|Z)|C(x: X)|D(x: X)');
    expectSubtract(B(x: x), A(x: y), 'B(x: W|Z)');
    expectSubtract(B(x: x), B(x: y), 'B(x: W|Z)');

    expectSubtract(A(x: y), A(x: x), '∅');
    expectSubtract(A(x: y), B(x: x), 'C(x: Y)|D(x: Y)');
    expectSubtract(B(x: y), A(x: x), '∅');
    expectSubtract(B(x: y), B(x: x), '∅');

    expectSubtract(A(x: y), A(x: y), '∅');
    expectSubtract(A(x: y), B(x: y), 'C(x: Y)|D(x: Y)');
    expectSubtract(B(x: y), A(x: y), '∅');
    expectSubtract(B(x: y), B(x: y), '∅');

    expectSubtract(A(x: x), a, '∅');
    expectSubtract(A(x: x), b, 'C(x: X)|D(x: X)');
    expectSubtract(B(x: x), a, '∅');
    expectSubtract(B(x: x), b, '∅');

    // Note that these don't specialize x to "W|Z" because it's declared type
    // is top, which isn't sealed.
    expectSubtract(a, A(x: x), 'A');
    expectSubtract(b, A(x: x), 'B');
    expectSubtract(a, B(x: x), 'B|C|D');
    expectSubtract(b, B(x: x), 'B');
  });

  group('sealed subtype and field', () {
    //   (X)    (A)
    //   /|\    /|\
    //  W Y Z  B C D
    var x = StaticType('X', isSealed: true);
    var w = StaticType('W', inherits: [x]);
    var y = StaticType('Y', inherits: [x]);
    var z = StaticType('Z', inherits: [x]);
    var a = StaticType('A', isSealed: true, fields: {'x': x, 'y': x, 'z': x});
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    StaticType('D', inherits: [a]);

    Space A({StaticType? x, StaticType? y, StaticType? z}) => ty(a,
        {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});
    Space B({StaticType? x, StaticType? y, StaticType? z}) => ty(b,
        {if (x != null) 'x': x, if (y != null) 'y': y, if (z != null) 'z': z});

    // Fields only on left.
    expectSubtract(A(x: x, y: y), a, '∅');
    expectSubtract(A(x: x, y: y), b, 'C(x: X, y: Y)|D(x: X, y: Y)');
    expectSubtract(B(x: x, y: y), a, '∅');
    expectSubtract(B(x: x, y: y), c, 'B(x: X, y: Y)');

    expectSubtract(A(x: w, y: z), a, '∅');
    expectSubtract(A(x: w, y: z), b, 'C(x: W, y: Z)|D(x: W, y: Z)');
    expectSubtract(B(x: w, y: z), a, '∅');
    expectSubtract(B(x: w, y: z), c, 'B(x: W, y: Z)');

    // Fields only on right.
    expectSubtract(a, A(x: x, y: y), 'A(x: X, y: W|Z)');
    expectSubtract(b, A(x: x, y: y), 'B(x: X, y: W|Z)');
    expectSubtract(a, B(x: x, y: y), 'B(x: X, y: W|Z)|C|D');
    expectSubtract(c, B(x: x, y: y), 'C');

    expectSubtract(a, A(x: w, y: z), 'A(x: Y|Z, y: X)|A(x: X, y: W|Y)');
    expectSubtract(b, A(x: w, y: z), 'B(x: Y|Z, y: X)|B(x: X, y: W|Y)');
    expectSubtract(a, B(x: w, y: z), 'B(x: Y|Z, y: X)|B(x: X, y: W|Y)|C|D');
    expectSubtract(c, B(x: w, y: z), 'C');
  });
}

void expectSubtract(Object left, Object right, String expected) {
  var leftSpace = parseSpace(left);
  var rightSpace = parseSpace(right);
  test('$leftSpace - $rightSpace', () {
    var result = subtract(leftSpace, rightSpace);
    expect(result.toString(), expected);
  });
}
