// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  test('Windows app starts and draws frame', () async {
    final FlutterDriver driver = await FlutterDriver.connect(printCommunication: true);
    final String result = await driver.requestData(null);

    expect(result, equals('success'));

    await driver.close();
  }, timeout: Timeout.none);
}
