// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
/*class: A:A<T>,Object*/
class A<T> {
  /*member: A.test:void Function()*/
  void test() {
    print(T);
  }
}

/*class: B:A<Object?>,B,Object*/
class B extends A<Object?> {
  /*member: B.test:void Function()*/
}

/*class: C:A<dynamic>,C,Object*/
class C extends A<dynamic> {
  /*member: C.test:void Function()*/
}

/*class: D1:A<Object?>,B,C,D1,Object*/
class D1 extends B implements C {
  /*member: D1.test:void Function()*/
}

/*class: D2:A<Object?>,B,C,D2,Object*/
class D2 extends C implements B {
  /*member: D2.test:void Function()*/
}

void main() {
  D1().test();
  D2().test();
}
