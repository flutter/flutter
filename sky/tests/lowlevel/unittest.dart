import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

void main() {
  initUnit();

  test('this is a test', () {
    int x = 2 + 3;
    expect(x, equals(5));
  });
}
