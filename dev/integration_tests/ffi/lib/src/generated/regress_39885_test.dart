// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import "package:ffi/ffi.dart" show allocate, free;

main() {
  final data = allocate<Uint8>(count: 3);
  for (int i = 0; i < 3; ++i) {
    data.elementAt(i).value = 1;
  }
  free(data);
}
