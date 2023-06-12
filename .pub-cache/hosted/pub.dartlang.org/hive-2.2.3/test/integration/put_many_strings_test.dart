import 'package:test/test.dart';

import '../tests/frames.dart';
import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var hive = await createHive();
  var repeat = isBrowser ? 20 : 1000;
  var box = await openBox(lazy, hive: hive);
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      await box.put('${frame.key}n$i', frame.value);
    }
  }

  box = await box.reopen();
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      expect(await await box.get('${frame.key}n$i'), frame.value);
    }
  }
  await box.close();
}

void main() {
  group('put many strings', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
