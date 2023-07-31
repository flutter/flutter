// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";

/*class: B:A<int?>,B,Object*/
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
class B extends A<int?> {
  /*member: B.getType:Type* Function()**/
}

/*class: C:A<int?>,B,C,Object,out_int*/
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
class C extends out_int implements B {
  /*member: C.getType:Type* Function()**/
}

Type typeOf<X>() => X;

main() {
  print(typeOf<int?>() == C().getType());
}
