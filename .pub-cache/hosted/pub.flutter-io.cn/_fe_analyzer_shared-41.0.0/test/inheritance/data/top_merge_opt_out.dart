// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'dart:async';

/*class: A:A,Object*/
/*cfe|cfe:builder.member: A.toString:String* Function()**/
/*cfe|cfe:builder.member: A.runtimeType:Type**/
/*cfe|cfe:builder.member: A._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A._identityHashCode:int**/
/*cfe|cfe:builder.member: A.hashCode:int**/
/*cfe|cfe:builder.member: A._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A.==:bool* Function(dynamic)**/
abstract class A {
  /*member: A.method:Object* Function(Object*)**/
  Object method(Object a);
}

/*class: B:B,Object*/
/*cfe|cfe:builder.member: B.toString:String* Function()**/
/*cfe|cfe:builder.member: B.runtimeType:Type**/
/*cfe|cfe:builder.member: B._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: B._identityHashCode:int**/
/*cfe|cfe:builder.member: B.hashCode:int**/
/*cfe|cfe:builder.member: B._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B.==:bool* Function(dynamic)**/
abstract class B {
  /*member: B.method:dynamic Function(dynamic)**/
  dynamic method(dynamic a);
}

/*class: C:C,Object*/
/*cfe|cfe:builder.member: C.toString:String* Function()**/
/*cfe|cfe:builder.member: C.runtimeType:Type**/
/*cfe|cfe:builder.member: C._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C._identityHashCode:int**/
/*cfe|cfe:builder.member: C.hashCode:int**/
/*cfe|cfe:builder.member: C._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C.==:bool* Function(dynamic)**/
abstract class C {
  /*member: C.method:void Function(void)**/
  void method(void a);
}

/*class: D:D,Object*/
/*cfe|cfe:builder.member: D.toString:String* Function()**/
/*cfe|cfe:builder.member: D.runtimeType:Type**/
/*cfe|cfe:builder.member: D._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D._identityHashCode:int**/
/*cfe|cfe:builder.member: D.hashCode:int**/
/*cfe|cfe:builder.member: D._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D.==:bool* Function(dynamic)**/
abstract class D {
  /*member: D.method:FutureOr<dynamic>* Function(FutureOr<dynamic>*)**/
  FutureOr method(FutureOr a);
}

/*class: E1:A,B,C,E1,Object*/
/*cfe|cfe:builder.member: E1.toString:String* Function()**/
/*cfe|cfe:builder.member: E1.runtimeType:Type**/
/*cfe|cfe:builder.member: E1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E1._identityHashCode:int**/
/*cfe|cfe:builder.member: E1.hashCode:int**/
/*cfe|cfe:builder.member: E1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E1.==:bool* Function(dynamic)**/
abstract class E1 implements A, B, C {
  /*member: E1.method:Object* Function(Object*)**/
}

/*class: E2:A,B,E2,Object*/
/*cfe|cfe:builder.member: E2.toString:String* Function()**/
/*cfe|cfe:builder.member: E2.runtimeType:Type**/
/*cfe|cfe:builder.member: E2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E2._identityHashCode:int**/
/*cfe|cfe:builder.member: E2.hashCode:int**/
/*cfe|cfe:builder.member: E2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E2.==:bool* Function(dynamic)**/
abstract class E2 implements A, B {
  /*member: E2.method:Object* Function(Object*)**/
}

/*class: E3:B,C,E3,Object*/
/*cfe|cfe:builder.member: E3.toString:String* Function()**/
/*cfe|cfe:builder.member: E3.runtimeType:Type**/
/*cfe|cfe:builder.member: E3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E3._identityHashCode:int**/
/*cfe|cfe:builder.member: E3.hashCode:int**/
/*cfe|cfe:builder.member: E3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E3.==:bool* Function(dynamic)**/
abstract class E3 implements B, C {
  /*member: E3.method:dynamic Function(dynamic)**/
}

/*class: E4:A,C,E4,Object*/
/*cfe|cfe:builder.member: E4.toString:String* Function()**/
/*cfe|cfe:builder.member: E4.runtimeType:Type**/
/*cfe|cfe:builder.member: E4._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E4._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E4.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E4._identityHashCode:int**/
/*cfe|cfe:builder.member: E4.hashCode:int**/
/*cfe|cfe:builder.member: E4._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E4._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E4.==:bool* Function(dynamic)**/
abstract class E4 implements A, C {
  /*member: E4.method:Object* Function(Object*)**/
}

