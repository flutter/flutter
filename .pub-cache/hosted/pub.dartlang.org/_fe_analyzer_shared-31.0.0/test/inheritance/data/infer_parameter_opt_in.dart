// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*library: nnbd=true*/

/*class: A:A,Object*/
class A {
  /*member: A.method:dynamic Function(dynamic, {dynamic named})*/
  dynamic method(dynamic o, {dynamic named}) {}
}

/*class: B:A,B,Object*/
abstract class B extends A {
  /*member: B.method:Object? Function(Object?, {Object? named})*/
  Object? method(Object? o, {Object? named});
}

/*class: C:A,C,Object*/
abstract class C extends A {
  /*member: C.method:void Function(void, {void named})*/
  void method(void o, {void named});
}

/*class: D:A,D,Object*/
abstract class D extends A {
  /*member: D.method:FutureOr<dynamic> Function(FutureOr<dynamic>, {FutureOr<dynamic> named})*/
  FutureOr method(FutureOr o, {FutureOr named});
}

/*class: E1:A,B,E1,Object*/
class E1 extends A implements B {
  /*member: E1.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: E2:A,B,E2,Object*/
class E2 extends B implements A {
  /*member: E2.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: E3:A,B,E3,Object*/
class E3 implements A, B {
  /*member: E3.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: E4:A,B,E4,Object*/
class E4 implements B, A {
  /*member: E4.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: F1:A,C,F1,Object*/
class F1 extends A implements C {
  /*member: F1.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: F2:A,C,F2,Object*/
class F2 extends C implements A {
  /*member: F2.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: F3:A,C,F3,Object*/
class F3 implements A, C {
  /*member: F3.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: F4:A,C,F4,Object*/
class F4 implements C, A {
  /*member: F4.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: G1:A,B,C,G1,Object*/
class G1 extends B implements C {
  /*member: G1.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: G2:A,B,C,G2,Object*/
class G2 extends C implements B {
  /*member: G2.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: G3:A,B,C,G3,Object*/
class G3 implements B, C {
  /*member: G3.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: G4:A,B,C,G4,Object*/
class G4 implements C, B {
  /*member: G4.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: H1:A,B,D,H1,Object*/
class H1 extends B implements D {
  /*member: H1.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: H2:A,B,D,H2,Object*/
class H2 extends D implements B {
  /*member: H2.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: H3:A,B,D,H3,Object*/
class H3 implements B, D {
  /*member: H3.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}

/*class: H4:A,B,D,H4,Object*/
class H4 implements D, B {
  /*member: H4.method:Object? Function(Object?, {Object? named})*/
  method(o, {named}) {}
}
