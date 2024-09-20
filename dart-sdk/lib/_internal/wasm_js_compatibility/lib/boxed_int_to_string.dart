// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';
import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_string';
import 'dart:_wasm';

@patch
class _BoxedInt {
  @patch
  String toRadixString(int radix) {
    // We could also catch the `_JavaScriptError` here and convert it to
    // `RangeError`, but I'm not sure if that would be faster.
    if (radix < 2 || 36 < radix) {
      throw RangeError.range(radix, 2, 36, "radix");
    }
    return _jsBigIntToString(this, radix);
  }

  @patch
  String toString() => _jsBigIntToString(this, 10);
}

@pragma("wasm:prefer-inline")
String _jsBigIntToString(int i, int radix) => JSStringImpl(JS<WasmExternRef?>(
    'Function.prototype.call.bind(BigInt.prototype.toString)',
    WasmI64.fromInt(i),
    WasmI32.fromInt(radix)));
