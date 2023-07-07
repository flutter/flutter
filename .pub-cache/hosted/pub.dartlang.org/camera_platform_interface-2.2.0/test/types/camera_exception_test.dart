// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('constructor should initialize properties', () {
    const String code = 'TEST_ERROR';
    const String description = 'This is a test error';
    final CameraException exception = CameraException(code, description);

    expect(exception.code, code);
    expect(exception.description, description);
  });

  test('toString: Should return a description of the exception', () {
    const String code = 'TEST_ERROR';
    const String description = 'This is a test error';
    const String expected = 'CameraException($code, $description)';
    final CameraException exception = CameraException(code, description);

    final String actual = exception.toString();

    expect(actual, expected);
  });
}
