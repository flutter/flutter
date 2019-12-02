// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('Flutter experience eventually appears', () async {
      final SerializableFinder fabFinder = find.byTooltip('Increment');

      // Ensure that the Flutter experience eventually becomes visible.
      await driver.waitFor(fabFinder);
    });
  });
}
