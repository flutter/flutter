import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('flutter run test --route', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('sanity check flutter drive --route', () async {
      // This only makes sense if you ran the test as described
      // in the test file. It's normally run from devicelab.
      expect(await driver.requestData('route'), '/smuggle-it');
    });
  });
}
