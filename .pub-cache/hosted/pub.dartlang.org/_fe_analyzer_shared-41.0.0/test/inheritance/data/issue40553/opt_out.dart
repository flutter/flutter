// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/
import "dart:async";

/*class: A:A<T*>,Object*/
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
class A<T> {
  /*member: A.getType:Type* Function()**/
  Type getType() => T;
}

/*class: B:A<FutureOr<int*>*>,B,Object*/
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
class B extends A<FutureOr<int>> {
  /*member: B.getType:Type* Function()**/
}
