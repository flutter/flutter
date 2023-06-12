import 'package:test/test.dart';

import 'integration.dart';

Future _performTest(bool lazy) async {
  var box = await openBox(lazy);
  for (var i = 0; i < 5; i++) {
    var largeString = i.toString() * 1000000;
    await box.put('string$i', largeString);
  }

  box = await box.reopen();
  for (var i = 0; i < 5; i++) {
    var largeString = await await box.get('string$i');

    expect(largeString == i.toString() * 1000000, true);
  }
  await box.close();
}

void main() {
  group('put large strings', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
