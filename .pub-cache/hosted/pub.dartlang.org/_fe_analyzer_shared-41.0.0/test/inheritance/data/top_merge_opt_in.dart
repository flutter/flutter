// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'dart:async';

/*class: A:A,Object*/
abstract class A {
  /*member: A.method:Object? Function(Object?)*/
  Object? method(Object? a);
}

/*class: B:B,Object*/
abstract class B {
  /*member: B.method:dynamic Function(dynamic)*/
  dynamic method(dynamic a);
}

/*class: C:C,Object*/
abstract class C {
  /*member: C.method:void Function(void)*/
  void method(void a);
}

/*class: D:D,Object*/
abstract class D {
  /*member: D.method:FutureOr<dynamic> Function(FutureOr<dynamic>)*/
  FutureOr method(FutureOr a);
}

/*class: E1:A,B,C,D,E1,Object*/
abstract class E1 implements A, B, C, D {
  /*member: E1.method:Object? Function(Object?)*/
}

/*class: E2:A,B,E2,Object*/
abstract class E2 implements A, B {
  /*member: E2.method:Object? Function(Object?)*/
}

/*class: E3:B,C,E3,Object*/
abstract class E3 implements B, C {
  /*member: E3.method:Object? Function(Object?)*/
}

/*class: E4:A,C,E4,Object*/
abstract class E4 implements A, C {
  /*member: E4.method:Object? Function(Object?)*/
}

/*class: E5:A,D,E5,Object*/
abstract class E5 implements A, D {
  /*member: E5.method:Object? Function(Object?)*/
}

/*class: E6:A,D,E6,Object*/
abstract class E6 implements D, A {
  /*member: E6.method:Object? Function(Object?)*/
}

/*class: F:F,Object*/
abstract class F {
  /*member: F.method:void Function(int)*/
  void method(int a);
}

/*class: G1:A,C,F,G1,Object*/
abstract class G1 implements A, C, F {
  /*member: G1.method:Object? Function(Object?)*/
}

/*class: G2:A,C,F,G2,Object*/
abstract class G2 implements A, F, C {
  /*member: G2.method:Object? Function(Object?)*/
}

/*class: G3:A,C,F,G3,Object*/
abstract class G3 implements C, A, F {
  /*member: G3.method:Object? Function(Object?)*/
}

/*class: G4:A,C,F,G4,Object*/
abstract class G4 implements C, F, A {
  /*member: G4.method:Object? Function(Object?)*/
}
