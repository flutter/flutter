import 'package:e2e/keys.dart' as keys;
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

    test('Test text input, clear', () async {
      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      await driver.waitFor(defaultTextField);
      await driver.setInputText(defaultTextField, 'Some text');
      await driver.submitInputText(defaultTextField);

      final SerializableFinder clearButton = find.byValueKey(keys.kClearButton);
      await driver.tap(clearButton);
    });
  });
}
