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

  tearDownAll(() async {
    await driver.close();
  });

  // Each test below must return back to the home page after finishing.
  test('MotionEvent recomposition', () async {
    final SerializableFinder motionEventsListTile = find.byValueKey('MotionEventsListTile');
    await driver.tap(motionEventsListTile);
    await driver.waitFor(find.byValueKey('PlatformView'));
    try {
      final String errorMessage = await driver.requestData('run test');
      expect(errorMessage, '');
    } finally {
      final SerializableFinder backButton = find.byValueKey('back');
      await driver.tap(backButton);
    }
  }, timeout: Timeout.none);

  group('Nested View Event', () {
    setUpAll(() async {
      final SerializableFinder wmListTile = find.byValueKey('NestedViewEventTile');
      await driver.tap(wmListTile);
    });

    tearDownAll(() async {
      await driver.waitFor(find.pageBack());
      await driver.tap(find.pageBack());
    });

    test('AlertDialog from platform view context', () async {
      final SerializableFinder showAlertDialog = find.byValueKey('ShowAlertDialog');
      await driver.waitFor(showAlertDialog);
      await driver.tap(showAlertDialog);
      final String status = await driver.getText(find.byValueKey('Status'));
      expect(status, 'Success');
    }, timeout: Timeout.none);

    test('Child view can handle touches', () async {
      final SerializableFinder addChildView = find.byValueKey('AddChildView');
      await driver.waitFor(addChildView);
      await driver.tap(addChildView);
      final SerializableFinder childView = find.byValueKey('PlatformView');
      await driver.tap(childView);
      // delay of 1000ms to allow widget to update
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      final String nestedViewClickCount = await driver.getText(
        find.byValueKey('NestedViewClickCount'),
      );
      expect(nestedViewClickCount, 'Click count: 1');
    }, timeout: Timeout.none);
  });

  group('Flutter surface without hybrid composition', () {
    setUpAll(() async {
      await driver.tap(find.byValueKey('NestedViewEventTile'));
    });

    tearDownAll(() async {
      await driver.waitFor(find.pageBack());
      await driver.tap(find.pageBack());
    });

    test('Uses FlutterSurfaceView when Android view is on the screen', () async {
      await driver.waitFor(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n' // Flutter UI
        '  |-ViewGroup\n' // Platform View
        '    |-ViewGroup\n',
      );

      // Hide platform view.
      final SerializableFinder togglePlatformView = find.byValueKey('TogglePlatformView');
      await driver.tap(togglePlatformView);
      await driver.waitForAbsent(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n', // Just the Flutter UI
      );

      // Show platform view again.
      await driver.tap(togglePlatformView);
      await driver.waitFor(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n' // Flutter UI
        '  |-ViewGroup\n' // Platform View
        '    |-ViewGroup\n',
      );
    }, timeout: Timeout.none);
  });

  group('Flutter surface with hybrid composition', () {
    setUpAll(() async {
      await driver.tap(find.byValueKey('NestedViewEventTile'));
      await driver.tap(find.byValueKey('ToggleHybridComposition'));
      await driver.tap(find.byValueKey('TogglePlatformView'));
      await driver.tap(find.byValueKey('TogglePlatformView'));
    });

    tearDownAll(() async {
      await driver.waitFor(find.pageBack());
      await driver.tap(find.pageBack());
    });

    test('Uses FlutterImageView when Android view is on the screen', () async {
      await driver.waitFor(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n' // Flutter UI (hidden)
        '  |-FlutterImageView\n' // Flutter UI (background surface)
        '  |-ViewGroup\n' // Platform View
        '    |-ViewGroup\n'
        '  |-FlutterImageView\n', // Flutter UI (overlay surface)
      );

      // Hide platform view.
      final SerializableFinder togglePlatformView = find.byValueKey('TogglePlatformView');
      await driver.tap(togglePlatformView);
      await driver.waitForAbsent(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n', // Just the Flutter UI
      );

      // Show platform view again.
      await driver.tap(togglePlatformView);
      await driver.waitFor(find.byValueKey('PlatformView'));

      expect(
        await driver.requestData('hierarchy'),
        '|-FlutterView\n'
        '  |-FlutterSurfaceView\n' // Flutter UI (hidden)
        '  |-FlutterImageView\n' // Flutter UI (background surface)
        '  |-ViewGroup\n' // Platform View
        '    |-ViewGroup\n'
        '  |-FlutterImageView\n', // Flutter UI (overlay surface)
      );
    }, timeout: Timeout.none);
  });

  test('PlatformView does not steal focus from TextField when unfocused', () async {
    final SerializableFinder keyboardTile = find.byValueKey('KeyboardUnfocusListTile');
    await driver.tap(keyboardTile);

    // Disable emulation to test real native keyboard behavior.
    await driver.setTextEntryEmulation(enabled: false);

    await driver.waitFor(find.byValueKey('PlatformViewContainer'));
    await driver.waitUntilNoTransientCallbacks();

    // Tap text field to focus it and open IME.
    await driver.tap(find.byValueKey('textfield'));
    await driver.waitUntilNoTransientCallbacks();

    // Tap platform view (causes native focus shift).
    await driver.tap(find.byValueKey('PlatformViewContainer'));
    await driver.waitUntilNoTransientCallbacks();

    // Tap text field again to re-focus it.
    await driver.tap(find.byValueKey('textfield'));
    await driver.waitUntilNoTransientCallbacks();

    expect(await driver.requestData('commitText'), 'true');
    await driver.waitUntilNoTransientCallbacks();

    // Also verify the text field value was updated!
    final SerializableFinder textValue = find.byValueKey('text_value');
    expect(await driver.getText(textValue), 'updated');

    // Clean up
    await driver.setTextEntryEmulation(enabled: true);
    await driver.waitFor(find.pageBack());
    await driver.tap(find.pageBack());
  }, timeout: Timeout.none);
}
