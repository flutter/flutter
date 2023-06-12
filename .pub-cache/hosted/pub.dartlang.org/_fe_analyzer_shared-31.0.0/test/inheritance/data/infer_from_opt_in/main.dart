// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart = 2.5
import 'opt_in.dart';

/*class: LegacyClass1:Class,LegacyClass1,Object*/
/*cfe|cfe:builder.member: LegacyClass1.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass1.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass1._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.==:bool* Function(dynamic)**/
abstract class LegacyClass1 extends Class {
  /*member: LegacyClass1.getter:int**/
  /*member: LegacyClass1.method:int* Function()**/
}

/*class: LegacyClass2:Class,LegacyClass1,LegacyClass2,Object*/
/*cfe|cfe:builder.member: LegacyClass2.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass2.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass2._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.==:bool* Function(dynamic)**/
class LegacyClass2 extends Class implements LegacyClass1 {
  /*member: LegacyClass2.method:int* Function()**/
  method() => 0;

  /*member: LegacyClass2.getter:int**/
  get getter => 0;
}

/*class: LegacyClass3:Class,LegacyClass1,LegacyClass3,Object*/
/*cfe|cfe:builder.member: LegacyClass3.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass3.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass3._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3.==:bool* Function(dynamic)**/
class LegacyClass3 extends LegacyClass1 {
  /*member: LegacyClass3.method:int* Function()**/
  method() => 0;

  /*member: LegacyClass3.getter:int**/
  get getter => 0;
}

/*class: EnvironmentMap:
 EnvironmentMap,Map<String*, String*>,
 MapBase<String*, String*>,
 MapMixin<String*, String*>,
 Object,
 UnmodifiableMapBase<String*, String*>,
 _UnmodifiableMapMixin<String*, String*>
*/
/*cfe|cfe:builder.member: EnvironmentMap.toString:String* Function()**/
/*cfe|cfe:builder.member: EnvironmentMap.runtimeType:Type**/
/*cfe|cfe:builder.member: EnvironmentMap._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EnvironmentMap._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: EnvironmentMap.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: EnvironmentMap._identityHashCode:int**/
/*cfe|cfe:builder.member: EnvironmentMap.hashCode:int**/
/*cfe|cfe:builder.member: EnvironmentMap._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EnvironmentMap._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: EnvironmentMap.==:bool* Function(dynamic)**/
class EnvironmentMap extends UnmodifiableMapBase<String, String> {
  /*member: EnvironmentMap.keys:Iterable<String*>**/
  get keys => null;
}
