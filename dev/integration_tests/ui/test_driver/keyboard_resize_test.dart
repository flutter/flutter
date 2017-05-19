import 'dart:async';

import 'package:integration_ui/keys.dart' as keys;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    test('Ensure keyboard dismissal resizes the view to original size', () async {
      final SerializableFinder heightText = find.byValueKey(keys.kHeightText);
      await driver.waitFor(heightText);

      // Measure the initial height.
      final String startHeight = await driver.getText(heightText);

      // Focus the text field to show the keyboard.
      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      await driver.waitFor(defaultTextField);
      await driver.tap(defaultTextField);
      await new Future<Null>.delayed(const Duration(seconds: 1));

      // Measure the height with keyboard displayed.
      final String heightWithKeyboardShown = await driver.getText(heightText);
      expect(double.parse(heightWithKeyboardShown) < double.parse(startHeight), isTrue);

      // Unfocus the text field to dismiss the keyboard.
      final SerializableFinder unfocusButton = find.byValueKey(keys.kUnfocusButton);
      await driver.waitFor(unfocusButton);
      await driver.tap(unfocusButton);
      await new Future<Null>.delayed(const Duration(seconds: 1));

      // Measure the final height.
      final String endHeight = await driver.getText(heightText);

      expect(endHeight, startHeight);
    });
  });
}