/*class: E5:A,D,E5,Object*/
/*cfe|cfe:builder.member: E5.toString:String* Function()**/
/*cfe|cfe:builder.member: E5.runtimeType:Type**/
/*cfe|cfe:builder.member: E5._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E5._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E5.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E5._identityHashCode:int**/
/*cfe|cfe:builder.member: E5.hashCode:int**/
/*cfe|cfe:builder.member: E5._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E5._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E5.==:bool* Function(dynamic)**/
abstract class E5 implements A, D {
  /*member: E5.method:Object* Function(Object*)**/
}

/*class: E6:A,D,E6,Object*/
/*cfe|cfe:builder.member: E6.toString:String* Function()**/
/*cfe|cfe:builder.member: E6.runtimeType:Type**/
/*cfe|cfe:builder.member: E6._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E6._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E6.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E6._identityHashCode:int**/
/*cfe|cfe:builder.member: E6.hashCode:int**/
/*cfe|cfe:builder.member: E6._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E6._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E6.==:bool* Function(dynamic)**/
abstract class E6 implements D, A {
  /*member: E6.method:FutureOr<dynamic>* Function(FutureOr<dynamic>*)**/
}

/*class: F:F,Object*/
/*cfe|cfe:builder.member: F.toString:String* Function()**/
/*cfe|cfe:builder.member: F.runtimeType:Type**/
/*cfe|cfe:builder.member: F._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: F._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: F.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: F._identityHashCode:int**/
/*cfe|cfe:builder.member: F.hashCode:int**/
/*cfe|cfe:builder.member: F._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: F._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: F.==:bool* Function(dynamic)**/
abstract class F {
  /*member: F.method:void Function(int*)**/
  void method(int a);
}

/*class: G1:A,C,F,G1,Object*/
/*cfe|cfe:builder.member: G1.toString:String* Function()**/
/*cfe|cfe:builder.member: G1.runtimeType:Type**/
/*cfe|cfe:builder.member: G1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: G1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: G1._identityHashCode:int**/
/*cfe|cfe:builder.member: G1.hashCode:int**/
/*cfe|cfe:builder.member: G1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G1.==:bool* Function(dynamic)**/
abstract class G1 implements A, C, F {
  /*member: G1.method:Object* Function(Object*)**/
}

/*class: G2:A,C,F,G2,Object*/
/*cfe|cfe:builder.member: G2.toString:String* Function()**/
/*cfe|cfe:builder.member: G2.runtimeType:Type**/
/*cfe|cfe:builder.member: G2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: G2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: G2._identityHashCode:int**/
/*cfe|cfe:builder.member: G2.hashCode:int**/
/*cfe|cfe:builder.member: G2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G2.==:bool* Function(dynamic)**/
abstract class G2 implements A, F, C {
  /*member: G2.method:Object* Function(Object*)**/
}

/*class: G3:A,C,F,G3,Object*/
/*cfe|cfe:builder.member: G3.toString:String* Function()**/
/*cfe|cfe:builder.member: G3.runtimeType:Type**/
/*cfe|cfe:builder.member: G3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: G3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: G3._identityHashCode:int**/
/*cfe|cfe:builder.member: G3.hashCode:int**/
/*cfe|cfe:builder.member: G3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G3.==:bool* Function(dynamic)**/
abstract class G3 implements C, A, F {
  /*member: G3.method:void Function(void)**/
}

/*class: G4:A,C,F,G4,Object*/
/*cfe|cfe:builder.member: G4.toString:String* Function()**/
/*cfe|cfe:builder.member: G4.runtimeType:Type**/
/*cfe|cfe:builder.member: G4._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G4._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: G4.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: G4._identityHashCode:int**/
/*cfe|cfe:builder.member: G4.hashCode:int**/
/*cfe|cfe:builder.member: G4._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G4._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: G4.==:bool* Function(dynamic)**/
abstract class G4 implements C, F, A {
  /*member: G4.method:void Function(void)**/
}
