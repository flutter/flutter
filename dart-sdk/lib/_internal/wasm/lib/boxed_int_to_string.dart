// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_string';
import 'dart:_wasm';

@patch
class BoxedInt {
  @patch
  String toRadixString(int radix) {
    RangeErrorUtils.checkValueInInterval(radix, 2, 36, "radix");
    return _jsBigIntToString(this, radix);
  }

  @patch
  String toString() => _jsBigIntToString(this, 10);
}

@pragma("wasm:prefer-inline")
String _jsBigIntToString(int i, int radix) {
  final upperBits = (i >> 31);
  final result = (upperBits == -1 || upperBits == 0)
      ? JS<WasmExternRef?>(
          'Function.prototype.call.bind(Number.prototype.toString)',
          WasmI32.fromInt(i),
          WasmI32.fromInt(radix),
        )
      : JS<WasmExternRef?>(
          'Function.prototype.call.bind(BigInt.prototype.toString)',
          WasmI64.fromInt(i),
          WasmI32.fromInt(radix),
        );
  return JSStringImpl.fromRefUnchecked(result);
}
