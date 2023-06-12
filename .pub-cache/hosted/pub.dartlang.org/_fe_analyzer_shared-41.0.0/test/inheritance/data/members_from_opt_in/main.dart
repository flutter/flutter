// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass:Class,Interface,LegacyClass,Object*/
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
class LegacyClass extends Class implements Interface {
  /*member: LegacyClass.method1:int* Function()**/
  /*member: LegacyClass.method2:int* Function()**/

  /*member: LegacyClass.method3:int* Function()**/
  int method3() => 0;

  /*member: LegacyClass.method4:int* Function()**/
  int method4() => 0;

  /*member: LegacyClass.method5a:int* Function(int*, int*)**/
  /*member: LegacyClass.method5b:int* Function(int*, [int*])**/
  /*member: LegacyClass.method5c:int* Function([int*, int*])**/

  /*member: LegacyClass.method6a:int* Function(int*, int*)**/
  int method6a(int a, int b) => 0;

  /*member: LegacyClass.method6b:int* Function(int*, [int*])**/
  int method6b(int a, [int b]) => 0;

  /*member: LegacyClass.method6c:int* Function([int*, int*])**/
  int method6c([int a, int b]) => 0;

  /*member: LegacyClass.method7a:int* Function(int*, {int* b})**/
  /*member: LegacyClass.method7b:int* Function({int* a, int* b})**/

  /*member: LegacyClass.method8a:int* Function(int*, {int* b})**/
  int method8a(int a, {int b: 0}) => 0;

  /*member: LegacyClass.method8b:int* Function({int* a, int* b})**/
  int method8b({int a, int b: 0}) => 0;

  /*member: LegacyClass.method9a:int* Function(int*, {int* b})**/
  /*member: LegacyClass.method9b:int* Function({int* a, int* b})**/

  /*member: LegacyClass.method10a:int* Function(int*, {int* b})**/
  int method10a(int a, {int b}) => 0;

  /*member: LegacyClass.method10b:int* Function({int* a, int* b})**/
  int method10b({int a, int b}) => 0;

  /*member: LegacyClass.getter1:int**/
  /*member: LegacyClass.getter2:int**/

  /*member: LegacyClass.getter3:int**/
  int get getter3 => 0;

  /*member: LegacyClass.getter4:int**/
  int get getter4 => 0;

  /*member: LegacyClass.setter1=:int**/

  /*member: LegacyClass.setter2=:int**/

  /*member: LegacyClass.setter3=:int**/
  void set setter3(int value) {}

  /*member: LegacyClass.setter4=:int**/
  void set setter4(int value) {}

  /*member: LegacyClass.field1:int**/
  /*member: LegacyClass.field1=:int**/

  /*member: LegacyClass.field2:int**/
  /*member: LegacyClass.field2=:int**/

  /*member: LegacyClass.field3:int**/
  /*member: LegacyClass.field3=:int**/
  int field3;

  /*member: LegacyClass.field4:int**/
  /*member: LegacyClass.field4=:int**/
  int field4;

  /*member: LegacyClass.field5:int**/
  /*member: LegacyClass.field5=:int**/

  /*member: LegacyClass.field6a:int**/
  /*member: LegacyClass.field6a=:int**/
  var field6a = 0;

  /*member: LegacyClass.field6b:int**/
  /*member: LegacyClass.field6b=:int**/
  var field6b = constant;

  /*member: LegacyClass.property1:int**/
  /*member: LegacyClass.property1=:int**/
  /*member: LegacyClass.property2:int**/
  /*member: LegacyClass.property2=:int**/

  /*member: LegacyClass.property3:int**/
  int get property3 => 0;

  /*member: LegacyClass.property3=:int**/
  void set property3(int value) {}

  /*member: LegacyClass.property4:int**/
  int get property4 => 0;

  /*member: LegacyClass.property4=:int**/
  void set property4(int value) {}

  /*member: LegacyClass.property5:int**/
  /*member: LegacyClass.property5=:int**/

  /*member: LegacyClass.property6:int**/
  /*member: LegacyClass.property6=:int**/

  /*member: LegacyClass.property7:int**/
  /*member: LegacyClass.property7=:int**/
  int property7;

  /*member: LegacyClass.property8:int**/
  /*member: LegacyClass.property8=:int**/
  int property8;
}

/*class: LegacyClass2a:Class,LegacyClass2a,Object*/
/*cfe|cfe:builder.member: LegacyClass2a.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass2a.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass2a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass2a._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2a.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2a.==:bool* Function(dynamic)**/
abstract class LegacyClass2a extends Class {
  /*member: LegacyClass2a.field1:int**/
  /*member: LegacyClass2a.field1=:int**/
  /*member: LegacyClass2a.field2:int**/
  /*member: LegacyClass2a.field2=:int**/
  /*member: LegacyClass2a.field5:int**/
  /*member: LegacyClass2a.field5=:int**/

