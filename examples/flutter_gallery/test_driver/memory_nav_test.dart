import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

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
      await driver.tap(find.text('Material'));

      final SerializableFinder demoList = find.byValueKey('GalleryDemoList');
      final SerializableFinder demoItem = find.text('Text fields');
      await driver.scrollUntilVisible(demoList, demoItem,
        dyScroll: -300.0,
        alignment: 0.5,
        timeout: const Duration(minutes: 1),
      );
      for (int i = 0; i < 15; i++) {
        await driver.tap(demoItem);
        await driver.tap(find.byTooltip('Back'));
      }
    });
  });
}
