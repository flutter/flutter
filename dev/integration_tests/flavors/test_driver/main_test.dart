// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('flavors suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('check flavor', () async {
      final SerializableFinder flavorField = find.byValueKey('flavor');
      final String flavor = await driver.getText(flavorField);
      expect(flavor, 'paid');
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}
