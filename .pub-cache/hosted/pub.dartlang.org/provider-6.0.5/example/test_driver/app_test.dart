import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('counter app', () {
    FlutterDriver? _driver;

    final incrementFloatingButton =
        find.byValueKey('increment_floatingActionButton');
    final appBarText = find.text('Example');
    final counterState = find.byValueKey('counterState');

    /// connect to [FlutterDriver]
    setUpAll(() async {
      _driver = await FlutterDriver.connect();
    });

    /// close the driver
    tearDownAll(() async {
      await _driver?.close();
    });

    test('AppBar is Flutter Demo Home Page', () async {
      expect(await _driver!.getText(appBarText), 'Example');
    });

    test('counterText is started with 0', () async {
      expect(await _driver!.getText(counterState), '0');
    });

    test('pressed increment floating action button twice', () async {
      // tap floating action button
      await _driver!.tap(incrementFloatingButton);
      expect(await _driver!.getText(counterState), '1');

      // tap floating action button
      await _driver!.tap(incrementFloatingButton);
      expect(await _driver!.getText(counterState), '2');
    });
  });
}
