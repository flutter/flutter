// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// `dart:convert` UTF-8 decoding functions when the input is a JS typed array.
library dart._js_string_convert;

import 'dart:_js_helper' as js;
import 'dart:_js_types';
import 'dart:_string';
import 'dart:_wasm';
import 'dart:js_interop';

/// Implements `_Utf8Decoder.convertSingle` hook for JS array inputs. Does not
/// do bounds checking.
JSStringImpl? decodeUtf8JS(
    JSUint8ArrayImpl codeUnits, int start, int end, bool allowMalformed) {
  final length = end - start;
  if (length >= _shortInputThreshold) {
    final JSAny? decoder = allowMalformed ? _decoderNonFatal : _decoder;
    if (decoder != null) {
      final arrayRef = codeUnits.toJSArrayExternRef(start, length);
      final textDecoderResult =
          _useTextDecoder(externRefForJSAny(decoder), arrayRef);
      if (textDecoderResult != null) {
        return textDecoderResult;
      }
    }
  }
  return null;
}

// Always fall back to the Dart implementation for strings shorter than this
// threshold, as there is a large, constant overhead for using `TextDecoder`.
// TODO(omersa): This is copied from dart2js runtime, make sure the value is
// right for dart2wasm.
const int _shortInputThreshold = 15;

JSStringImpl? _useTextDecoder(
    WasmExternRef? decoder, WasmExternRef? codeUnits) {
  // If the input is malformed, catch the exception and return `null` to fall
  // back on unintercepted decoder. The fallback will either succeed in
  // decoding, or report the problem better than `TextDecoder`.
  try {
    return JSStringImpl(js.JS<WasmExternRef?>(
        '(decoder, codeUnits) => decoder.decode(codeUnits)',
        decoder,
        codeUnits));
  } catch (e) {}
  return null;
}

// TextDecoder is not defined on some browsers and on the stand-alone d8 and
// jsshell engines. Use a lazy initializer to do feature detection once.
//
// Globals need to return boxed Dart values, so these return `JSAny?` instead
// of `WasmExternRef?`.
final JSAny? _decoder = () {
  try {
    return js
        .JS<WasmExternRef>('() => new TextDecoder("utf-8", {fatal: true})')
        .toJS;
  } catch (e) {}
  return null;
}();

final JSAny? _decoderNonFatal = () {
  try {
    return js
        .JS<WasmExternRef>('() => new TextDecoder("utf-8", {fatal: false})')
        .toJS;
  } catch (e) {}
  return null;
}();
