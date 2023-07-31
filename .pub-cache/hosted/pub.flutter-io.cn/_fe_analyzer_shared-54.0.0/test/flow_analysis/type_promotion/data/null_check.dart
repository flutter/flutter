// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

doesNotPromoteNonNullableType(int x) {
  if (x != null) {
    x;
  } else {
    x;
  }
}

promotesNullableType(int? x) {
  if (x != null) {
    /*int*/ x;
  } else {
    x;
  }
}

doesNotPromoteNullType(Null x) {
  if (x != null) {
    x;
  } else {
    x;
  }
}
