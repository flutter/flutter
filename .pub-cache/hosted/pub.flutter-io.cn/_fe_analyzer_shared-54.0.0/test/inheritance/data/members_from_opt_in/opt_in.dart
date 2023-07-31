// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: Interface:Interface,Object*/
abstract class Interface {
  /*member: Interface.method1:int? Function()*/
  int? method1();

  /*member: Interface.method2:int Function()*/
  int method2();

  /*member: Interface.method3:int Function()*/
  int method3();

  /*member: Interface.method4:int? Function()*/
  int? method4();

  /*member: Interface.method5a:int Function(int, int?)*/
  int method5a(int a, int? b);

  /*member: Interface.method5b:int Function(int, [int?])*/
  int method5b(int a, [int? b]);

  /*member: Interface.method5c:int Function([int, int?])*/
  int method5c([int a, int? b]);

  /*member: Interface.method6a:int? Function(int?, int)*/
  int? method6a(int? a, int b);

  /*member: Interface.method6b:int? Function(int?, [int])*/
  int? method6b(int? a, [int b = 0]);

  /*member: Interface.method6c:int? Function([int?, int])*/
  int? method6c([int? a, int b = 0]);

  /*member: Interface.method7a:int Function(int, {int? b})*/
  int method7a(int a, {int? b});

  /*member: Interface.method7b:int Function({int a, int? b})*/
  int method7b({int a = 0, int? b});

  /*member: Interface.method8a:int? Function(int?, {int b})*/
  int? method8a(int? a, {int b = 0});

  /*member: Interface.method8b:int? Function({int? a, int b})*/
  int? method8b({int? a, int b = 0});

  /*member: Interface.method9a:int Function(int, {required int? b})*/
  int method9a(int a, {required int? b});

  /*member: Interface.method9b:int Function({required int a, required int? b})*/
  int method9b({required int a, required int? b});

  /*member: Interface.method10a:int? Function(int?, {required int b})*/
  int? method10a(int? a, {required int b});

  /*member: Interface.method10b:int? Function({required int? a, required int b})*/
  int? method10b({required int? a, required int b});

  /*member: Interface.getter1:int?*/
  int? get getter1;

  /*member: Interface.getter2:int*/
  int get getter2;

  /*member: Interface.getter3:int*/
  int get getter3;

  /*member: Interface.getter4:int?*/
  int? get getter4;

  /*member: Interface.setter1=:int?*/
  void set setter1(int? value);

  /*member: Interface.setter2=:int*/
  void set setter2(int value);

  /*member: Interface.setter3=:int*/
  void set setter3(int value);

  /*member: Interface.setter4=:int?*/
  void set setter4(int? value);

  /*member: Interface.field1:int?*/
  /*member: Interface.field1=:int?*/
  int? field1;

  /*member: Interface.field2:int*/
  /*member: Interface.field2=:int*/
  int field2 = 0;

  /*member: Interface.field3:int*/
  /*member: Interface.field3=:int*/
  int field3 = 0;

  /*member: Interface.field4=:int?*/
  /*member: Interface.field4:int?*/
  int? field4;

  /*member: Interface.property1:int?*/
  int? get property1;

  /*member: Interface.property1=:int?*/
  void set property1(int? value);

  /*member: Interface.property2:int*/
  int get property2;

  /*member: Interface.property2=:int*/
  void set property2(int value);

  /*member: Interface.property3:int*/
  int get property3;

  /*member: Interface.property3=:int*/
  void set property3(int value);

  /*member: Interface.property4:int?*/
  int? get property4;

  /*member: Interface.property4=:int?*/
  void set property4(int? value);

  /*member: Interface.property5:int?*/
  int? get property5;

  /*member: Interface.property5=:int?*/
  void set property5(int? value);

  /*member: Interface.property6:int*/
  int get property6;

  /*member: Interface.property6=:int*/
  void set property6(int value);

  /*member: Interface.property7:int*/
  int get property7;

  /*member: Interface.property7=:int*/
  void set property7(int value);

  /*member: Interface.property8:int?*/
  int? get property8;

  /*member: Interface.property8=:int?*/
  void set property8(int? value);
}

/*class: Class:Class,Object*/
class Class {
  /*member: Class.method1:int Function()*/
  int method1() => 0;

  /*member: Class.method2:int? Function()*/
  int? method2() => 0;

  /*member: Class.method5a:int Function(int, int?)*/
  int method5a(int a, int? b) => 0;

  /*member: Class.method5b:int Function(int, [int?])*/
  int method5b(int a, [int? b]) => 0;

  /*member: Class.method5c:int Function([int, int?])*/
  int method5c([int a = 0, int? b]) => 0;

  /*member: Class.method7a:int Function(int, {int? b})*/
  int method7a(int a, {int? b}) => 0;

  /*member: Class.method7b:int Function({int a, int? b})*/
  int method7b({int a = 0, int? b}) => 0;

  /*member: Class.method9a:int Function(int, {required int? b})*/
  int method9a(int a, {required int? b}) => 0;

  /*member: Class.method9b:int Function({required int a, required int? b})*/
  int method9b({required int a, required int? b}) => 0;

  /*member: Class.getter1:int*/
  int get getter1 => 0;

  /*member: Class.getter2:int?*/
  int? get getter2 => 0;

  /*member: Class.setter1=:int*/
  void set setter1(int value) {}

  /*member: Class.setter2=:int?*/
  void set setter2(int? value) {}

  /*member: Class.field1:int*/
  /*member: Class.field1=:int*/
  int field1 = 0;

  /*member: Class.field2:int?*/
  /*member: Class.field2=:int?*/
  int? field2;

  /*member: Class.field5:int*/
  /*member: Class.field5=:int*/
  var field5 = 0;

  /*member: Class.field6a=:int*/
  /*member: Class.field6a:int*/
  var field6a = 0;

  /*member: Class.field6b:int?*/
  /*member: Class.field6b=:int?*/
  var field6b = constant;

  /*member: Class.property1:int*/
  int get property1 => 0;

  /*member: Class.property1=:int*/
  void set property1(int value) {}

  /*member: Class.property2:int?*/
  int? get property2 => 0;

  /*member: Class.property2=:int?*/
  void set property2(int? value) {}

  /*member: Class.property5:int*/
  /*member: Class.property5=:int*/
  int property5 = 0;

  /*member: Class.property6:int?*/
  /*member: Class.property6=:int?*/
  int? property6;
}

const int? constant = 0;

/*class: GenericInterface:GenericInterface<T>,Object*/
abstract class GenericInterface<T> {
  /*member: GenericInterface.genericMethod1:S Function<S>(T, S, {T c, S d})*/
  S genericMethod1<S>(T a, S b, {T c, S d});

  /*member: GenericInterface.genericMethod2:S Function<S>(T, S, [T, S])*/
  S genericMethod2<S>(T a, S b, [T c, S d]);
}
