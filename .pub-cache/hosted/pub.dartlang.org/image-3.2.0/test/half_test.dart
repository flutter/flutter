import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Half', () {
    test('Arithmetic', () {
      const f1 = 1.0;
      const f2 = 2.0;
      var h1 = Half(3);
      var h2 = Half(4);

      h1 = Half(f1 + f2);
      expect(h1.toDouble(), equals(3.0));

      h2 += f1;
      expect(h2.toDouble(), equals(5.0));

      h2 = h1 + h2;
      expect(h2.toDouble(), equals(8.0));

      h2 += h1;
      expect(h2.toDouble(), equals(11.0));

      h2 = -h2;
      expect(h2.toDouble(), equals(-11.0));
    });
  });
}
