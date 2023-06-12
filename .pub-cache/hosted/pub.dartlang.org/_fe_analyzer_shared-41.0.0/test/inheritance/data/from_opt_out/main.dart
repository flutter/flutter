// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

/*class: Class1:Class1,LegacyClass1,Object*/
/*cfe|cfe:builder.member: Class1.toString:String* Function()**/
/*cfe|cfe:builder.member: Class1.runtimeType:Type**/
/*cfe|cfe:builder.member: Class1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class1._identityHashCode:int**/
/*cfe|cfe:builder.member: Class1.hashCode:int**/
/*cfe|cfe:builder.member: Class1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class1.==:bool* Function(dynamic)**/
class Class1 extends LegacyClass1 {}

/*class: Class2:Class2<T>,LegacyClass2<T>,Object*/
/*cfe|cfe:builder.member: Class2.toString:String* Function()**/
/*cfe|cfe:builder.member: Class2.runtimeType:Type**/
/*cfe|cfe:builder.member: Class2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class2._identityHashCode:int**/
/*cfe|cfe:builder.member: Class2.hashCode:int**/
/*cfe|cfe:builder.member: Class2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class2.==:bool* Function(dynamic)**/
class Class2<T> extends LegacyClass2<T> {}

/*class: Class3a:Class3a<T>,GenericInterface<T*>,LegacyClass3<T>,Object*/
/*cfe|cfe:builder.member: Class3a.toString:String* Function()**/
/*cfe|cfe:builder.member: Class3a.runtimeType:Type**/
/*cfe|cfe:builder.member: Class3a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class3a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class3a._identityHashCode:int**/
/*cfe|cfe:builder.member: Class3a.hashCode:int**/
/*cfe|cfe:builder.member: Class3a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3a.==:bool* Function(dynamic)**/
class Class3a<T> extends LegacyClass3<T> {}

/*class: Class3b:Class3b<T>,GenericInterface<T>,LegacyClass3<T>,Object*/
/*cfe|cfe:builder.member: Class3b.toString:String* Function()**/
/*cfe|cfe:builder.member: Class3b.runtimeType:Type**/
/*cfe|cfe:builder.member: Class3b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class3b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class3b._identityHashCode:int**/
/*cfe|cfe:builder.member: Class3b.hashCode:int**/
/*cfe|cfe:builder.member: Class3b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3b.==:bool* Function(dynamic)**/
class Class3b<T> extends LegacyClass3<T> implements GenericInterface<T> {}

/*class: Class4a:Class4a,GenericInterface<num*>,LegacyClass4,Object*/
/*cfe|cfe:builder.member: Class4a.toString:String* Function()**/
/*cfe|cfe:builder.member: Class4a.runtimeType:Type**/
/*cfe|cfe:builder.member: Class4a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class4a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class4a._identityHashCode:int**/
/*cfe|cfe:builder.member: Class4a.hashCode:int**/
/*cfe|cfe:builder.member: Class4a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4a.==:bool* Function(dynamic)**/
class Class4a extends LegacyClass4 {}

/*class: Class4b:Class4b,GenericInterface<num>,Object*/
/*cfe|cfe:builder.member: Class4b.==:bool* Function(dynamic)*/
class Class4b implements GenericInterface<num> {}

/*class: Class4c:Class4c,GenericInterface<num?>,Object*/
/*cfe|cfe:builder.member: Class4c.==:bool* Function(dynamic)*/
class Class4c implements GenericInterface<num?> {}

/*class: Class4d:Class4d,GenericInterface<num>,LegacyClass4,Object*/
/*cfe|cfe:builder.member: Class4d.toString:String* Function()**/
/*cfe|cfe:builder.member: Class4d.runtimeType:Type**/
/*cfe|cfe:builder.member: Class4d._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4d._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class4d.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class4d._identityHashCode:int**/
/*cfe|cfe:builder.member: Class4d.hashCode:int**/
/*cfe|cfe:builder.member: Class4d._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4d._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class4d.==:bool* Function(dynamic)**/
class Class4d extends LegacyClass4 implements GenericInterface<num> {}
