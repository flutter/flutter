// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Hello World App', () {
    final SerializableFinder titleFinder = find.byValueKey('title');

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      print('before connecting the driver');
      driver = await FlutterDriver.connect();
      print('driver connected');
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('title is correct', () async {
      print('test 1 started');
      // Use the `driver.getText` method to verify the counter starts at 0.
      expect(await driver.getText(titleFinder), 'Hello, world!');
    });
  });
}
