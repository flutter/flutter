// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

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
  /*member: A.method:void Function(dynamic)**/
  void method(dynamic a);
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
  /*member: B.method:void Function(num*)**/
  void method(covariant num a);
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
  /*member: C.method:void Function(int*)**/
  void method(covariant int a);
}

/*class: D1:A,B,C,D1,Object*/
/*cfe|cfe:builder.member: D1.toString:String* Function()**/
/*cfe|cfe:builder.member: D1.runtimeType:Type**/
/*cfe|cfe:builder.member: D1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D1._identityHashCode:int**/
/*cfe|cfe:builder.member: D1.hashCode:int**/
/*cfe|cfe:builder.member: D1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D1.==:bool* Function(dynamic)**/
abstract class D1 implements A, B, C {
  /*member: D1.method:void Function(dynamic)**/
}

/*class: D2:A,B,D2,Object*/
/*cfe|cfe:builder.member: D2.toString:String* Function()**/
/*cfe|cfe:builder.member: D2.runtimeType:Type**/
/*cfe|cfe:builder.member: D2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D2._identityHashCode:int**/
/*cfe|cfe:builder.member: D2.hashCode:int**/
/*cfe|cfe:builder.member: D2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D2.==:bool* Function(dynamic)**/
abstract class D2 implements A, B {
  /*member: D2.method:void Function(dynamic)**/
}

/*class: D3:B,C,D3,Object*/
/*cfe|cfe:builder.member: D3.toString:String* Function()**/
/*cfe|cfe:builder.member: D3.runtimeType:Type**/
/*cfe|cfe:builder.member: D3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D3._identityHashCode:int**/
/*cfe|cfe:builder.member: D3.hashCode:int**/
/*cfe|cfe:builder.member: D3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D3.==:bool* Function(dynamic)**/
abstract class D3 implements B, C {
  /*member: D3.method:void Function(num*)**/
}

/*class: D4:B,C,D4,Object*/
/*cfe|cfe:builder.member: D4.toString:String* Function()**/
/*cfe|cfe:builder.member: D4.runtimeType:Type**/
/*cfe|cfe:builder.member: D4._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D4._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D4.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D4._identityHashCode:int**/
/*cfe|cfe:builder.member: D4.hashCode:int**/
/*cfe|cfe:builder.member: D4._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D4._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D4.==:bool* Function(dynamic)**/
abstract class D4 implements C, B {
  /*member: D4.method:void Function(num*)**/
}

/*class: D5:A,C,D5,Object*/
/*cfe|cfe:builder.member: D5.toString:String* Function()**/
/*cfe|cfe:builder.member: D5.runtimeType:Type**/
/*cfe|cfe:builder.member: D5._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D5._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D5.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D5._identityHashCode:int**/
/*cfe|cfe:builder.member: D5.hashCode:int**/
/*cfe|cfe:builder.member: D5._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D5._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D5.==:bool* Function(dynamic)**/
abstract class D5 implements A, C {
  /*member: D5.method:void Function(dynamic)**/
}

/*class: E:E,Object*/
/*cfe|cfe:builder.member: E.toString:String* Function()**/
/*cfe|cfe:builder.member: E.runtimeType:Type**/
/*cfe|cfe:builder.member: E._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E._identityHashCode:int**/
/*cfe|cfe:builder.member: E.hashCode:int**/
/*cfe|cfe:builder.member: E._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E.==:bool* Function(dynamic)**/
abstract class E {
  /*member: E.method:void Function(num*)**/
  void method(num a);
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
  void method(covariant int a);
}

/*class: G1:E,F,G1,Object*/
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
abstract class G1 implements E, F {
  /*member: G1.method:void Function(num*)**/
}

/*class: G2:E,F,G2,Object*/
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
abstract class G2 implements F, E {
  /*member: G2.method:void Function(num*)**/
}
