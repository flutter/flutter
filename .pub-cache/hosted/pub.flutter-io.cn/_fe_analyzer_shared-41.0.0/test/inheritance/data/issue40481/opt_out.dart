// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

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
class A<T> {}

/*class: A_Object:A<Object*>,A_Object,Object*/
/*cfe|cfe:builder.member: A_Object.toString:String* Function()**/
/*cfe|cfe:builder.member: A_Object.runtimeType:Type**/
/*cfe|cfe:builder.member: A_Object._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A_Object._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: A_Object.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: A_Object._identityHashCode:int**/
/*cfe|cfe:builder.member: A_Object.hashCode:int**/
/*cfe|cfe:builder.member: A_Object._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A_Object._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: A_Object.==:bool* Function(dynamic)**/
class A_Object implements A<Object> {}
