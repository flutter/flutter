// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";

/*class: A_dynamic:A<dynamic>,A_dynamic,Object*/
/*cfe|cfe:builder.member: A_dynamic.==:bool* Function(dynamic)*/
class A_dynamic implements A<dynamic> {}

/*class: A_void:A<void>,A_void,Object*/
/*cfe|cfe:builder.member: A_void.==:bool* Function(dynamic)*/
class A_void implements A<void> {}

/*class: B1:A<Object?>,A_Object,A_dynamic,B1,Object*/
/*cfe|cfe:builder.member: B1.toString:String Function()*/
/*cfe|cfe:builder.member: B1.runtimeType:Type*/
/*cfe|cfe:builder.member: B1._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B1._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: B1.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: B1._identityHashCode:int*/
/*cfe|cfe:builder.member: B1.hashCode:int*/
/*cfe|cfe:builder.member: B1._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B1._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B1.==:bool* Function(dynamic)**/
class B1 extends A_Object implements A_dynamic {}

/*class: B2:A<Object?>,A_Object,A_void,B2,Object*/
/*cfe|cfe:builder.member: B2.toString:String Function()*/
/*cfe|cfe:builder.member: B2.runtimeType:Type*/
/*cfe|cfe:builder.member: B2._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B2._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: B2.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: B2._identityHashCode:int*/
/*cfe|cfe:builder.member: B2.hashCode:int*/
/*cfe|cfe:builder.member: B2._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B2._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: B2.==:bool* Function(dynamic)**/
class B2 extends A_Object implements A_void {}

main() {}
