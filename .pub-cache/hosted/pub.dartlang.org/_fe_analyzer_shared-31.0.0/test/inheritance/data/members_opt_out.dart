// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

/*class: A1:A1,Object*/
/*cfe|cfe:builder.member: A1.toString:String* Function()**/
/*cfe|cfe:builder.member: A1.runtimeType:Type**/
/*cfe|cfe:builder.member: A1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A1._identityHashCode:int**/
/*cfe|cfe:builder.member: A1.hashCode:int**/
/*cfe|cfe:builder.member: A1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A1.==:bool* Function(dynamic)**/
abstract class A1 {
  /*member: A1.close:void Function()**/
  void close();
}

/*class: B1:B1,Object*/
/*cfe|cfe:builder.member: B1.toString:String* Function()**/
/*cfe|cfe:builder.member: B1.runtimeType:Type**/
/*cfe|cfe:builder.member: B1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: B1._identityHashCode:int**/
/*cfe|cfe:builder.member: B1.hashCode:int**/
/*cfe|cfe:builder.member: B1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B1.==:bool* Function(dynamic)**/
abstract class B1 {
  /*member: B1.close:Object* Function()**/
  Object close();
}

/*class: C1a:A1,B1,C1a,Object*/
/*cfe|cfe:builder.member: C1a.toString:String* Function()**/
/*cfe|cfe:builder.member: C1a.runtimeType:Type**/
/*cfe|cfe:builder.member: C1a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C1a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C1a._identityHashCode:int**/
/*cfe|cfe:builder.member: C1a.hashCode:int**/
/*cfe|cfe:builder.member: C1a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1a.==:bool* Function(dynamic)**/
abstract class C1a implements A1, B1 {
  /*member: C1a.close:Object* Function()**/
  Object close();
}

/*class: C1b:A1,B1,C1b,Object*/
/*cfe|cfe:builder.member: C1b.toString:String* Function()**/
/*cfe|cfe:builder.member: C1b.runtimeType:Type**/
/*cfe|cfe:builder.member: C1b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C1b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C1b._identityHashCode:int**/
/*cfe|cfe:builder.member: C1b.hashCode:int**/
/*cfe|cfe:builder.member: C1b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C1b.==:bool* Function(dynamic)**/
abstract class C1b implements B1, A1 {
  /*member: C1b.close:Object* Function()**/
  Object close();
}

/*class: A2:A2<T*>,Object*/
/*cfe|cfe:builder.member: A2.toString:String* Function()**/
/*cfe|cfe:builder.member: A2.runtimeType:Type**/
/*cfe|cfe:builder.member: A2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A2._identityHashCode:int**/
/*cfe|cfe:builder.member: A2.hashCode:int**/
/*cfe|cfe:builder.member: A2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A2.==:bool* Function(dynamic)**/
abstract class A2<T> {
  /*member: A2.close:void Function()**/
  void close();
}

/*class: B2a:B2a<T*>,Object*/
/*cfe|cfe:builder.member: B2a.toString:String* Function()**/
/*cfe|cfe:builder.member: B2a.runtimeType:Type**/
/*cfe|cfe:builder.member: B2a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B2a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: B2a._identityHashCode:int**/
/*cfe|cfe:builder.member: B2a.hashCode:int**/
/*cfe|cfe:builder.member: B2a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2a.==:bool* Function(dynamic)**/
abstract class B2a<T> {
  /*member: B2a.close:Object* Function()**/
  Object close();
}

/*class: B2b:B2a<dynamic>,B2b<T*>,Object*/
/*cfe|cfe:builder.member: B2b.toString:String* Function()**/
/*cfe|cfe:builder.member: B2b.runtimeType:Type**/
/*cfe|cfe:builder.member: B2b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B2b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: B2b._identityHashCode:int**/
/*cfe|cfe:builder.member: B2b.hashCode:int**/
/*cfe|cfe:builder.member: B2b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2b.==:bool* Function(dynamic)**/
abstract class B2b<T> implements B2a {
  /*member: B2b.close:Object* Function()**/
  Object close();
}

