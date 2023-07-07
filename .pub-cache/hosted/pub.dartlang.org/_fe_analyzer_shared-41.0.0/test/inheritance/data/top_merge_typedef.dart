// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

typedef Typedef1 = void Function();
typedef Typedef2 = dynamic Function();

/*class: A:A,Object*/
abstract class A {
  /*member: A.method1:void Function(void Function())*/
  void method1(void Function() f);

  /*member: A.method2:void Function(void Function())*/
  void method2(Typedef1 f);

  /*member: A.method3:void Function(void Function())*/
  void method3(Typedef1 f);

  /*member: A.method4:void Function(void Function())*/
  void method4(void Function() f);
}

/*class: B:B,Object*/
abstract class B {
  /*member: B.method1:void Function(dynamic Function())*/
  void method1(dynamic Function() f);

  /*member: B.method2:void Function(dynamic Function())*/
  void method2(Typedef2 f);

  /*member: B.method3:void Function(dynamic Function())*/
  void method3(dynamic Function() f);

  /*member: B.method4:void Function(dynamic Function())*/
  void method4(Typedef2 f);
}

/*class: C:A,B,C,Object*/
abstract class C implements A, B {
  /*member: C.method1:void Function(Object? Function())*/
  /*member: C.method2:void Function(Object? Function())*/
  /*member: C.method3:void Function(Object? Function())*/
  /*member: C.method4:void Function(Object? Function())*/
}
