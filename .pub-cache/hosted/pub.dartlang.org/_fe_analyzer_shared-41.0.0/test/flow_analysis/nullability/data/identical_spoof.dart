// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool identical(Object? x, Object? y) => false;

void test(int? x) {
  if (identical(x, null)) {
    x;
  } else {
    x;
  }
}
