// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('nested records', () {
    //   (A)
    //   / \
    //  B   C
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var t = StaticType('T', fields: {'x': a, 'y': b});
    var u = StaticType('U', fields: {'w': t, 'z': t});

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a), z: t),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a, y: a), z: rec(x: a, y: a)),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a, y: b), z: rec(x: a, y: b)),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: b), z: t),
      rec(w: rec(x: c), z: t),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: b, y: b), z: rec(x: b, y: b)),
      rec(w: rec(x: b, y: b), z: rec(x: c, y: b)),
      rec(w: rec(x: c, y: b), z: rec(x: b, y: b)),
      rec(w: rec(x: c, y: b), z: rec(x: c, y: b)),
    ]);
  });

  group('nested with different fields of same name', () {
    // A B C D
    var a = StaticType('A');
    var b = StaticType('B', fields: {'x': a});
    var c = StaticType('C', fields: {'x': b});
    var d = StaticType('D', fields: {'x': c});

    expectExhaustiveOnlyAll(d, [
      rec(x: rec(x: rec(x: a))),
    ]);
  });
}
