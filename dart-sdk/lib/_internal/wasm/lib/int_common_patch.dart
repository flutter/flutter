// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

@patch
class int {
  @patch
  external const factory int.fromEnvironment(String name,
      {int defaultValue = 0});

  /// Wasm i64.div_s instruction.
  external int _div_s(int divisor);

  /// Wasm i64.le_u instruction.
  external bool _le_u(int other);

  /// Wasm i64.lt_u instruction.
  external bool _lt_u(int other);

  /// Wasm i64.shr_s instruction.
  external int _shr_s(int shift);

  /// Wasm i64.shr_u instruction.
  external int _shr_u(int shift);

  /// Wasm i64.shl instruction.
  external int _shl(int shift);
}
