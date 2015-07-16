import 'dart:sky' as sky;

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  test("paint set to black", () {
    sky.Color c = new sky.Color(0x00000000);
    sky.Paint p = new sky.Paint();
    p.color = c;
    expect(c.toString(), equals('Color(0x00000000)'));
  });

  test("color created with out of bounds value", () {
    try {
      sky.Color c = new sky.Color(0x100 << 24);
      sky.Paint p = new sky.Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });

  test("color created with wildly out of bounds value", () {
    try {
      sky.Color c = new sky.Color(1 << 1000000);
      sky.Paint p = new sky.Paint();
      p.color = c;
    } catch (e) {
      expect(e != null, equals(true));
    }
  });
}
