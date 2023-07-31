// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_in.dart';
import 'opt_out.dart';

/*class: SubClass1:Class,Interface,LegacyClass1,Object,SubClass1*/
/*cfe|cfe:builder.member: SubClass1.toString:String* Function()**/
/*cfe|cfe:builder.member: SubClass1.runtimeType:Type**/
/*cfe|cfe:builder.member: SubClass1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: SubClass1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: SubClass1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: SubClass1._identityHashCode:int**/
/*cfe|cfe:builder.member: SubClass1.hashCode:int**/
/*cfe|cfe:builder.member: SubClass1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: SubClass1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: SubClass1.==:bool* Function(dynamic)**/
class SubClass1 extends LegacyClass1 {
  /*member: SubClass1.method:int* Function(int*)**/
}

/*class: SubClass2:Class,Interface,LegacyClass2,Object,SubClass2*/
/*cfe|cfe:builder.member: SubClass2.toString:String Function()*/
/*cfe|cfe:builder.member: SubClass2.runtimeType:Type*/
/*cfe|cfe:builder.member: SubClass2._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: SubClass2._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: SubClass2.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: SubClass2._identityHashCode:int*/
/*cfe|cfe:builder.member: SubClass2.hashCode:int*/
/*cfe|cfe:builder.member: SubClass2._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: SubClass2._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: SubClass2.==:bool* Function(dynamic)**/
class SubClass2 extends LegacyClass2 implements Interface {
  /*member: SubClass2.method:int? Function(int)*/
}

/*class: GenericSubClass1a:GenericClass1,GenericInterface<int?>,GenericLegacyClass1a,GenericSubClass1a,Object*/
/*cfe|cfe:builder.member: GenericSubClass1a.toString:String Function()*/
/*cfe|cfe:builder.member: GenericSubClass1a.runtimeType:Type*/
/*cfe|cfe:builder.member: GenericSubClass1a._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1a._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1a.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: GenericSubClass1a._identityHashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass1a.hashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass1a._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1a._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1a.==:bool* Function(dynamic)**/
abstract class GenericSubClass1a extends GenericLegacyClass1a
    implements GenericInterface<int?> {
  /*member: GenericSubClass1a.method:int? Function(int?)*/
}

/*class: GenericSubClass1b:GenericClass1,GenericInterface<int?>,GenericLegacyClass1b,GenericSubClass1b,Object*/
/*cfe|cfe:builder.member: GenericSubClass1b.toString:String Function()*/
/*cfe|cfe:builder.member: GenericSubClass1b.runtimeType:Type*/
/*cfe|cfe:builder.member: GenericSubClass1b._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1b._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1b.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: GenericSubClass1b._identityHashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass1b.hashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass1b._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1b._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass1b.==:bool* Function(dynamic)**/
abstract class GenericSubClass1b extends GenericLegacyClass1b
    implements GenericInterface<int?> {
  /*member: GenericSubClass1b.method:int? Function(int?)*/
}

/*class: GenericSubClass2a:GenericClass2,GenericInterface<int>,GenericLegacyClass2a,GenericSubClass2a,Object*/
/*cfe|cfe:builder.member: GenericSubClass2a.toString:String Function()*/
/*cfe|cfe:builder.member: GenericSubClass2a.runtimeType:Type*/
/*cfe|cfe:builder.member: GenericSubClass2a._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2a._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2a.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: GenericSubClass2a._identityHashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass2a.hashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass2a._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2a._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2a.==:bool* Function(dynamic)**/
abstract class GenericSubClass2a extends GenericLegacyClass2a
    implements GenericInterface<int> {
  /*member: GenericSubClass2a.method:int Function(int)*/
}

/*class: GenericSubClass2b:GenericClass2,GenericInterface<int>,GenericLegacyClass2b,GenericSubClass2b,Object*/
/*cfe|cfe:builder.member: GenericSubClass2b.toString:String Function()*/
/*cfe|cfe:builder.member: GenericSubClass2b.runtimeType:Type*/
/*cfe|cfe:builder.member: GenericSubClass2b._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2b._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2b.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: GenericSubClass2b._identityHashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass2b.hashCode:int*/
/*cfe|cfe:builder.member: GenericSubClass2b._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2b._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: GenericSubClass2b.==:bool* Function(dynamic)**/
abstract class GenericSubClass2b extends GenericLegacyClass2b
    implements GenericInterface<int> {
  /*member: GenericSubClass2b.method:int Function(int)*/
}
