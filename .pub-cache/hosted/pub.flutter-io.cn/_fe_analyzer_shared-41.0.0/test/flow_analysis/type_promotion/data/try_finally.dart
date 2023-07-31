// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void outerIsType_assigned_body(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
      x = 42;
    } finally {
      x;
    }
    x;
  }
}

void outerIsType_assigned_finally(Object x) {
  if (x is String) {
    try {
      /*String*/ x;
    } finally {
      /*String*/ x;
      x = 42;
    }
    x;
  }
}
