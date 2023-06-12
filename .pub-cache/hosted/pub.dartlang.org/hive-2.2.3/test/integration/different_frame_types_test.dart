import 'package:test/test.dart';

import '../tests/frames.dart';
import 'integration.dart';

Future _performTest(bool encrypted, bool lazy) async {
  var encryptionKey = encrypted ? List.generate(32, (i) => i) : null;
  var box = await openBox(lazy, encryptionKey: encryptionKey);
  for (var frame in valueTestFrames) {
    if (frame.deleted) continue;
    await box.put(frame.key, frame.value);
  }

  box = await box.reopen(encryptionKey: encryptionKey);

  for (var frame in valueTestFrames) {
    if (frame.deleted) continue;
    var f = await await box.get(frame.key);
    expect(f, frame.value);
  }
  await box.close();
}

void main() {
  group('different frame types', () {
    group('encrypted', () {
      test('normal box', () => _performTest(true, false));

      test('lazy box', () => _performTest(true, true));
    });

    group('not encrypted', () {
      test('normal box', () => _performTest(false, false));

      test('lazy box', () => _performTest(false, true));
    });
  }, timeout: longTimeout);
}
