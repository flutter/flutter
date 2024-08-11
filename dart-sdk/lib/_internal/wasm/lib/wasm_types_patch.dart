// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:_js_helper";
import "dart:_wasm";
import "dart:js_interop";

@patch
extension WasmExternRefToJSAny on WasmExternRef {
  @patch
  JSAny get toJS => JSValue.box(this) as JSAny;
}

@patch
WasmExternRef? externRefForJSAny(JSAny object) =>
    (object as JSValue).toExternRef;
