// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    expect(HttpOverrides.current, isNull);
  });

  test('testWidgets does not register HttpOverrides.current', () {
    expect(HttpOverrides.current, isNull);
  });
}
