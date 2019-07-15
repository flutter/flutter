// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<void> main() async {
  FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll((){
    driver.close();
  });

  group('motion event tests', () {

    test('MotionEvents recomposition', () async {
    
      final SerializableFinder linkToOpenMotionEventPage = find.byValueKey('MotionEventPage');
      await driver.tap(linkToOpenMotionEventPage);
      await driver.waitFor(find.byValueKey('MotionEventPageLoaded'));
      final String errorMessage = await driver.requestData('run test');
      expect(errorMessage, '');
      driver?.close();
    });
  });

}

