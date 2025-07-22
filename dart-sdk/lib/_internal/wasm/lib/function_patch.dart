// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class Function {
  @patch
  @pragma("wasm:intrinsic")
  external static apply(
    Function function,
    List<dynamic>? positionalArguments, [
    Map<Symbol, dynamic>? namedArguments,
  ]);
}
