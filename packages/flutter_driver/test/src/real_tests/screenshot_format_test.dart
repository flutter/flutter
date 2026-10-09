// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_driver/src/common/error.dart';
import 'package:flutter_driver/src/common/handler_factory.dart';
import 'package:flutter_driver/src/common/screenshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('png maps to ImageByteFormat.png', () {
    // Regression test: the formats used to be matched by index, and on the web
    // ScreenshotFormat.png.index is out of range for ImageByteFormat.values.
    expect(imageByteFormatFor(ScreenshotFormat.png), ui.ImageByteFormat.png);
  });

  test('every ScreenshotFormat maps by name or throws a DriverError', () {
    final supported = <String>{
      for (final ui.ImageByteFormat value in ui.ImageByteFormat.values) value.name,
    };
    for (final ScreenshotFormat format in ScreenshotFormat.values) {
      if (supported.contains(format.name)) {
        expect(imageByteFormatFor(format).name, format.name);
      } else {
        expect(() => imageByteFormatFor(format), throwsA(isA<DriverError>()));
      }
    }
  });
}
