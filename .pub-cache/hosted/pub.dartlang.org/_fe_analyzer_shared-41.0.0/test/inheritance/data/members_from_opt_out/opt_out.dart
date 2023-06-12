// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/
library opt_out;

/*class: LegacyClass:LegacyClass,Object*/
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
class LegacyClass {
  /*member: LegacyClass.method1:int* Function()**/
  int method1() => 0;

  /*member: LegacyClass.method2:int* Function()**/
  int method2() => 0;

  /*member: LegacyClass.method3a:int* Function(int*, int*)**/
  int method3a(int a, int b) => 0;

  /*member: LegacyClass.method3b:int* Function(int*, [int*])**/
  int method3b(int a, [int b]) => 0;

  /*member: LegacyClass.method3c:int* Function([int*, int*])**/
  int method3c([int a, int b]) => 0;

  /*member: LegacyClass.method4a:int* Function(int*, int*)**/
  int method4a(int a, int b) => 0;

  /*member: LegacyClass.method4b:int* Function(int*, [int*])**/
  int method4b(int a, [int b]) => 0;

  /*member: LegacyClass.method4c:int* Function([int*, int*])**/
  int method4c([int a, int b]) => 0;

  /*member: LegacyClass.method5a:int* Function(int*, {int* b})**/
  int method5a(int a, {int b}) => 0;

  /*member: LegacyClass.method5b:int* Function({int* a, int* b})**/
  int method5b({int a, int b}) => 0;

  /*member: LegacyClass.method6a:int* Function(int*, {int* b})**/
  int method6a(int a, {int b}) => 0;

  /*member: LegacyClass.method6b:int* Function({int* a, int* b})**/
  int method6b({int a, int b}) => 0;

  /*member: LegacyClass.getter1:int**/
  int get getter1 => 0;

  /*member: LegacyClass.getter2:int**/
  int get getter2 => 0;

  /*member: LegacyClass.setter1=:int**/
  void set setter1(int value) {}

  /*member: LegacyClass.setter2=:int**/
  void set setter2(int value) {}

  /*member: LegacyClass.field1:int**/
  /*member: LegacyClass.field1=:int**/
  int field1;

  /*member: LegacyClass.field2:int**/
  /*member: LegacyClass.field2=:int**/
  int field2;

  /*member: LegacyClass.field3:int**/
  /*member: LegacyClass.field3=:int**/
  int field3;

  /*member: LegacyClass.field4:int**/
  /*member: LegacyClass.field4=:int**/
  int field4;

  /*member: LegacyClass.field5:int**/
  /*member: LegacyClass.field5=:int**/
  var field5 = 0;

  /*member: LegacyClass.field6:int**/
  /*member: LegacyClass.field6=:int**/
  int field6 = 0;

  /*member: LegacyClass.property1:int**/
  int get property1 => 0;

  /*member: LegacyClass.property1=:int**/
  void set property1(int value) {}

  /*member: LegacyClass.property2:int**/
  int get property2 => 0;

  /*member: LegacyClass.property2=:int**/
  void set property2(int value) {}

  /*member: LegacyClass.property3:int**/
  int get property3 => 0;

  /*member: LegacyClass.property3=:int**/
  void set property3(int value) {}

  /*member: LegacyClass.property4:int**/
  int get property4 => 0;

  /*member: LegacyClass.property4=:int**/
  void set property4(int value) {}
}

/*class: GenericLegacyClass:GenericLegacyClass<T*>,Object*/
/*cfe|cfe:builder.member: GenericLegacyClass.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericLegacyClass.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericLegacyClass._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericLegacyClass._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass.hashCode:int**/
/*cfe|cfe:builder.member: GenericLegacyClass._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericLegacyClass.==:bool* Function(dynamic)**/
class GenericLegacyClass<T> {
  /*member: GenericLegacyClass.method1:T* Function()**/
  T method1() => null;
}
