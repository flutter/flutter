// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<void> main() async {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() {
    driver.close();
  });

  // Each test below must return back to the home page after finishing.

  test('MotionEvent recomposition', () async {
    final SerializableFinder motionEventsListTile =
    find.byValueKey('MotionEventsListTile');
    await driver.tap(motionEventsListTile);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await driver.waitFor(find.byValueKey('PlatformView'));
    final String errorMessage = await driver.requestData('run test');
    expect(errorMessage, '');
    final SerializableFinder backButton = find.byValueKey('back');
    await driver.tap(backButton);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }, timeout: Timeout.none);

  group('WindowManager', ()
  {
    setUpAll(() async {
      final SerializableFinder wmListTile =
      find.byValueKey('WmIntegrationsListTile');
      await driver.tap(wmListTile);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    tearDownAll(() async {
      await driver.waitFor(find.pageBack());
      await driver.tap(find.pageBack());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('AlertDialog from platform view context', () async {
      final SerializableFinder showAlertDialog = find.byValueKey(
          'ShowAlertDialog');
      await driver.waitFor(showAlertDialog);
      await driver.tap(showAlertDialog);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final String status = await driver.getText(find.byValueKey('Status'));
      expect(status, 'Success');
    }, timeout: Timeout.none);

    test('Child windows can handle touches', () async {
      final SerializableFinder addWindow = find.byValueKey('AddWindow');
      await driver.waitFor(addWindow);
      await driver.tap(addWindow);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final SerializableFinder tapWindow = find.byValueKey('TapWindow');
      await driver.tap(tapWindow);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final String windowClickCount = await driver.getText(
        find.byValueKey('WindowClickCount'),
      );
      expect(windowClickCount, 'Click count: 1');
    }, timeout: Timeout.none);
  });
}
