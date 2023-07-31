// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.5

/*class: Map:Map<K*, V*>,Object*/
/*cfe|cfe:builder.member: Map.toString:String* Function()**/
/*cfe|cfe:builder.member: Map.runtimeType:Type**/
/*cfe|cfe:builder.member: Map._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Map._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Map.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Map._identityHashCode:int**/
/*cfe|cfe:builder.member: Map.hashCode:int**/
/*cfe|cfe:builder.member: Map._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Map._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Map.==:bool* Function(dynamic)**/
abstract class Map<K, V> {
  /*member: Map.map:Map<K2*, V2*>* Function<K2, V2>(MapEntry<K2*, V2*>* Function(K*, V*)*)**/
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) f);
}

/*class: MapEntry:MapEntry<K*, V*>,Object*/
/*cfe|cfe:builder.member: MapEntry.toString:String* Function()**/
/*cfe|cfe:builder.member: MapEntry.runtimeType:Type**/
/*cfe|cfe:builder.member: MapEntry._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapEntry._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: MapEntry.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: MapEntry._identityHashCode:int**/
/*cfe|cfe:builder.member: MapEntry.hashCode:int**/
/*cfe|cfe:builder.member: MapEntry._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapEntry._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: MapEntry.==:bool* Function(dynamic)**/
abstract class MapEntry<K, V> {}
