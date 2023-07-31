// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

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
class A {
  /*member: A.method:dynamic Function(dynamic, {dynamic named})**/
  dynamic method(dynamic o, {dynamic named}) {}
}

/*class: B:A,B,Object*/
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
abstract class B extends A {
  /*member: B.method:Object* Function(Object*, {Object* named})**/
  Object method(Object o, {Object named});
}

/*class: C1:A,B,C1,Object*/
/*cfe|cfe:builder.member: C1.toString:String* Function()**/
/*cfe|cfe:builder.member: C1.runtimeType:Type**/
/*cfe|cfe:builder.member: C1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C1._identityHashCode:int**/
/*cfe|cfe:builder.member: C1.hashCode:int**/
/*cfe|cfe:builder.member: C1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1.==:bool* Function(dynamic)**/
class C1 extends A implements B {
  /*member: C1.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: C2:A,B,C2,Object*/
/*cfe|cfe:builder.member: C2.toString:String* Function()**/
/*cfe|cfe:builder.member: C2.runtimeType:Type**/
/*cfe|cfe:builder.member: C2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C2._identityHashCode:int**/
/*cfe|cfe:builder.member: C2.hashCode:int**/
/*cfe|cfe:builder.member: C2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2.==:bool* Function(dynamic)**/
class C2 extends B implements A {
  /*member: C2.method:Object* Function(Object*, {Object* named})**/
  method(o, {named}) {}
}

/*class: C3:A,B,C3,Object*/
/*cfe|cfe:builder.member: C3.toString:String* Function()**/
/*cfe|cfe:builder.member: C3.runtimeType:Type**/
/*cfe|cfe:builder.member: C3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C3._identityHashCode:int**/
/*cfe|cfe:builder.member: C3.hashCode:int**/
/*cfe|cfe:builder.member: C3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3.==:bool* Function(dynamic)**/
class C3 implements A, B {
  /*member: C3.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: C4:A,B,C4,Object*/
/*cfe|cfe:builder.member: C4.toString:String* Function()**/
/*cfe|cfe:builder.member: C4.runtimeType:Type**/
/*cfe|cfe:builder.member: C4._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C4._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C4.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C4._identityHashCode:int**/
/*cfe|cfe:builder.member: C4.hashCode:int**/
/*cfe|cfe:builder.member: C4._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C4._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C4.==:bool* Function(dynamic)**/
class C4 implements B, A {
  /*member: C4.method:Object* Function(Object*, {Object* named})**/
  method(o, {named}) {}
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
abstract class D {
  /*member: D.==:bool* Function(Object*)**/
  bool operator ==(Object other);
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
abstract class F {}

/*class: E:D,E,F,Object*/
/*cfe|cfe:builder.member: E.toString:String* Function()**/
/*cfe|cfe:builder.member: E.runtimeType:Type**/
/*cfe|cfe:builder.member: E._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E._identityHashCode:int**/
/*cfe|cfe:builder.member: E.hashCode:int**/
/*cfe|cfe:builder.member: E._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._simpleInstanceOfTrue:bool* Function(dynamic)**/
class E implements D, F {
  /// TODO: Solve CFE / analyzer difference.
  /// Analyzer uses MockSdk that is migrated. So, `Object.==(Object)`.
  /// So, `D.==(Object)` matches to the `Object`, and inference does not fail
  /// and does not cause `dynamic`. I expect that the difference will be solved
  /// after SDK unfork.
  /*cfe|cfe:builder.member: E.==:bool* Function(dynamic)**/
  /*analyzer.member: E.==:bool* Function(Object*)**/
  bool operator ==(other) => true;
}
