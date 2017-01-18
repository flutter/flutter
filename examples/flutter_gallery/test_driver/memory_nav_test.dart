import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

const Duration kWaitBetweenActions = const Duration(milliseconds: 250);

void main() {
  group('flutter gallery transitions', () {
    FlutterDriver driver;
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        await driver.close();
    });

    test('navigation', () async {
      SerializableFinder menuItem = find.text('Text fields');
      await driver.scrollIntoView(menuItem);
      await new Future<Null>.delayed(kWaitBetweenActions);

      for (int i = 0; i < 15; i++) {
        await driver.tap(menuItem);
        await new Future<Null>.delayed(kWaitBetweenActions);
        await driver.tap(find.byTooltip('Back'));
        await new Future<Null>.delayed(kWaitBetweenActions);
      }
    }, timeout: new Timeout(new Duration(minutes: 1)));
  });
}
