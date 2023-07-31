// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'env.dart';
import 'utils.dart';

void main() {
  var x = 'x';
  var y = 'y';
  var z = 'z';
  var w = 'w';

  group('nested records |', () {
    //   (A)
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var t = env.createRecordType({'x': a, 'y': b});
    var u = env.createRecordType({'w': t, 'z': t});

    expectExhaustiveOnlyAll(u, [
      ty(u, {
        w: ty(t, {x: a}),
        z: t
      }),
    ]);

    expectExhaustiveOnlyAll(u, [
      ty(u, {
        w: ty(t, {x: a, y: a}),
        z: ty(t, {x: a, y: a})
      }),
    ]);

    expectExhaustiveOnlyAll(u, [
      ty(u, {
        w: ty(t, {x: a, y: b}),
        z: ty(t, {x: a, y: b})
      }),
    ]);

    expectExhaustiveOnlyAll(u, [
      ty(u, {
        w: ty(t, {x: b}),
        z: t
      }),
      ty(u, {
        w: ty(t, {x: c}),
        z: t
      }),
    ]);

    expectExhaustiveOnlyAll(u, [
      ty(u, {
        w: ty(t, {x: b, y: b}),
        z: ty(t, {x: b, y: b})
      }),
      ty(u, {
        w: ty(t, {x: b, y: b}),
        z: ty(t, {x: c, y: b})
      }),
      ty(u, {
        w: ty(t, {x: c, y: b}),
        z: ty(t, {x: b, y: b})
      }),
      ty(u, {
        w: ty(t, {x: c, y: b}),
        z: ty(t, {x: c, y: b})
      }),
    ]);
  });

  group('nested with different fields of same name |', () {
    // A B C D
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createRecordType({'x': a});
    var c = env.createRecordType({'x': b});
    var d = env.createRecordType({'x': c});

    expectExhaustiveOnlyAll(d, [
      ty(d, {
        x: ty(c, {
          x: ty(b, {x: a})
        })
      }),
    ]);
  });
}
