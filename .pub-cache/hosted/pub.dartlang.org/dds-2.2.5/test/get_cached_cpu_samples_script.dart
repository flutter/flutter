// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

fib(int n) {
  if (n <= 1) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

void main() {
  final tag = UserTag('Testing')..makeCurrent();
  final tag2 = UserTag('Baz');
  int i = 5;
  while (true) {
    tag.makeCurrent();
    ++i;
    fib(i);
    tag2.makeCurrent();
    fib(i);
  }
}
