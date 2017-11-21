// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

final RegExp statsRegExp = new RegExp('Produced: (.*)fps\nConsumed: (.*)fps\nWidget builds: (.*)');

void main() {
  group('texture suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('texture rendering', () async {
      final SerializableFinder fab = find.byValueKey('fab');
      final SerializableFinder summary = find.byValueKey('summary');

      await driver.tap(fab);
      await new Future<Null>.delayed(const Duration(seconds: 3));
      await driver.tap(fab);

      final String statsSlow = await driver.getText(summary);
      final Match matchSlow = statsRegExp.matchAsPrefix(statsSlow);
      expect(matchSlow, isNotNull);
      expect(double.parse(matchSlow.group(1)), closeTo(10.0, 2.0));
      expect(double.parse(matchSlow.group(2)), closeTo(10.0, 2.0));
      expect(int.parse(matchSlow.group(3)), 1);

      await driver.tap(fab);
      await new Future<Null>.delayed(const Duration(seconds: 3));
      await driver.tap(fab);

      final String statsFast = await driver.getText(summary);
      final Match matchFast = statsRegExp.matchAsPrefix(statsFast);
      expect(matchFast, isNotNull);
      expect(double.parse(matchFast.group(1)), closeTo(100.0, 2.0));
      expect(double.parse(matchFast.group(2)), inInclusiveRange(52.0, 61.0));
      expect(int.parse(matchFast.group(3)), 1);
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}
