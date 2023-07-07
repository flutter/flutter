// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass:Class,LegacyClass,Object*/
/*cfe|cfe:builder.member: LegacyClass.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass.==:bool* Function(dynamic)**/
class LegacyClass extends Class {
  /*member: LegacyClass.method:int* Function(int*)**/
}

/*class: LegacyInterface:Interface,LegacyInterface,Object*/
/*cfe|cfe:builder.member: LegacyInterface.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyInterface.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyInterface._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyInterface._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyInterface.hashCode:int**/
/*cfe|cfe:builder.member: LegacyInterface._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface.==:bool* Function(dynamic)**/
abstract class LegacyInterface implements Interface {
  /*member: LegacyInterface.method:int* Function(int*)**/
}

/*class: LegacySubClass:Class,Interface,LegacyClass,LegacyInterface,LegacySubClass,Object*/
/*cfe|cfe:builder.member: LegacySubClass.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacySubClass.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacySubClass._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacySubClass._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacySubClass.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacySubClass._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacySubClass.hashCode:int**/
/*cfe|cfe:builder.member: LegacySubClass._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacySubClass._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacySubClass.==:bool* Function(dynamic)**/
class LegacySubClass extends LegacyClass implements LegacyInterface {
  /*member: LegacySubClass.method:int* Function(int*)**/
}

/*class: LegacyClass2:Class2,Interface,LegacyClass2,Object*/
/*cfe|cfe:builder.member: LegacyClass2.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass2.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass2._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.==:bool* Function(dynamic)**/
abstract class LegacyClass2 extends Class2 {
  /*member: LegacyClass2.method:int* Function(int*)**/
}
