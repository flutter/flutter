// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

@TestOn('!chrome') // This test is not intended to run on the web.
import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

void main() {
  test('isWeb is false for flutter tester', () {
    expect(kIsWeb, false);
  });
}
