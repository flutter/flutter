// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:_wasm';
import 'dart:js_interop';

@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
JSAny dartToJsWrapper(Object object) =>
    WasmAnyRef.fromObject(object).externalize().toJS;

@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
Object jsWrapperToDart(JSAny jsWrapper) =>
    externRefForJSAny(jsWrapper).internalize()!.toObject();
