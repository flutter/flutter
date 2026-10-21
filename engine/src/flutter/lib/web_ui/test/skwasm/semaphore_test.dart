// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library;

import 'dart:ffi';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

@Native<Int32 Function()>(symbol: 'skwasm_verifySemaphores', isLeaf: true)
external int _verifySemaphores();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  // Regression test for https://github.com/flutter/flutter/issues/193695.
  test('sem_* resolve to the Wasm worker semaphore implementation, not the libc no-op stubs', () {
    expect(_verifySemaphores(), 0);
  });
}
