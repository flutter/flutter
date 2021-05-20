// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:litetest/litetest.dart';

void main() {
  test('Invalid isolate URI', () async {
    bool threw = false;
    try {
      await Isolate.spawnUri(
        Uri.parse('http://127.0.0.1/foo.dart'),
        <String>[],
        null,
      );
    } on IsolateSpawnException {
      threw = true;
    }
    expect(threw, true);
  });
}
