// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  FlutterDriver? driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver?.close();
  });

  test('Can run with feature flags enabled', () async {
    // TODO(loic-sharma): Turn on a framework feature flag once one exists.
    // https://github.com/flutter/flutter/issues/167668
    await driver?.waitFor(find.text('Feature flags: "{}"'));
  }, timeout: Timeout.none);
}
