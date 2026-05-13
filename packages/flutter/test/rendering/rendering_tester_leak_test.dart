// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('onErrors and captured errors do not leak between tests', () {
    layout(RenderSizedBox(const Size(100, 100)));
    
    // Manually pollute the state. 
    // In a real scenario, this could happen if a test fails or handles errors unconventionally.
    TestRenderingFlutterBinding.instance.onErrors = () {
      fail('Leaked onErrors handler called!');
    };
  });

  test('State is clean in the next test', () {
    expect(TestRenderingFlutterBinding.instance.onErrors, isNull);
    expect(TestRenderingFlutterBinding.instance.takeFlutterErrorDetails(), isNull);
  });

  test('layout() clears previous state even if not cleaned up by tearDown', () {
    TestRenderingFlutterBinding.instance.onErrors = () {
      fail('Leaked onErrors handler called!');
    };
    layout(RenderSizedBox(const Size(100, 100)));
    expect(TestRenderingFlutterBinding.instance.onErrors, isNull);
  });
}
