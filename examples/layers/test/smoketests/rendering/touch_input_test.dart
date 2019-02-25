// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import '../../../rendering/touch_input.dart' as demo;

void main() {
  test('layers smoketest for rendering/touch_input.dart', () {
    FlutterError.onError = (FlutterErrorDetails details) { throw details.exception; };
    demo.main();
  });
}
