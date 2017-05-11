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
      final Completer<Null> completer = new Completer<Null>();
      bool scroll = true;
      final SerializableFinder menuItem = find.text('Text fields');
      driver.waitFor(menuItem).then<Null>((Null value) async {
        scroll = false;
        await new Future<Null>.delayed(kWaitBetweenActions);
        for (int i = 0; i < 15; i++) {
          await driver.tap(menuItem);
          await new Future<Null>.delayed(kWaitBetweenActions);
          await driver.tap(find.byTooltip('Back'));
          await new Future<Null>.delayed(kWaitBetweenActions);
        }
        completer.complete();
      });
      while (scroll) {
        await driver.scroll(find.text('Flutter Gallery'), 0.0, -500.0, const Duration(milliseconds: 80));
        await new Future<Null>.delayed(kWaitBetweenActions);
      }
      await completer.future;
    }, timeout: const Timeout(const Duration(minutes: 1)));
  });
}
