// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  FlutterDriver driver;

  setUp(() async {
    driver = await FlutterDriver.connect();
  });

  test('can catch image errors in zone', () async {
    // trigger image loading.
    await driver.tap(find.text('LOAD'));
    // assert that error is caught in framework.
    await driver.waitFor(find.text('CAUGHT'));
  });
}