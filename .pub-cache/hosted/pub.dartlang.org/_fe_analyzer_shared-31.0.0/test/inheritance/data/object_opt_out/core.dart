// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'dart:async';
import
    /*analyzer.error: CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY*/
    'dart:_internal';

export 'dart:async' show Future;

bool identical(a, b) => false;

/*class: Object:Object*/
class Object {
  const Object();

  bool operator ==(other) => true;

  noSuchMethod(Invocation invocation) => null;

  String toString() => '';
}

/*class: Enum:Enum,Object*/
abstract class Enum {}

/*class: Null:Null,Object*/
class Null {
  factory Null._uninstantiable() {
    throw 'class Null cannot be instantiated';
  }
}

/*class: bool:Object,bool*/
class bool {}

/*class: num:Object,num*/
class num {}

/*class: int:Object,int,num*/
class int extends num {}

/*class: double:Object,double,num*/
class double extends num {}

/*class: String:Object,String*/
class String {}

/*class: Iterable:Iterable<E*>,Object*/
abstract class Iterable<E> {}

/*class: List:EfficientLengthIterable<E*>,Iterable<E*>,List<E*>,Object*/
abstract class List<E> implements EfficientLengthIterable<E> {
  /*cfe|cfe:builder.member: List.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: Set:Iterable<E*>,Object,Set<E*>*/
class Set<E> implements Iterable<E> {}

/*class: Map:Map<K*, V*>,Object*/
class Map<K, V> {}

/*class: Stream:Object,Stream<E*>*/
class Stream<E> {}

/*class: Function:Function,Object*/
class Function {}

/*class: Symbol:Object,Symbol*/
class Symbol {}

/*class: Type:Object,Type*/
class Type {}

/*class: Invocation:Invocation,Object*/
class Invocation {}
