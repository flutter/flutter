// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  static StackTrace get current {
    // `Error` should be supported in most browsers.  A possible future
    // optimization we could do is to just save the `Error` object here, and
    // stringify the stack trace when it is actually used.
    //
    // Note: We remove the first two frames to prevent including
    // `getCurrentStackTrace` and `StackTrace.current`. On Chrome, the first
    // line is not a frame but a line with just "Error", which we also remove.
    return _StringStackTrace(JSStringImpl(JS<WasmExternRef?>(r"""() => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        }""")));
  }
}
