// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// FlutterTesterOptions=--enable-serial-gc

import 'package:litetest/litetest.dart';

void main() {
  test('Serial GC option test ', () async {
    bool threw = false;
    for (int i = 0; i < 100; i++) {
      var a = <int>[100];
    }
    expect(threw, false);
  });
}
