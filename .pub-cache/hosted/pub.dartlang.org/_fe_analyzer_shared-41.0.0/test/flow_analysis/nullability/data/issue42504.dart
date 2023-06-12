// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Bar {}

abstract class Foo {
  dynamic get _map;

  Bar? putIfAbsent(Object key, Bar loader()) {
    assert(key != null);
    assert(loader != null);
    Bar? result = _map[key]?.result;
    if (result != null) {
      return /*nonNullable*/ result;
    }
    result = loader();
    /*nonNullable*/ result;
    try {
      result = loader();
      /*nonNullable*/ result;
    } catch (error) {
      return null;
    }

    return /*nonNullable*/ result;
  }
}

main() {}
