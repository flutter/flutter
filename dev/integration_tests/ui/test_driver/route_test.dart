// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('flutter run test --route', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('sanity check flutter drive --route', () async {
      // This only makes sense if you ran the test as described
      // in the test file. It's normally run from devicelab.
      expect(await driver.requestData('route'), '/smuggle-it');
    });
  });
}
