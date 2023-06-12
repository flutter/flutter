// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

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

/*class: out_int:A<int*>,Object,out_int*/
/*cfe|cfe:builder.member: out_int.toString:String* Function()**/
/*cfe|cfe:builder.member: out_int.runtimeType:Type**/
/*cfe|cfe:builder.member: out_int._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: out_int._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: out_int.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: out_int._identityHashCode:int**/
/*cfe|cfe:builder.member: out_int.hashCode:int**/
/*cfe|cfe:builder.member: out_int._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: out_int._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: out_int.==:bool* Function(dynamic)**/
class out_int extends A<int> {
  /*member: out_int.getType:Type* Function()**/
}
