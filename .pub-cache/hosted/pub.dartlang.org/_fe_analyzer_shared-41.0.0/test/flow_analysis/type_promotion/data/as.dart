// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B {}

class C implements A, B {}

promotesIfSubtype(A a) {
  a as C;
  /*C*/ a;
}

doesNotPromoteIfNotSubtype(A a) {
  a as B;
  a;
}

doesNotPromoteIfSameType(A a) {
  a as A;
  a;
}

class D<T extends A> {
  promotesTypeParameter(T t) {
    t as C;
    /*T & C*/ t;
  }
}
