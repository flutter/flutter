// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void conditional_false() {
  false ? /*unreachable*/ 1 : 2;
}

void conditional_true() {
  true ? 1 : /*unreachable*/ 2;
}
