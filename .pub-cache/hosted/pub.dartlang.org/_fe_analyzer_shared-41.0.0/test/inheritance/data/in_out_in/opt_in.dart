// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: Class:Class,Object*/
class Class {
  /*member: Class.method:int Function(int?)*/
  int method(int? i) => i ?? 0;
}

/*class: Interface:Interface,Object*/
abstract class Interface {
  /*member: Interface.method:int? Function(int)*/
  int? method(int i) => i;
}

/*class: GenericInterface:GenericInterface<T>,Object*/
abstract class GenericInterface<T> {
  /*member: GenericInterface.method:T Function(T)*/
  T method(T t);
}

/*class: GenericClass1:GenericClass1,GenericInterface<int>,Object*/
abstract class GenericClass1 implements GenericInterface<int> {
  /*member: GenericClass1.method:int Function(int)*/
}

/*class: GenericClass2:GenericClass2,GenericInterface<int?>,Object*/
abstract class GenericClass2 implements GenericInterface<int?> {
  /*member: GenericClass2.method:int? Function(int?)*/
}
