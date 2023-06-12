// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

import "opt_in.dart";

/*class: A:A,NONNULLABLE,NULLABLE,Object*/
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
class A extends NULLABLE implements NONNULLABLE {
  /*member: A.i:int**/
  /*member: A.i=:int**/
}
