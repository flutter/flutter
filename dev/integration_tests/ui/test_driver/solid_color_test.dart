// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
    await driver.waitUntilFirstFrameRasterized();
  });

  test('Can render solid red', () async {
    // PNG Encoded Bytes.
    final Uint8List bytes = (await driver.screenshot()) as Uint8List;

    final img.Image image = img.decodePng(bytes)!;
    final Uint8List data = image.getBytes(order: img.ChannelOrder.argb);

    expect(data[0] << 24 | data[1] << 16 | data[2] << 8 | data[3], 0xFFFF0000);
  });

  tearDownAll(() async {
    await driver.close();
  });
}
