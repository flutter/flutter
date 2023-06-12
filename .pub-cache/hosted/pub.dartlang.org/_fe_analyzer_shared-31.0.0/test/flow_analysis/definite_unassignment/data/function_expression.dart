// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

localFunction_local() {
  late int v;

  v = 0;

  void f() {
    late int v;
    /*unassigned*/ v;
  }
}

localFunction_local2() {
  late int v1;

  v1 = 0;

  void f() {
    late int v2, v3;
    v2 = 0;
    v1;
    v2;
    /*unassigned*/ v3;
  }
}

readInClosure_writeInMain() {
  late int v1, v2, v3;

  v1 = 0;

  [0, 1, 2].forEach((t) {
    v1;
    v2;
    /*unassigned*/ v3;
  });

  v2 = 0;
}

readInLocal_writeInLocal() {
  late int v1, v2;

  void f() {
    v1;
    /*unassigned*/ v2;
  }

  void g() {
    v1 = 0;
    v1;
    /*unassigned*/ v2;
  }

  g();
  f();
}

readInLocal_writeInMain() {
  late int v1, v2, v3;

  v1 = 0;

  void f() {
    v1;
    v2;
    /*unassigned*/ v3;
  }

  v2 = 0;
  f();
}

readInMain_writeInClosure() {
  late int v1, v2;

  /*unassigned*/ v1;
  /*unassigned*/ v2;

  [0, 1, 2].forEach((t) {
    v1 = t;
  });

  v1;
  /*unassigned*/ v2;
}

readInMain_writeInLocal() {
  late int v1, v2;

  /*unassigned*/ v1;
  /*unassigned*/ v2;

  void f() {
    v1 = 0;
  }

  v1;
  /*unassigned*/ v2;
}
