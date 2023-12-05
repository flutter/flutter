// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'streams.dart';

typedef CompressionFormat = String;

@JS('CompressionStream')
@staticInterop
class CompressionStream {
  external factory CompressionStream(CompressionFormat format);
}

extension CompressionStreamExtension on CompressionStream {
  external ReadableStream get readable;
  external WritableStream get writable;
}

@JS('DecompressionStream')
@staticInterop
class DecompressionStream {
  external factory DecompressionStream(CompressionFormat format);
}

extension DecompressionStreamExtension on DecompressionStream {
  external ReadableStream get readable;
  external WritableStream get writable;
}
