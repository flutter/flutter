// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('sealed subtypes', () {
    //   (A)
    //   / \
    //  B   C
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var t = StaticType('T', fields: {'x': a, 'y': a});

    expectExhaustiveOnlyAll(t, [
      {'x': b, 'y': b},
      {'x': b, 'y': c},
      {'x': c, 'y': b},
      {'x': c, 'y': c},
    ]);
  });

  group('sealed subtypes medium', () {
    //   (A)
    //   /|\
    //  B C D
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [a]);
    var t = StaticType('T', fields: {'y': a, 'z': a});

    expectExhaustiveOnlyAll(t, [
      {'y': b, 'z': b},
      {'y': b, 'z': c},
      {'y': b, 'z': d},
      {'y': c, 'z': b},
      {'y': c, 'z': c},
      {'y': c, 'z': d},
      {'y': d, 'z': b},
      {'y': d, 'z': c},
      {'y': d, 'z': d},
    ]);
  });

  group('sealed subtypes large', () {
    //   (A)
    //   /|\
    //  B C D
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [a]);
    var t = StaticType('T', fields: {'w': a, 'x': a, 'y': a, 'z': a});

    expectExhaustiveOnlyAll(t, [
      {'w': b, 'x': b, 'y': b, 'z': b},
      {'w': b, 'x': b, 'y': b, 'z': c},
      {'w': b, 'x': b, 'y': b, 'z': d},
      {'w': b, 'x': b, 'y': c, 'z': b},
      {'w': b, 'x': b, 'y': c, 'z': c},
      {'w': b, 'x': b, 'y': c, 'z': d},
      {'w': b, 'x': b, 'y': d, 'z': b},
      {'w': b, 'x': b, 'y': d, 'z': c},
      {'w': b, 'x': b, 'y': d, 'z': d},
      {'w': b, 'x': c, 'y': b, 'z': b},
      {'w': b, 'x': c, 'y': b, 'z': c},
      {'w': b, 'x': c, 'y': b, 'z': d},
      {'w': b, 'x': c, 'y': c, 'z': b},
      {'w': b, 'x': c, 'y': c, 'z': c},
      {'w': b, 'x': c, 'y': c, 'z': d},
      {'w': b, 'x': c, 'y': d, 'z': b},
      {'w': b, 'x': c, 'y': d, 'z': c},
      {'w': b, 'x': c, 'y': d, 'z': d},
      {'w': b, 'x': d, 'y': b, 'z': b},
      {'w': b, 'x': d, 'y': b, 'z': c},
      {'w': b, 'x': d, 'y': b, 'z': d},
      {'w': b, 'x': d, 'y': c, 'z': b},
      {'w': b, 'x': d, 'y': c, 'z': c},
      {'w': b, 'x': d, 'y': c, 'z': d},
      {'w': b, 'x': d, 'y': d, 'z': b},
      {'w': b, 'x': d, 'y': d, 'z': c},
      {'w': b, 'x': d, 'y': d, 'z': d},
      {'w': c, 'x': b, 'y': b, 'z': b},
      {'w': c, 'x': b, 'y': b, 'z': c},
      {'w': c, 'x': b, 'y': b, 'z': d},
      {'w': c, 'x': b, 'y': c, 'z': b},
      {'w': c, 'x': b, 'y': c, 'z': c},
      {'w': c, 'x': b, 'y': c, 'z': d},
      {'w': c, 'x': b, 'y': d, 'z': b},
      {'w': c, 'x': b, 'y': d, 'z': c},
      {'w': c, 'x': b, 'y': d, 'z': d},
      {'w': c, 'x': c, 'y': b, 'z': b},
      {'w': c, 'x': c, 'y': b, 'z': c},
      {'w': c, 'x': c, 'y': b, 'z': d},
      {'w': c, 'x': c, 'y': c, 'z': b},
      {'w': c, 'x': c, 'y': c, 'z': c},
      {'w': c, 'x': c, 'y': c, 'z': d},
      {'w': c, 'x': c, 'y': d, 'z': b},
      {'w': c, 'x': c, 'y': d, 'z': c},
      {'w': c, 'x': c, 'y': d, 'z': d},
      {'w': c, 'x': d, 'y': b, 'z': b},
      {'w': c, 'x': d, 'y': b, 'z': c},
      {'w': c, 'x': d, 'y': b, 'z': d},
      {'w': c, 'x': d, 'y': c, 'z': b},
      {'w': c, 'x': d, 'y': c, 'z': c},
      {'w': c, 'x': d, 'y': c, 'z': d},
      {'w': c, 'x': d, 'y': d, 'z': b},
      {'w': c, 'x': d, 'y': d, 'z': c},
      {'w': c, 'x': d, 'y': d, 'z': d},
      {'w': d, 'x': b, 'y': b, 'z': b},
      {'w': d, 'x': b, 'y': b, 'z': c},
      {'w': d, 'x': b, 'y': b, 'z': d},
      {'w': d, 'x': b, 'y': c, 'z': b},
      {'w': d, 'x': b, 'y': c, 'z': c},
      {'w': d, 'x': b, 'y': c, 'z': d},
      {'w': d, 'x': b, 'y': d, 'z': b},
      {'w': d, 'x': b, 'y': d, 'z': c},
      {'w': d, 'x': b, 'y': d, 'z': d},
      {'w': d, 'x': c, 'y': b, 'z': b},
      {'w': d, 'x': c, 'y': b, 'z': c},
      {'w': d, 'x': c, 'y': b, 'z': d},
      {'w': d, 'x': c, 'y': c, 'z': b},
      {'w': d, 'x': c, 'y': c, 'z': c},
      {'w': d, 'x': c, 'y': c, 'z': d},
      {'w': d, 'x': c, 'y': d, 'z': b},
      {'w': d, 'x': c, 'y': d, 'z': c},
      {'w': d, 'x': c, 'y': d, 'z': d},
      {'w': d, 'x': d, 'y': b, 'z': b},
      {'w': d, 'x': d, 'y': b, 'z': c},
      {'w': d, 'x': d, 'y': b, 'z': d},
      {'w': d, 'x': d, 'y': c, 'z': b},
      {'w': d, 'x': d, 'y': c, 'z': c},
      {'w': d, 'x': d, 'y': c, 'z': d},
      {'w': d, 'x': d, 'y': d, 'z': b},
      {'w': d, 'x': d, 'y': d, 'z': c},
      {'w': d, 'x': d, 'y': d, 'z': d},
    ]);
  });

  group('sealed transitive subtypes', () {
    //     (A)
    //     / \
    //   (B) (C)
    //   / \   \
    //  D   E   F
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', isSealed: true, inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b]);
    var f = StaticType('F', inherits: [c]);

    var t = StaticType('T', fields: {'x': a, 'y': a});
    expectExhaustiveOnlyAll(t, [
      {'x': a, 'y': a},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'x': b, 'y': b},
      {'x': b, 'y': c},
      {'x': c, 'y': b},
      {'x': c, 'y': c},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'x': b, 'y': d},
      {'x': b, 'y': e},
      {'x': b, 'y': f},
      {'x': c, 'y': d},
      {'x': c, 'y': e},
      {'x': c, 'y': f},
    ]);
  });

  group('unsealed subtypes', () {
    //    A
    //   / \
    //  B   C
    var a = StaticType('A');
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);

    // Not exhaustive even when known subtypes covered.
    var t = StaticType('T', fields: {'x': a, 'y': a});
    expectNeverExhaustive(t, [
      {'x': b, 'y': b},
      {'x': b, 'y': c},
      {'x': c, 'y': b},
      {'x': c, 'y': c},
    ]);

    // Exhaustive if field static type is a covered subtype.
    var u = StaticType('T', fields: {'x': b, 'y': c});
    expectExhaustiveOnlyAll(u, [
      {'x': b, 'y': c},
    ]);
  });

  group('different fields', () {
    //   (A)
    //   / \
    //  B   C
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var t = StaticType('T', fields: {'x': a, 'y': a, 'z': a});

    expectNeverExhaustive(t, [
      {'x': b},
      {'y': b},
      {'z': b},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'x': b, 'y': a},
      {'x': c, 'z': a},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'x': b, 'y': b},
      {'x': b, 'y': c},
      {'x': c, 'y': b},
      {'x': c, 'y': c},
    ]);
  });

  group('field types', () {
    //   (A)
    //   / \
    //  B   C
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var t = StaticType('T', fields: {'x': a, 'y': b, 'z': c});

    expectExhaustiveOnlyAll(t, [
      {'x': a, 'y': b, 'z': c},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'x': b},
      {'x': c},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'y': b},
    ]);

    expectExhaustiveOnlyAll(t, [
      {'z': c},
    ]);
  });
}
