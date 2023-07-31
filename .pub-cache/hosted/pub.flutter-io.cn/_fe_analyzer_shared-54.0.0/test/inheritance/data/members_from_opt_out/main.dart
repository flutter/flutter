// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
library main;

import 'opt_out.dart';

/*class: Interface:Interface,Object*/
abstract class Interface {
  /*member: Interface.method1:int Function()*/
  int method1();

  /*member: Interface.method2:int? Function()*/
  int? method2();

  /*member: Interface.method3a:int Function(int, int)*/
  int method3a(int a, int b);

  /*member: Interface.method3b:int Function(int, [int])*/
  int method3b(int a, [int b]);

  /*member: Interface.method3c:int Function([int, int])*/
  int method3c([int a, int b]);

  /*member: Interface.method4a:int? Function(int?, int?)*/
  int? method4a(int? a, int? b);

  /*member: Interface.method4b:int? Function(int?, [int?])*/
  int? method4b(int? a, [int? b]);

  /*member: Interface.method4c:int? Function([int?, int?])*/
  int? method4c([int? a, int? b]);

  /*member: Interface.method5a:int Function(int, {int b})*/
  int method5a(int a, {int b = 0});

  /*member: Interface.method5b:int Function({int a, int b})*/
  int method5b({int a = 0, int b = 0});

  /*member: Interface.method6a:int? Function(int?, {int? b})*/
  int? method6a(int? a, {int? b});

  /*member: Interface.method6b:int? Function({int? a, int? b})*/
  int? method6b({int? a, int? b});

  /*member: Interface.getter1:int*/
  int get getter1;

  /*member: Interface.getter2:int?*/
  int? get getter2;

  /*member: Interface.setter1=:int*/
  void set setter1(int value);

  /*member: Interface.setter2=:int?*/
  void set setter2(int? value);

  /*member: Interface.field1:int*/
  /*member: Interface.field1=:int*/
  int field1 = 0;

  /*member: Interface.field2:int?*/
  /*member: Interface.field2=:int?*/
  int? field2;

  /*member: Interface.field3:int*/
  int get field3;

  /*member: Interface.field3=:int*/
  void set field3(int value);

  /*member: Interface.field4:int?*/
  int? get field4;

  /*member: Interface.field4=:int?*/
  void set field4(int? value);

  /*member: Interface.field5:int*/
  /*member: Interface.field5=:int*/
  var field5 = 0;

  /*member: Interface.field6:int?*/
  /*member: Interface.field6=:int?*/
  var field6 = constant;

  /*member: Interface.property1:int*/
  int get property1;

  /*member: Interface.property1=:int*/
  void set property1(int value);

  /*member: Interface.property2:int?*/
  int? get property2;

  /*member: Interface.property2=:int?*/
  void set property2(int? value);

  /*member: Interface.property3:int*/
  /*member: Interface.property3=:int*/
  int property3 = 0;

  /*member: Interface.property4:int?*/
  /*member: Interface.property4=:int?*/
  int? property4;
}

/*class: Class1:Class1,LegacyClass,Object*/
/*member: Class1.field1=:int**/
/*member: Class1.field2=:int**/
/*member: Class1.field3=:int**/
/*member: Class1.field4=:int**/
/*member: Class1.field5=:int**/
/*member: Class1.field6=:int**/
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
class Class1 extends LegacyClass {
  /*member: Class1.method1:int* Function()**/
  /*member: Class1.method2:int* Function()**/
  /*member: Class1.method3a:int* Function(int*, int*)**/
  /*member: Class1.method3b:int* Function(int*, [int*])**/
  /*member: Class1.method3c:int* Function([int*, int*])**/
  /*member: Class1.method4a:int* Function(int*, int*)**/
  /*member: Class1.method4b:int* Function(int*, [int*])**/
  /*member: Class1.method4c:int* Function([int*, int*])**/
  /*member: Class1.method5a:int* Function(int*, {int* b})**/
  /*member: Class1.method5b:int* Function({int* a, int* b})**/
  /*member: Class1.method6a:int* Function(int*, {int* b})**/
  /*member: Class1.method6b:int* Function({int* a, int* b})**/
  /*member: Class1.getter1:int**/
  /*member: Class1.getter2:int**/
  /*member: Class1.setter1=:int**/
  /*member: Class1.setter2=:int**/
  /*member: Class1.field1:int**/
  /*member: Class1.field2:int**/
  /*member: Class1.field3:int**/
  /*member: Class1.field4:int**/
  /*member: Class1.field5:int**/
  /*member: Class1.field6:int**/
  /*member: Class1.property1:int**/
  /*member: Class1.property1=:int**/
  /*member: Class1.property2:int**/
  /*member: Class1.property2=:int**/
  /*member: Class1.property3:int**/
  /*member: Class1.property3=:int**/
  /*member: Class1.property4:int**/
  /*member: Class1.property4=:int**/
}

