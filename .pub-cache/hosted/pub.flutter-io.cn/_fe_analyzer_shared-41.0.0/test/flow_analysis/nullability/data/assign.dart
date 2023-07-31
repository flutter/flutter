// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void toNonNull(int? x) {
  if (x != null) return;
  x;
  x = 0;
  /*nonNullable*/ x;
}

void toNull(int? x) {
  if (x == null) return;
  /*nonNullable*/ x;
  x = null;
  x;
}

void toUnknown_fromNotNull(int? a, int? b) {
  if (a == null) return;
  /*nonNullable*/ a;
  a = b;
  a;
}

void toUnknown_fromNull(int? a, int? b) {
  if (a != null) return;
  a;
  a = b;
  a;
}
