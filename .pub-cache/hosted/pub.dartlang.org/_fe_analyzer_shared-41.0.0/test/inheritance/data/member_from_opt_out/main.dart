// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

/*class: Interface:Interface,Object*/
abstract class Interface {
  /*member: Interface.method:int Function(int?)*/
  int method(int? i) => i ?? 0;
}

/*class: Class:Class,Interface,LegacyClass,Object*/
/*cfe|cfe:builder.member: Class.toString:String Function()*/
/*cfe|cfe:builder.member: Class.runtimeType:Type*/
/*cfe|cfe:builder.member: Class._simpleInstanceOf:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class._instanceOf:bool Function(dynamic, dynamic, dynamic)*/
/*cfe|cfe:builder.member: Class.noSuchMethod:dynamic Function(Invocation)*/
/*cfe|cfe:builder.member: Class._identityHashCode:int*/
/*cfe|cfe:builder.member: Class.hashCode:int*/
/*cfe|cfe:builder.member: Class._simpleInstanceOfFalse:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class._simpleInstanceOfTrue:bool Function(dynamic)*/
/*cfe|cfe:builder.member: Class.==:bool* Function(dynamic)**/
abstract class Class extends LegacyClass implements Interface {
  /*member: Class.method:int Function(int?)*/
}
