// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

/*cfe|cfe:builder.class: JSIndexable:JSIndexable<E*>,Object*/
abstract class JSIndexable<E> {}

/*cfe|cfe:builder.class: JSArray:EfficientLengthIterable<E*>,Iterable<E*>,JSArray<E*>,JSIndexable<E*>,List<E*>,Object*/
class JSArray<E> implements List<E>, JSIndexable<E> {
  /*cfe|cfe:builder.member: JSArray.==:bool* Function(dynamic)**/
  bool operator ==(other) => true;
}
