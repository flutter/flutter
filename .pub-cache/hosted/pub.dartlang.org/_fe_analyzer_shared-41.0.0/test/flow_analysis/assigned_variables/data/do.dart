// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: doStatement:declared={a, b}, assigned={a, b}*/
doStatement(int a, int b) {
  /*assigned={a, b}*/ do {
    a = 0;
  } while ((b = 0) != 0);
}
