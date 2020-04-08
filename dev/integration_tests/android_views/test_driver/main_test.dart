// Copyright 2014 The Flutter Authors. All rights reserved.
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

  tearDownAll(() {
    driver.close();
  });

  test('MotionEvent recomposition', () async {
    final SerializableFinder motionEventsListTile =
    find.byValueKey('MotionEventsListTile');
    await driver.tap(motionEventsListTile);
    await driver.waitFor(find.byValueKey('PlatformView'));
    final String errorMessage = await driver.requestData('run test');
    expect(errorMessage, '');
  });

  test('AlertDialog from platform view context', () async {
    final SerializableFinder wmListTile =
    find.byValueKey('WmIntegrationsListTile');
    await driver.tap(wmListTile);

    final SerializableFinder showAlertDialog = find.byValueKey('ShowAlertDialog');
    await driver.waitFor(showAlertDialog);
    await driver.tap(showAlertDialog);
    final String status = await driver.getText(find.byValueKey('Status'));
    expect(status, 'Success');
  });
}
