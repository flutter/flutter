// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.5

import 'opt_in.dart';

/*class: MapImpl:Map<K*, V*>,MapImpl<K*, V*>,Object*/
/*cfe|cfe:builder.member: MapImpl.toString:String* Function()**/
/*cfe|cfe:builder.member: MapImpl.runtimeType:Type**/
/*cfe|cfe:builder.member: MapImpl._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapImpl._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: MapImpl.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: MapImpl._identityHashCode:int**/
/*cfe|cfe:builder.member: MapImpl.hashCode:int**/
/*cfe|cfe:builder.member: MapImpl._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapImpl._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapImpl.==:bool* Function(dynamic)**/
abstract class MapImpl<K, V> implements Map<K, V> {
  /*member: MapImpl.map:Map<K2*, V2*>* Function<K2, V2>(MapEntry<K2*, V2*>* Function(K*, V*)*)**/
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) f);
}

/*class: FixedMapImpl:FixedMapImpl,Map<int*, String*>,Object*/
/*cfe|cfe:builder.member: FixedMapImpl.toString:String* Function()**/
/*cfe|cfe:builder.member: FixedMapImpl.runtimeType:Type**/
/*cfe|cfe:builder.member: FixedMapImpl._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: FixedMapImpl._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: FixedMapImpl.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: FixedMapImpl._identityHashCode:int**/
/*cfe|cfe:builder.member: FixedMapImpl.hashCode:int**/
/*cfe|cfe:builder.member: FixedMapImpl._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: FixedMapImpl._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: FixedMapImpl.==:bool* Function(dynamic)**/
abstract class FixedMapImpl implements Map<int, String> {
  /*member: FixedMapImpl.map:Map<K2*, V2*>* Function<K2, V2>(MapEntry<K2*, V2*>* Function(int*, String*)*)**/
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(int key, String value) f);
}
