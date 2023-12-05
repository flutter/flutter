// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class HMACGetSecretInput {
  external factory HMACGetSecretInput({
    required JSArrayBuffer salt1,
    JSArrayBuffer salt2,
  });
}

extension HMACGetSecretInputExtension on HMACGetSecretInput {
  external set salt1(JSArrayBuffer value);
  external JSArrayBuffer get salt1;
  external set salt2(JSArrayBuffer value);
  external JSArrayBuffer get salt2;
}

@JS()
@staticInterop
@anonymous
class HMACGetSecretOutput {
  external factory HMACGetSecretOutput({
    required JSArrayBuffer output1,
    JSArrayBuffer output2,
  });
}

extension HMACGetSecretOutputExtension on HMACGetSecretOutput {
  external set output1(JSArrayBuffer value);
  external JSArrayBuffer get output1;
  external set output2(JSArrayBuffer value);
  external JSArrayBuffer get output2;
}