/*class: Class2a:Class2a,Interface,LegacyClass,Object*/
/*cfe|cfe:builder.member: Class2a.toString:String Function()*/
/*cfe|cfe:builder.member: Class2a.runtimeType:Type*/
/*cfe|cfe:builder.member: Class2a._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2a._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: Class2a.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: Class2a._identityHashCode:int*/
/*cfe|cfe:builder.member: Class2a.hashCode:int*/
/*cfe|cfe:builder.member: Class2a._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2a._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2a.==:bool* Function(dynamic)**/
class Class2a extends LegacyClass implements Interface {
  /*member: Class2a.method1:int Function()*/

  /*member: Class2a.method2:int? Function()*/

  /*member: Class2a.method3a:int Function(int, int)*/

  /*member: Class2a.method3b:int Function(int, [int])*/

  /*member: Class2a.method3c:int Function([int, int])*/

  /*member: Class2a.method4a:int? Function(int?, int?)*/

  /*member: Class2a.method4b:int? Function(int?, [int?])*/

  /*member: Class2a.method4c:int? Function([int?, int?])*/

  /*member: Class2a.method5a:int Function(int, {int b})*/

  /*member: Class2a.method5b:int Function({int a, int b})*/

  /*member: Class2a.method6a:int? Function(int?, {int? b})*/

  /*member: Class2a.method6b:int? Function({int? a, int? b})*/

  /*member: Class2a.getter1:int*/
  /*member: Class2a.getter2:int?*/

  /*member: Class2a.setter1=:int*/
  /*member: Class2a.setter2=:int?*/

  /*member: Class2a.field1:int*/
  /*member: Class2a.field1=:int*/

  /*member: Class2a.field2:int?*/
  /*member: Class2a.field2=:int?*/

  /*member: Class2a.field3:int*/
  /*member: Class2a.field3=:int*/

  /*member: Class2a.field4:int?*/
  /*member: Class2a.field4=:int?*/

  /*member: Class2a.field5:int*/
  /*member: Class2a.field5=:int*/

  /*member: Class2a.field6:int?*/
  /*member: Class2a.field6=:int?*/

  /*member: Class2a.property1:int*/
  /*member: Class2a.property1=:int*/

  /*member: Class2a.property2:int?*/
  /*member: Class2a.property2=:int?*/

  /*member: Class2a.property3:int*/
  /*member: Class2a.property3=:int*/

  /*member: Class2a.property4:int?*/
  /*member: Class2a.property4=:int?*/
}

/*class: Class2b:Class2b,Interface,LegacyClass,Object*/
/*cfe|cfe:builder.member: Class2b.toString:String Function()*/
/*cfe|cfe:builder.member: Class2b.runtimeType:Type*/
/*cfe|cfe:builder.member: Class2b._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2b._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: Class2b.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: Class2b._identityHashCode:int*/
/*cfe|cfe:builder.member: Class2b.hashCode:int*/
/*cfe|cfe:builder.member: Class2b._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2b._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class2b.==:bool* Function(dynamic)**/
class Class2b extends LegacyClass implements Interface {
  /*member: Class2b.method1:int Function()*/
  int method1() => 0;

