// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  /*member: C.constructor:declared={a, b}, assigned={a}*/
  C.constructor(int a, int b) {
    a = 0;
  }
}

class D {
  const D(bool b) : assert(b);
}

class E {
  final String a;
  final String? b;

  const E(this.a, {this.b});
}
