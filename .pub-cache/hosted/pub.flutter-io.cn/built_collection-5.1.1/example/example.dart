// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';

void main() {
  // `built_collection` provides immutable equivalents of Dart SDK `List`,
  // `Set` and `Map`: `BuiltList`, `BuiltSet` and `BuiltMap`.

  // The easiest way to create them is from collection literals using `build`:
  var builtList = [1, 2, 3].build();
  var builtSet = {1, 2, 3}.build();
  var builtMap = {1: 'one', 2: 'two', 3: 'three'}.build();

  // `BuiltList` and `BuiltSet` can also be constructed from any `Iterable`.
  // The unnamed constructors act like the SDK `from` constructors, meaning
  // the elements are type checked at runtime.
  builtList = BuiltList([1, 2, 3]);
  builtSet = BuiltSet([1, 2, 3]);

  // Alternatively, the `of` constructors match the type to the `Iterable` you
  // pass, and so do not need to check the type of elements.
  builtList = BuiltList.of([1, 2, 3]);
  builtSet = BuiltSet.of([1, 2, 3]);

  // `BuiltMap` can be constructed from a `Map` or a `BuiltMap`.
  builtMap = BuiltMap({1: 'one', 2: 'two', 3: 'three'});

  // Immutable collections can't be updated, but you can create new instances
  // based on existing ones. The most convenient way to do that is the
  // `rebuild` methods, which give you access to each collection type's
  // corresponding builder type.

  // For example, to add some elements then sort:
  builtList = builtList.rebuild((b) => b
    ..addAll([7, 6, 5])
    ..sort());

  // Generally, built collections match the SDK collections, except that the
  // API has been split in two: read only methods go on the `Built` collection
  // types, and mutating methods go on the corresponding `Builder` types.

  // If you need to keep a mutable version of the collection around for a
  // while, for example to pass it to other methods, you can use `toBuilder`.
  // Then, later, the collection is made immutable again by calling `build`.
  var listBuilder = builtList.toBuilder();
  listBuilder.addAll([10, 9, 8]);
  // More changes could go here, including passing the builder to other
  // methods.
  builtList = listBuilder.build();

  // Finally, `built_collection` also provides immutable versions of
  // `ListMultimap` and `SetMultimap` from `package:quiver`. For information
  // on these, and full details on all the APIs, please see the package
  // [dartdoc](https://pub.dev/documentation/built_collection/latest).

  // Use the values so the analyzer is happy.
  print(builtList);
  print(builtSet);
  print(builtMap);
}
