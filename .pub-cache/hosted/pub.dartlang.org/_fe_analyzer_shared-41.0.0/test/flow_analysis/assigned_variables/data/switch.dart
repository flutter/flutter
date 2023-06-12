// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: switchStatement:declared={a, b, c}, assigned={a, b, c}*/
switchStatement(int a, int b, int c) {
  /*assigned={b, c}*/ switch (a = 0) {
    case 1:
      b = 0;
      break;
    default:
      c = 0;
      break;
  }
}
