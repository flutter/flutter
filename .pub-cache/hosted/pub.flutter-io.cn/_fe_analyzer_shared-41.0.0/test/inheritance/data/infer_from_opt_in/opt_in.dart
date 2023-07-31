// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: Class:Class,Object*/
class Class {
  /*member: Class.method:int Function()*/
  int method() => 0;

  /*member: Class.getter:int*/
  int get getter => 0;
}

/*class: Map:Map<K, V>,Object*/
abstract class Map<K, V> {
  /*member: Map.keys:Iterable<K>*/
  Iterable<K> get keys;
}

/*class: MapMixin:Map<K, V>,MapMixin<K, V>,Object*/
abstract class MapMixin<K, V> implements Map<K, V> {
  /*member: MapMixin.keys:Iterable<K>*/
  Iterable<K> get keys;
}

/*class: MapBase:Map<K, V>,MapBase<K, V>,MapMixin<K, V>,Object*/
abstract class MapBase<K, V> extends MapMixin<K, V> {
  /*member: MapBase.keys:Iterable<K>*/
}

/*class: _UnmodifiableMapMixin:Map<K, V>,Object,_UnmodifiableMapMixin<K, V>*/
abstract class _UnmodifiableMapMixin<K, V> implements Map<K, V> {
  /*member: _UnmodifiableMapMixin.keys:Iterable<K>*/
}

/*cfe|cfe:builder.class: UnmodifiableMapBase:Map<K, V>,MapBase<K, V>,MapMixin<K, V>,Object,UnmodifiableMapBase<K, V>,_UnmodifiableMapMixin<K, V>*/
/*cfe|cfe:builder.member: UnmodifiableMapBase.keys:Iterable<K>*/
// TODO(johnniwinther,paulberry): Support named mixin declarations in id-tests.
abstract class UnmodifiableMapBase<K, V> = MapBase<K, V>
    with _UnmodifiableMapMixin<K, V>;
