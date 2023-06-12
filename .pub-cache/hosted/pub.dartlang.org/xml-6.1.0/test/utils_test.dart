import 'package:test/test.dart';
import 'package:xml/src/xml/utils/cache.dart';

void main() {
  group('cache', () {
    test('simple', () {
      var counter = 0;
      final cache = XmlCache<int, String>((key) {
        expect(key, counter);
        return '${counter++}';
      }, 10);
      expect(cache[0], '0');
      expect(cache[1], '1');
      expect(cache[0], '0');
      expect(cache[1], '1');
    });
    test('expiry', () {
      var counter = 0;
      final cache = XmlCache<int, String>((key) => '${counter++}', 1);
      expect(cache[0], '0');
      expect(cache[1], '1');
      expect(cache[0], '2');
      expect(cache[1], '3');
    });
  });
}
