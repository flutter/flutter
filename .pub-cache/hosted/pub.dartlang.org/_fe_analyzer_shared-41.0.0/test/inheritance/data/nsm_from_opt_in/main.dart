// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

import 'opt_in.dart';

/*class: B2:A,B2,C2,Object*/
/*cfe|cfe:builder.member: B2.toString:String* Function()**/
/*cfe|cfe:builder.member: B2.runtimeType:Type**/
/*cfe|cfe:builder.member: B2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: B2._identityHashCode:int**/
/*cfe|cfe:builder.member: B2.hashCode:int**/
/*cfe|cfe:builder.member: B2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: B2.==:bool* Function(dynamic)**/
abstract class B2 extends A implements C2 {
  /*member: B2.method:int* Function(int*, {dynamic optional})**/

  /*member: B2.noSuchMethod:dynamic Function(Invocation*)**/
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/*class: C2:C2,Object*/
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
abstract class C2 {
  /*member: C2.method:int* Function(int*, {dynamic optional})**/
  int method(int i, {optional});
}
