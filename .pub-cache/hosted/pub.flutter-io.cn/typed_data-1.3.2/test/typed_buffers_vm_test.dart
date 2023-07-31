// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'typed_buffers_test.dart';

void main() {
  var browserUnsafe = [
    0x0ffffffffffffffff,
    0xaaaaaaaaaaaaaaaa,
    0x8000000000000001,
    0x7fffffffffffffff,
    0x5555555555555555,
  ];
  initTests(<int>[
    ...browserSafeIntSamples,
    ...browserUnsafe,
  ]);
}