  /*member: LegacyClass2a.field6a:int**/
  /*member: LegacyClass2a.field6a=:int**/
  /*member: LegacyClass2a.field6b:int**/
  /*member: LegacyClass2a.field6b=:int**/

  /*member: LegacyClass2a.getter1:int**/
  /*member: LegacyClass2a.getter2:int**/

  /*member: LegacyClass2a.method1:int* Function()**/
  /*member: LegacyClass2a.method2:int* Function()**/
  /*member: LegacyClass2a.method5a:int* Function(int*, int*)**/
  /*member: LegacyClass2a.method5b:int* Function(int*, [int*])**/
  /*member: LegacyClass2a.method5c:int* Function([int*, int*])**/
  /*member: LegacyClass2a.method7a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2a.method7b:int* Function({int* a, int* b})**/
  /*member: LegacyClass2a.method9a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2a.method9b:int* Function({int* a, int* b})**/

  /*member: LegacyClass2a.property1:int**/
  /*member: LegacyClass2a.property1=:int**/
  /*member: LegacyClass2a.property2:int**/
  /*member: LegacyClass2a.property2=:int**/
  /*member: LegacyClass2a.property5:int**/
  /*member: LegacyClass2a.property5=:int**/
  /*member: LegacyClass2a.property6:int**/
  /*member: LegacyClass2a.property6=:int**/

  /*member: LegacyClass2a.setter1=:int**/
  /*member: LegacyClass2a.setter2=:int**/
}

/*class: LegacyInterface2:Interface,LegacyInterface2,Object*/
/*cfe|cfe:builder.member: LegacyInterface2.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyInterface2.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyInterface2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyInterface2._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyInterface2.hashCode:int**/
/*cfe|cfe:builder.member: LegacyInterface2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyInterface2.==:bool* Function(dynamic)**/
abstract class LegacyInterface2 implements Interface {
  /*member: LegacyInterface2.field1:int**/
  /*member: LegacyInterface2.field1=:int**/
  /*member: LegacyInterface2.field2:int**/
  /*member: LegacyInterface2.field2=:int**/
  /*member: LegacyInterface2.field3:int**/
  /*member: LegacyInterface2.field3=:int**/
  /*member: LegacyInterface2.field4:int**/
  /*member: LegacyInterface2.field4=:int**/

  /*member: LegacyInterface2.getter1:int**/
  /*member: LegacyInterface2.getter2:int**/
  /*member: LegacyInterface2.getter3:int**/
  /*member: LegacyInterface2.getter4:int**/

  /*member: LegacyInterface2.method1:int* Function()**/
  /*member: LegacyInterface2.method2:int* Function()**/
  /*member: LegacyInterface2.method3:int* Function()**/
  /*member: LegacyInterface2.method4:int* Function()**/
  /*member: LegacyInterface2.method5a:int* Function(int*, int*)**/
  /*member: LegacyInterface2.method5b:int* Function(int*, [int*])**/
  /*member: LegacyInterface2.method5c:int* Function([int*, int*])**/
  /*member: LegacyInterface2.method6a:int* Function(int*, int*)**/
  /*member: LegacyInterface2.method6b:int* Function(int*, [int*])**/
  /*member: LegacyInterface2.method6c:int* Function([int*, int*])**/
  /*member: LegacyInterface2.method7a:int* Function(int*, {int* b})**/
  /*member: LegacyInterface2.method7b:int* Function({int* a, int* b})**/
  /*member: LegacyInterface2.method8a:int* Function(int*, {int* b})**/
  /*member: LegacyInterface2.method8b:int* Function({int* a, int* b})**/
  /*member: LegacyInterface2.method9a:int* Function(int*, {int* b})**/
  /*member: LegacyInterface2.method9b:int* Function({int* a, int* b})**/
  /*member: LegacyInterface2.method10a:int* Function(int*, {int* b})**/
  /*member: LegacyInterface2.method10b:int* Function({int* a, int* b})**/

  /*member: LegacyInterface2.property1:int**/
  /*member: LegacyInterface2.property1=:int**/
  /*member: LegacyInterface2.property2:int**/
  /*member: LegacyInterface2.property2=:int**/
  /*member: LegacyInterface2.property3:int**/
  /*member: LegacyInterface2.property3=:int**/
  /*member: LegacyInterface2.property4:int**/
  /*member: LegacyInterface2.property4=:int**/
  /*member: LegacyInterface2.property5:int**/
  /*member: LegacyInterface2.property5=:int**/
  /*member: LegacyInterface2.property6:int**/
  /*member: LegacyInterface2.property6=:int**/
  /*member: LegacyInterface2.property7:int**/
  /*member: LegacyInterface2.property7=:int**/
  /*member: LegacyInterface2.property8:int**/
  /*member: LegacyInterface2.property8=:int**/

