// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_driver/src/native/android.dart';
import 'package:flutter_driver/src/native/driver.dart';
import 'package:test/test.dart';

void main() async {
  test('should connect to an Android device and take a screenshot', () async {
    final NativeDriver driver = await AndroidNativeDriver.connect();
    final NativeScreenshot screenshot = await driver.screenshot();

    final Uint8List bytes = await screenshot.readAsBytes();
    expect(bytes.length, greaterThan(0));

    final String path = await screenshot.saveAs();
    expect(io.File(path).readAsBytesSync(), bytes);

    await driver.close();
  });
}
