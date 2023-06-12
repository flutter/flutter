// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart = 2.5
import 'opt_in.dart';

/*class: Legacy:Legacy,Object*/
/*cfe|cfe:builder.member: Legacy.toString:String* Function()**/
/*cfe|cfe:builder.member: Legacy.runtimeType:Type**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Legacy.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Legacy._identityHashCode:int**/
/*cfe|cfe:builder.member: Legacy.hashCode:int**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy.==:bool* Function(dynamic)**/
abstract class Legacy {
  /*member: Legacy.mandatory:void Function(int*)**/
  void mandatory(int param);
  /*member: Legacy.optional:void Function(int*)**/
  void optional(int param);
}

/*class: Both1:Both1,Legacy,Nnbd,Object*/
/*cfe|cfe:builder.member: Both1.toString:String* Function()**/
/*cfe|cfe:builder.member: Both1.runtimeType:Type**/
/*cfe|cfe:builder.member: Both1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Both1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Both1._identityHashCode:int**/
/*cfe|cfe:builder.member: Both1.hashCode:int**/
/*cfe|cfe:builder.member: Both1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both1.==:bool* Function(dynamic)**/
class Both1 implements Legacy, Nnbd {
  /*member: Both1.mandatory:void Function(int*)**/
  void mandatory(param) {}
  /*member: Both1.optional:void Function(int*)**/
  void optional(param) {}
}

/*class: Both2:Both2,Legacy,Nnbd,Object*/
/*cfe|cfe:builder.member: Both2.toString:String* Function()**/
/*cfe|cfe:builder.member: Both2.runtimeType:Type**/
/*cfe|cfe:builder.member: Both2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Both2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Both2._identityHashCode:int**/
/*cfe|cfe:builder.member: Both2.hashCode:int**/
/*cfe|cfe:builder.member: Both2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Both2.==:bool* Function(dynamic)**/
class Both2 implements Nnbd, Legacy {
  /*member: Both2.mandatory:void Function(int*)**/
  void mandatory(param) {}
  /*member: Both2.optional:void Function(int*)**/
  void optional(param) {}
}
