// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

// TODO(49531): This file is nearly identical to the VM's
// symbol_patch.dart, with the exception of the added pragma on `const Symbol`.
// Unfortunately, adding this pragma to the VM's symbol_patch causes a
// deadlock. When this bug is fixed we can share a patch file with the VM.

@patch
class Symbol {
  // TODO(http://dartbug.com/46716): Recognize Symbol in the VM.
  @patch
  @pragma("wasm:entry-point")
  const Symbol(String name) : this._name = name;

  @patch
  String toString() => 'Symbol("${computeUnmangledName(this)}")';

  @patch
  static String computeUnmangledName(Symbol symbol) {
    String string = Symbol.getName(symbol);

    // get:foo -> foo
    // set:foo -> foo=
    // get:_foo@xxx -> _foo
    // set:_foo@xxx -> _foo=
    // Class._constructor@xxx -> Class._constructor
    // _Class@xxx._constructor@xxx -> _Class._constructor
    // lib._S@xxx with lib._M1@xxx, lib._M2@xxx -> lib._S with lib._M1, lib._M2
    StringBuffer result = new StringBuffer();
    bool add_setter_suffix = false;
    var pos = 0;
    if (string.length >= 4 && string[3] == ':') {
      // Drop 'get:' or 'set:' prefix.
      pos = 4;
      if (string[0] == 's') {
        add_setter_suffix = true;
      }
    }
    // Skip everything between AT and PERIOD, SPACE, COMMA or END
    bool skip = false;
    for (; pos < string.length; pos++) {
      var char = string[pos];
      if (char == '@') {
        skip = true;
      } else if (char == '.' || char == ' ' || char == ',') {
        skip = false;
      }
      if (!skip) {
        result.write(char);
      }
    }
    if (add_setter_suffix) {
      result.write('=');
    }
    return result.toString();
  }

  // Must be kept in sync with Symbol::CanonicalizeHash in object.cc.
  @patch
  int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }
}