  /*member: Class2b.method2:int? Function()*/
  int? method2() => 0;

  /*member: Class2b.method3a:int Function(int, int)*/
  int method3a(int a, int b) => 0;

  /*member: Class2b.method3b:int Function(int, [int])*/
  int method3b(int a, [int b = 0]) => 0;

  /*member: Class2b.method3c:int Function([int, int])*/
  int method3c([int a = 0, int b = 0]) => 0;

  /*member: Class2b.method4a:int? Function(int?, int?)*/
  int? method4a(int? a, int? b) => 0;

  /*member: Class2b.method4b:int? Function(int?, [int?])*/
  int? method4b(int? a, [int? b]) => 0;

  /*member: Class2b.method4c:int? Function([int?, int?])*/
  int? method4c([int? a, int? b]) => 0;

  /*member: Class2b.method5a:int Function(int, {int b})*/
  int method5a(int a, {int b = 0}) => 0;

  /*member: Class2b.method5b:int Function({int a, int b})*/
  int method5b({int a = 0, int b = 0}) => 0;

  /*member: Class2b.method6a:int? Function(int?, {int? b})*/
  int? method6a(int? a, {int? b}) => 0;

  /*member: Class2b.method6b:int? Function({int? a, int? b})*/
  int? method6b({int? a, int? b}) => 0;

  /*member: Class2b.getter1:int*/
  int get getter1 => 0;

  /*member: Class2b.getter2:int?*/
  int? get getter2 => 0;

  /*member: Class2b.setter1=:int*/
  void set setter1(int value) {}

  /*member: Class2b.setter2=:int?*/
  void set setter2(int? value) {}

  /*member: Class2b.field1:int*/
  /*member: Class2b.field1=:int*/
  int field1 = 0;

  /*member: Class2b.field2:int?*/
  /*member: Class2b.field2=:int?*/
  int? field2;

  /*member: Class2b.field3:int*/
  int get field3 => 0;

  /*member: Class2b.field3=:int*/
  void set field3(int value) {}

  /*member: Class2b.field4:int?*/
  int? get field4 => 0;

  /*member: Class2b.field5:int*/
  /*member: Class2b.field5=:int*/
  int field5 = 0;

  /*member: Class2b.field6=:int?*/
  /*member: Class2b.field6:int?*/
  int? field6;

  /*member: Class2b.field4=:int?*/
  void set field4(int? value) {}

  /*member: Class2b.property1:int*/
  int get property1 => 0;

  /*member: Class2b.property1=:int*/
  void set property1(int value) {}

  /*member: Class2b.property2:int?*/
  int? get property2 => 0;

  /*member: Class2b.property2=:int?*/
  void set property2(int? value) {}

  /*member: Class2b.property3:int*/
  /*member: Class2b.property3=:int*/
  int property3 = 0;

  /*member: Class2b.property4=:int?*/
  /*member: Class2b.property4:int?*/
  int? property4;
}

/*class: Class3a:Class3a,GenericLegacyClass<int>,Object*/
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
class Class3a extends GenericLegacyClass<int> {
  /*member: Class3a.method1:int* Function()**/
}

/*class: Class3b:Class3b,GenericLegacyClass<int?>,Object*/
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
class Class3b extends GenericLegacyClass<int?> {
  /*member: Class3b.method1:int? Function()**/
}

/*class: Class3c:Class3c<S>,GenericLegacyClass<S>,Object*/
/*cfe|cfe:builder.member: Class3c.toString:String* Function()**/
/*cfe|cfe:builder.member: Class3c.runtimeType:Type**/
/*cfe|cfe:builder.member: Class3c._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3c._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Class3c.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Class3c._identityHashCode:int**/
/*cfe|cfe:builder.member: Class3c.hashCode:int**/
/*cfe|cfe:builder.member: Class3c._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3c._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Class3c.==:bool* Function(dynamic)**/
class Class3c<S> extends GenericLegacyClass<S> {
  /*member: Class3c.method1:S* Function()**/
}

const int? constant = 0;
