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
  int? method(int i);
}

/*class: Class2:Class2,Interface,Object*/
abstract class Class2 implements Interface {
  /*member: Class2.method:int? Function(int)*/
}
