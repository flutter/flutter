// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:typed_data';

@patch
extension AllocatorAlloc on Allocator {
  // TODO(http://dartbug.com/39964): Add `alignmentOf<T>()` call.
  @patch
  Pointer<T> call<T extends SizedNativeType>([int count = 1]) {
    // This case should have been rewritten in pre-processing.
    throw UnimplementedError("Pointer<$T>");
  }
}
