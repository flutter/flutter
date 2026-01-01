// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@patch
class Symbol {
  @patch
  @pragma("wasm:entry-point")
  const Symbol(String name) : this._name = name;

  @patch
  String toString() => 'Symbol("${computeUnmangledName(this)}")';

  @patch
  static String computeUnmangledName(Symbol symbol) {
    // A symbol is mangled iff it has the form `#_<id>` and in no other
    // circumstance. The following *will not* be considered private and not
    // cause any mangling:
    //
    //   `new Symbol('_a')`
    //   `const Symbol('_a')`
    //   `#a._b`
    //   `#_a.b`
    final mangledName = Symbol.getName(symbol);

    final index = mangledName.lastIndexOf('@');
    if (index == -1) return mangledName;
    return mangledName.substring(0, index);
  }

  @patch
  int get hashCode => _name.hashCode;
}
