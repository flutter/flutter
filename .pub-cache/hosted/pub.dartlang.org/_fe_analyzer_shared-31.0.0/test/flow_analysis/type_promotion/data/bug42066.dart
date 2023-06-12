// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f() {
  num par2;
  par2 = 0;
  if (par2 is! int) return;
  try {} catch (exception) {
    throw 'x';
    () {
      par2 = 1;
    };
  } finally {}
}