/*class: C2a:A2<T*>,B2a<dynamic>,B2b<T*>,C2a<T*>,Object*/
/*cfe|cfe:builder.member: C2a.toString:String* Function()**/
/*cfe|cfe:builder.member: C2a.runtimeType:Type**/
/*cfe|cfe:builder.member: C2a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C2a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C2a._identityHashCode:int**/
/*cfe|cfe:builder.member: C2a.hashCode:int**/
/*cfe|cfe:builder.member: C2a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2a.==:bool* Function(dynamic)**/
abstract class C2a<T> implements A2<T>, B2b<T> {
  /*member: C2a.close:Object* Function()**/
  Object close();
}

/*class: C2b:A2<T*>,B2a<dynamic>,B2b<T*>,C2b<T*>,Object*/
/*cfe|cfe:builder.member: C2b.toString:String* Function()**/
/*cfe|cfe:builder.member: C2b.runtimeType:Type**/
/*cfe|cfe:builder.member: C2b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C2b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C2b._identityHashCode:int**/
/*cfe|cfe:builder.member: C2b.hashCode:int**/
/*cfe|cfe:builder.member: C2b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C2b.==:bool* Function(dynamic)**/
abstract class C2b<T> implements B2b<T>, A2<T> {
  /*member: C2b.close:Object* Function()**/
  Object close();
}

/*class: A3a:A3a<T*>,Object*/
/*cfe|cfe:builder.member: A3a.toString:String* Function()**/
/*cfe|cfe:builder.member: A3a.runtimeType:Type**/
/*cfe|cfe:builder.member: A3a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A3a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A3a._identityHashCode:int**/
/*cfe|cfe:builder.member: A3a.hashCode:int**/
/*cfe|cfe:builder.member: A3a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3a.==:bool* Function(dynamic)**/
abstract class A3a<T> {
  /*member: A3a.close:void Function()**/
  void close();
}

/*class: A3b:A3a<T*>,A3b<T*>,Object*/
/*cfe|cfe:builder.member: A3b.toString:String* Function()**/
/*cfe|cfe:builder.member: A3b.runtimeType:Type**/
/*cfe|cfe:builder.member: A3b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A3b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A3b._identityHashCode:int**/
/*cfe|cfe:builder.member: A3b.hashCode:int**/
/*cfe|cfe:builder.member: A3b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A3b.==:bool* Function(dynamic)**/
abstract class A3b<T> implements A3a<T> {
  /*member: A3b.close:void Function()**/
  void close();
}

/*class: B3:B3<T*>,Object*/
/*cfe|cfe:builder.member: B3.toString:String* Function()**/
/*cfe|cfe:builder.member: B3.runtimeType:Type**/
/*cfe|cfe:builder.member: B3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: B3._identityHashCode:int**/
/*cfe|cfe:builder.member: B3.hashCode:int**/
/*cfe|cfe:builder.member: B3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B3.==:bool* Function(dynamic)**/
abstract class B3<T> {
  /*member: B3.close:Object* Function()**/
  Object close();
}

/*class: C3a:A3a<T*>,A3b<T*>,B3<T*>,C3a<T*>,Object*/
/*cfe|cfe:builder.member: C3a.toString:String* Function()**/
/*cfe|cfe:builder.member: C3a.runtimeType:Type**/
/*cfe|cfe:builder.member: C3a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C3a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C3a._identityHashCode:int**/
/*cfe|cfe:builder.member: C3a.hashCode:int**/
/*cfe|cfe:builder.member: C3a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3a.==:bool* Function(dynamic)**/
abstract class C3a<T> implements A3b<T>, B3<T> {
  /*member: C3a.close:Object* Function()**/
  Object close();
}

/*class: C3b:A3a<T*>,A3b<T*>,B3<T*>,C3b<T*>,Object*/
/*cfe|cfe:builder.member: C3b.toString:String* Function()**/
/*cfe|cfe:builder.member: C3b.runtimeType:Type**/
/*cfe|cfe:builder.member: C3b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C3b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C3b._identityHashCode:int**/
/*cfe|cfe:builder.member: C3b.hashCode:int**/
/*cfe|cfe:builder.member: C3b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C3b.==:bool* Function(dynamic)**/
abstract class C3b<T> implements B3<T>, A3b<T> {
  /*member: C3b.close:Object* Function()**/
  Object close();
}
