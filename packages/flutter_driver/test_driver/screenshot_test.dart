// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_driver/flutter_driver.dart';

import '../test/common.dart';

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
    await driver.waitUntilFirstFrameRasterized();
  });

  test('it takes a screenshot', () async {
    // PNG Encoded Bytes.
    final Uint8List bytes = (await driver.screenshot()) as Uint8List;

    // Check PNG header.
    expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });

  tearDownAll(() async {
    await driver.close();
  });
}
