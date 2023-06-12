// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass1:Class,Interface,LegacyClass1,Object*/
/*cfe|cfe:builder.member: LegacyClass1.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass1.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass1._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.==:bool* Function(dynamic)**/
abstract class LegacyClass1 extends Class implements Interface {
  /*member: LegacyClass1.method:int* Function(int*)**/
}

/*class: LegacyClass2:Class,LegacyClass2,Object*/
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
abstract class LegacyClass2 extends Class {
  /*member: LegacyClass2.method:int* Function(int*)**/
}

/*class: GenericLegacyClass1a:GenericClass1,GenericInterface<int*>,GenericLegacyClass1a,Object*/
/*cfe|cfe:builder.member: GenericLegacyClass1a.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericLegacyClass1a.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericLegacyClass1a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericLegacyClass1a._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass1a.hashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass1a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1a.==:bool* Function(dynamic)**/
abstract class GenericLegacyClass1a extends GenericClass1 {
  /*member: GenericLegacyClass1a.method:int* Function(int*)**/
}

/*class: GenericLegacyClass1b:GenericClass1,GenericInterface<int*>,GenericLegacyClass1b,Object*/
/*cfe|cfe:builder.member: GenericLegacyClass1b.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericLegacyClass1b.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericLegacyClass1b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericLegacyClass1b._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass1b.hashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass1b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass1b.==:bool* Function(dynamic)**/
abstract class GenericLegacyClass1b extends GenericClass1
    implements GenericInterface<int> {
  /*member: GenericLegacyClass1b.method:int* Function(int*)**/
}

/*class: GenericLegacyClass2a:GenericClass2,GenericInterface<int*>,GenericLegacyClass2a,Object*/
/*cfe|cfe:builder.member: GenericLegacyClass2a.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericLegacyClass2a.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericLegacyClass2a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericLegacyClass2a._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass2a.hashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass2a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2a.==:bool* Function(dynamic)**/
abstract class GenericLegacyClass2a extends GenericClass2 {
  /*member: GenericLegacyClass2a.method:int* Function(int*)**/
}

/*class: GenericLegacyClass2b:GenericClass2,GenericInterface<int*>,GenericLegacyClass2b,Object*/
/*cfe|cfe:builder.member: GenericLegacyClass2b.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericLegacyClass2b.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericLegacyClass2b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericLegacyClass2b._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass2b.hashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass2b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass2b.==:bool* Function(dynamic)**/
abstract class GenericLegacyClass2b extends GenericClass2
    implements GenericInterface<int> {
  /*member: GenericLegacyClass2b.method:int* Function(int*)**/
}
