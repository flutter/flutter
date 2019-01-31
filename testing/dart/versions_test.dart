// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// HACK: pretend to be dart.ui in order to access its internals
library dart.ui;

import 'package:test/test.dart';

part '../../lib/ui/versions.dart';

bool _isNotEmpty(String s) {
  if (s == null || s.isEmpty) {
    return false;
  } else {
    return true;
  }
}

void main() {
  test('dartVersion should not be empty', () {
    final String dartVersion = versions.dartVersion;
    expect(_isNotEmpty(dartVersion), equals(true));
  });

  test('skiaVersion should not be empty', () {
    final String skiaVersion = versions.skiaVersion;
    expect(_isNotEmpty(skiaVersion), equals(true));
  });

  test('flutterEngineVersion should not be empty', () {
    final String flutterEngineVersion = versions.flutterEngineVersion;
    expect(_isNotEmpty(flutterEngineVersion), equals(true));
  });
}