  /*member: LegacyInterface2.setter1=:int**/
  /*member: LegacyInterface2.setter2=:int**/
  /*member: LegacyInterface2.setter3=:int**/
  /*member: LegacyInterface2.setter4=:int**/
}

/*class: LegacyClass2b:Class,Interface,LegacyClass2a,LegacyClass2b,LegacyInterface2,Object*/
/*cfe|cfe:builder.member: LegacyClass2b.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass2b.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass2b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass2b._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2b.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2b.==:bool* Function(dynamic)**/
abstract class LegacyClass2b extends LegacyClass2a implements LegacyInterface2 {
  /*member: LegacyClass2b.field1:int**/
  /*member: LegacyClass2b.field1=:int**/
  /*member: LegacyClass2b.field2:int**/
  /*member: LegacyClass2b.field2=:int**/
  /*member: LegacyClass2b.field3:int**/
  /*member: LegacyClass2b.field3=:int**/
  /*member: LegacyClass2b.field4:int**/
  /*member: LegacyClass2b.field4=:int**/
  /*member: LegacyClass2b.field5:int**/
  /*member: LegacyClass2b.field5=:int**/
  /*member: LegacyClass2b.field6a:int**/
  /*member: LegacyClass2b.field6a=:int**/
  /*member: LegacyClass2b.field6b:int**/
  /*member: LegacyClass2b.field6b=:int**/

  /*member: LegacyClass2b.getter1:int**/
  /*member: LegacyClass2b.getter2:int**/
  /*member: LegacyClass2b.getter3:int**/
  /*member: LegacyClass2b.getter4:int**/

  /*member: LegacyClass2b.method1:int* Function()**/
  /*member: LegacyClass2b.method2:int* Function()**/
  /*member: LegacyClass2b.method3:int* Function()**/
  /*member: LegacyClass2b.method4:int* Function()**/
  /*member: LegacyClass2b.method5a:int* Function(int*, int*)**/
  /*member: LegacyClass2b.method5b:int* Function(int*, [int*])**/
  /*member: LegacyClass2b.method5c:int* Function([int*, int*])**/
  /*member: LegacyClass2b.method6a:int* Function(int*, int*)**/
  /*member: LegacyClass2b.method6b:int* Function(int*, [int*])**/
  /*member: LegacyClass2b.method6c:int* Function([int*, int*])**/
  /*member: LegacyClass2b.method7a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2b.method7b:int* Function({int* a, int* b})**/
  /*member: LegacyClass2b.method8a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2b.method8b:int* Function({int* a, int* b})**/
  /*member: LegacyClass2b.method9a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2b.method9b:int* Function({int* a, int* b})**/
  /*member: LegacyClass2b.method10a:int* Function(int*, {int* b})**/
  /*member: LegacyClass2b.method10b:int* Function({int* a, int* b})**/

  /*member: LegacyClass2b.property1:int**/
  /*member: LegacyClass2b.property1=:int**/
  /*member: LegacyClass2b.property2:int**/
  /*member: LegacyClass2b.property2=:int**/
  /*member: LegacyClass2b.property3:int**/
  /*member: LegacyClass2b.property3=:int**/
  /*member: LegacyClass2b.property4:int**/
  /*member: LegacyClass2b.property4=:int**/
  /*member: LegacyClass2b.property5:int**/
  /*member: LegacyClass2b.property5=:int**/
  /*member: LegacyClass2b.property6:int**/
  /*member: LegacyClass2b.property6=:int**/
  /*member: LegacyClass2b.property7:int**/
  /*member: LegacyClass2b.property7=:int**/
  /*member: LegacyClass2b.property8:int**/
  /*member: LegacyClass2b.property8=:int**/

  /*member: LegacyClass2b.setter1=:int**/
  /*member: LegacyClass2b.setter2=:int**/
  /*member: LegacyClass2b.setter3=:int**/
  /*member: LegacyClass2b.setter4=:int**/
}

/*class: LegacyGenericClass1:GenericInterface<T*>,LegacyGenericClass1<T*>,Object*/
/*cfe|cfe:builder.member: LegacyGenericClass1.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyGenericClass1.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyGenericClass1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyGenericClass1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyGenericClass1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyGenericClass1._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyGenericClass1.hashCode:int**/
/*cfe|cfe:builder.member: LegacyGenericClass1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyGenericClass1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyGenericClass1.==:bool* Function(dynamic)**/
abstract class LegacyGenericClass1<T> implements GenericInterface<T> {
  /*member: LegacyGenericClass1.genericMethod1:S* Function<S>(T*, S*, {T* c, S* d})**/
  /*member: LegacyGenericClass1.genericMethod2:S* Function<S>(T*, S*, [T*, S*])**/
}
