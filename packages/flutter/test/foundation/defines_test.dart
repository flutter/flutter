// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines match expectations per platform', () {
    expect(kIsWeb, !const bool.fromEnvironment('dart.library.io'));
    expect(kIsWeb, !const bool.fromEnvironment('dart.library.isolate'));
    expect(kIsWeb, const bool.fromEnvironment('dart.library.html'));
  });
}
